class XNT::Wiber < Fiber
  include XNT::Jiber

  module Error
    class NoHandler < Exception; end
  end

  @proc_job_shutdown : Proc(Nil) | Nothing = nothing
  @proc_job_finished : Proc(Status::Finished, Nil) | Nothing = nothing
  @proc_job_interrupt : Proc(Event, Nil) | Nothing = nothing

  def initialize(&block : Proc(Job))
    Jibers.register self
    super @id.to_s do
      # p started: self
      trace XNT::Trace::Event::Started.new
      Jibers.make_jiber_running self
      job = block.call
      # https://github.com/crystal-lang/crystal/issues/3943
      # @proc_job_shutdown  = ->job.handle_shutdown
      # @proc_job_finished  = ->job.handle_finished(Status::Finished)
      # @proc_job_interrupt = ->job.handle_interrupt(Event)
      @proc_job_shutdown = ->{ job.handle_shutdown }
      @proc_job_finished = ->(status : Status::Finished) { job.handle_finished status }
      @proc_job_interrupt = ->(event : Event) { job.handle_interrupt event }
      job.main
      error = nothing
    rescue x
      error = x
      # p x: x
    ensure
      local_cleanup error
      # p ended: self
      trace XNT::Trace::Event::Finished.new
    end
  end

  def handle_shutdown : Nil
    proc = @proc_job_shutdown
    raise Error::NoHandler.new "No shutdown handler" if proc.is_a? Nothing
    proc.call
  end

  def handle_interrupt(event : Event) : Nil
    proc = @proc_job_interrupt
    raise Error::NoHandler.new "No interrupt handler for #{event}" if proc.is_a? Nothing
    proc.call event
  end

  protected def handle_finished_status(status : Status) : Nil
    proc = @proc_job_finished
    raise Error::NoHandler.new "No finished handler" if proc.is_a? Nothing
    proc.call status
  end
end
