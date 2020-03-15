class XNT::Job::Timeout < XNT::Job
  class Expired < Exception; end

  struct Event::Stop < XNT::Jiber::Event; end

  struct Event::Rewind < XNT::Jiber::Event; end

  struct Event::Set < XNT::Jiber::Event
    getter span : Time::Span

    def initialize(@span : Time::Span); end
  end

  @span : Time::Span | Nothing = nothing
  @shutdown : Bool = false

  def handle_shutdown : Nil
    @shutdown = true
    wakeup
  end

  def handle_interrupt(event : Event::Stop) : Nil
    @jiber.free_resume_event
  end

  def handle_interrupt(event : Event::Rewind) : Nil
    rewind
  end

  def handle_interrupt(event : Event::Set) : Nil
    @span = event.span
    rewind
  end

  def main : Nil
    sleep
    handle_timeout unless @shutdown
  end

  protected def handle_timeout : Nil
    raise Expired.new
  end

  protected def resleep(n : Nothing) : Nil; end

  protected def resleep(span : Time::Span) : Nil
    @jiber.resume_event.add span
  end

  protected def wakeup : Nil
    resleep ZERO_SECONDS
  end

  protected def rewind : Nil
    resleep @span
  end
end
