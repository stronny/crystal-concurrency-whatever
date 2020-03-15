require "./crystal_scheduler/wakeup_parent"

class Crystal::Scheduler
  private def forbid_double_reschedule(me : XNT::Jiber) : Nil
    fatal_resume_error me, "Reschedule called while handling an interrupt" if me.interrupt_inside_handler
  end

  private def detect_and_handle_interrupt(me : XNT::Jiber) : Bool # true if interrupt handled, false if no interrupt
    event = me.interrupt_event
    return false if event.is_a? Nothing
    me.interrupt_event = nothing
    me.interrupt_inside_handler = true
    me.route_event event
    #		case event
    #			when XNT::Jiber::Event::Shutdown then me.handle_shutdown
    #			when XNT::Jiber::Event::Finished then me.handle_finished event.jid
    #			else me.handle_interrupt event
    #		end
    me.interrupt_inside_handler = false
    #		resume event.origin
    resume event.origin
    # enqueue_next event.origin
    # reschedule
    true
  rescue x
    fatal_resume_error me, "Unhandled exception during interrupt handling: #{x.inspect_with_backtrace}"
  end

  private def detect_and_handle_interrupt(me : Fiber) : Bool
    false
  end

  protected def reschedule : Nil
    current = @current
    forbid_double_reschedule current if current.is_a? XNT::Jiber
    if current.dead?
      check_and_wakeup_my_parent current if current.is_a? XNT::Jiber
      @runnables.delete current
      @wakeup_table_any.delete current
      @wakeup_table_every.delete current
    end
    # p going_to_sleep: current
    current.trace XNT::Trace::Event::Reschedule::Sleeping.new if current.is_a? XNT::Jiber
    current.sleep_ts = Time.utc if current.is_a? XNT::Jiber
    previous_def
    current.sleep_ts = nothing if current.is_a? XNT::Jiber
    # p woke: current
    current.trace XNT::Trace::Event::Reschedule::Awake.new if current.is_a? XNT::Jiber
    while detect_and_handle_interrupt current; end
  end

  protected def enqueue(fiber : Fiber) : Nil
    return if fiber.dead?
    #		if (Crystal::EventLoop.eq? @current) && (fiber.is_a? XNT::Jiber) && !fiber.event_loop_status.free?
    #			fiber.event_loop_status = :waiting
    #			return
    #		end
    previous_def
  end

  protected def enqueue(fibers : Enumerable(Fiber)) : Nil
    fibers = fibers.reject { |fiber| fiber.dead? }
    previous_def
  end

  protected def resume(fiber : Fiber) : Nil
    current = @current

    if current == fiber
      current.trace XNT::Trace::Event::Reschedule::Self.new if current.is_a? XNT::Jiber
      return
    end

    # p switching_fibers: {@current, fiber}
    current.trace XNT::Trace::Event::Reschedule::Switching.new current.inspect, fiber.inspect if current.is_a? XNT::Jiber
    fiber.trace XNT::Trace::Event::Reschedule::Switching.new current.inspect, fiber.inspect if fiber.is_a? XNT::Jiber

    previous_def
  end

  def self.fatal(fiber : Fiber, message) : Nil
    Thread.current.scheduler.fatal fiber, message
  end

  def fatal(fiber : Fiber, message) : Nil
    fatal_resume_error fiber, message
  end

  #	def self.eventloop_resume_pause(jiber : XNT::Jiber) : Nil
  #		Thread.current.scheduler.eventloop_resume_pause jiber
  #	end

  #	def eventloop_resume_pause(jiber : XNT::Jiber) : Nil
  #		jiber.event_loop_status = :paused if jiber.event_loop_status.free?
  #	end

  #	def self.eventloop_resume_unpause(jiber : XNT::Jiber) : Nil
  #		Thread.current.scheduler.eventloop_resume_pause jiber
  #	end

  #	def eventloop_resume_unpause(jiber : XNT::Jiber) : Nil
  #		return if jiber.event_loop_status.free?
  #		is_waiting = jiber.event_loop_status.waiting?
  #		jiber.event_loop_status = :free
  #		enqueue jiber if is_waiting
  #	end

  def self.enqueue_next(fiber : Fiber) : Nil
    Thread.current.scheduler.enqueue_next fiber
  end

  protected def enqueue_next(fiber : Fiber) : Nil
    @runnables.unshift fiber
  end
end
