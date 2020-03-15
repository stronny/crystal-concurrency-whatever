module XNT::Jiber
  alias ID = UInt64

  #	enum EventLoopStatus
  #		FREE     # no resume block
  #		PAUSED   # yes resume block
  #		WAITING  # event received while blocked
  #	end

  getter id : ID = Jibers.new_jid

  getter parent : Fiber = Fiber.current

  property interrupt_event : Event | Nothing = nothing
  property interrupt_inside_handler : Bool = false
  #	property event_loop_status : EventLoopStatus = EventLoopStatus::FREE

  property sleep_ts : Time | Nothing = nothing

  getter trace_log : XNT::Queue(XNT::Trace::Event) = XNT::Queue(XNT::Trace::Event).new 2048_u32

  getter children_jids : Array(ID) = Array(ID).new

  def interrupt(event : Event) : Nil
    if Fiber.current == self
      route_event event
    else
      active = @interrupt_event
      #			raise "Interrupt #{event} conflicts with active interrupt #{active}" if active.is_a? Event
      Crystal::Scheduler.fatal self, "Interrupt #{event} conflicts with active interrupt #{active}" if active.is_a? Event
      @interrupt_event = event
      # p interrupted: {self, event}
      trace XNT::Trace::Event::Interrupted.new event
      #			resume
      resume
      # Crystal::Scheduler.enqueue_next self
      # Crystal::Scheduler.reschedule
    end
  end

  def route_event(event : Event) : Nil
    case event
    #			when Event::Stop     then Crystal::Scheduler.eventloop_resume_pause self
    #			when Event::Continue then Crystal::Scheduler.eventloop_resume_unpause self
    when Event::Shutdown then handle_shutdown
    when Event::Finished then handle_finished event.jid
    else                      handle_interrupt event
    end
  end

  abstract def handle_interrupt(event : Event) : Nil
  abstract def handle_shutdown : Nil

  def handle_finished(jid : ID) : Nil
    @children_jids.delete jid
    handle_finished_status Jibers.reap_finished_child jid
  end

  protected def handle_finished_status(status : Status) : Nil
    # p finished: status
    trace XNT::Trace::Event::ChildFinished.new status
  end

  private def local_cleanup(error : Status::Error) : Nil
    Jibers.debrief_finished_jiber self, error
    local_shutdown_children
    local_wait_for_children
    local_interrupt_parent
  rescue x
    # p error_cleaning_up: {self, x.inspect_with_backtrace}
    trace XNT::Trace::Event::Error::Cleanup.new x
  end

  private def local_shutdown_child(jid : ID) : Nil
    Jibers.shutdown_if_running jid
  rescue x
    # p error_killing_child: {jid, x}
    trace XNT::Trace::Event::Error::ShutdownChild.new jid, x
  end

  private def local_shutdown_children : Nil
    @children_jids.each { |jid| local_shutdown_child jid }
  end

  private def local_wait_for_children : Nil
    Crystal::Scheduler.wake_me_up_after_all_of_these_children_finish @children_jids
    Crystal::Scheduler.fatal self, "Alive children after the wait: #{@children_jids}" unless @children_jids.empty?
    # p all_children_dead: {self, @children_jids}
    trace XNT::Trace::Event::Childfree.new
  end

  private def local_interrupt_parent : Nil
    parent = @parent
    return unless parent.is_a? Jiber
    parent.interrupt Event::Finished.new @id
  rescue x
    # p error_interrupting_parent: {self, x}
    trace XNT::Trace::Event::Error::InterruptParent.new x
  end

  def start_child : ID
    jiber = yield
    jid = jiber.id
    @children_jids.push jid
    Crystal::Scheduler.enqueue jiber
    jid
  end

  def trace(event : XNT::Trace::Event) : Nil
    #		@trace_log.push! event
    p({self, event})
    # XNT::STDOUT.puts({self, event}.inspect) unless XNT::STDOUT.eq? self
  end
end
