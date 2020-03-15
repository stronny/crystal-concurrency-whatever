module XNT::Jiber
  abstract struct Event
    getter origin : Fiber = Fiber.current
  end

  struct Event::Shutdown < Event; end

  struct Event::Finished < Event
    getter jid : ID

    def initialize(@jid : ID); end
  end

  #	struct Event::Stop < Event; end

  #	struct Event::Continue < Event; end

end
