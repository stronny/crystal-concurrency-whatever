module XNT::Jiber
  abstract struct Status
    alias Error = Exception | Nothing
    getter jid : ID
    getter created : Time

    def initialize(@jid, @created = Time.utc); end
  end

  struct Status::Created < Status
    getter jiber : Jiber

    def initialize(@jiber : Jiber)
      super @jiber.id
    end

    def make_running : Status::Running
      Status::Running.new @jiber, @created
    end
  end

  struct Status::Running < Status
    getter jiber : Jiber
    getter started : Time

    def initialize(@jiber, @created, @started = Time.utc)
      @jid = @jiber.id
    end

    def interrupt(event : Event) : Nil
      @jiber.interrupt event
    end

    def shutdown : Nil
      interrupt Event::Shutdown.new
    end

    def make_finished(parent : Fiber, error : Status::Error) : Status::Finished
      Status::Finished.new @jid, @created, @started, parent, error
    end
  end

  struct Status::Finished < Status
    getter started : Time
    getter parent : Fiber
    getter error : Error
    getter finished : Time

    def initialize(@jid, @created, @started, @parent, @error, @finished = Time.utc); end
  end
end
