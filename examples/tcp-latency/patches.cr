# class Socket
#	def reinit_nonblock! : Nil
#		return unless @closed
#		initialize @family, @type, @protocol, false
#	end
# end

# module Crystal::EventLoop
#  def self.create_resume_event(fiber)
# p resume_create: {Fiber.current, fiber}
#    event_base.new_event(-1, LibEvent2::EventFlags::None, fiber) do |s, flags, data|
# p resume_fired: {Fiber.current, data.as(Fiber)}
#      Crystal::Scheduler.enqueue data.as(Fiber)
#    end
#  end
# end

# struct Crystal::Event
#  def add(timeout : LibC::Timeval? = nil)
#    if timeout
# p ev_add: @event
#      timeout_copy = timeout
#      LibEvent2.event_add(@event, pointerof(timeout_copy))
#    else
#      LibEvent2.event_add(@event, nil)
# p ev_del: @event
#    end
#  end

#  def free
# p ev_free: @event
#    LibEvent2.event_free(@event) unless @freed
#    @freed = true
#  end

# end
