abstract struct XNT::Trace::Event
	getter ts : Time = Time.utc
end

struct XNT::Trace::Event::Reschedule::Self      < XNT::Trace::Event; end
struct XNT::Trace::Event::Reschedule::Sleeping  < XNT::Trace::Event; end
struct XNT::Trace::Event::Reschedule::Awake     < XNT::Trace::Event; end
struct XNT::Trace::Event::Reschedule::Switching < XNT::Trace::Event
	getter old : String
	getter new : String
	def initialize(@old : String, @new : String); end
end

struct XNT::Trace::Event::Started   < XNT::Trace::Event; end
struct XNT::Trace::Event::Finished  < XNT::Trace::Event; end
struct XNT::Trace::Event::Childfree < XNT::Trace::Event; end

struct XNT::Trace::Event::Error::ShutdownChild < XNT::Trace::Event
	getter jid : XNT::Jiber::ID
	getter error : Exception
	def initialize(@jid : XNT::Jiber::ID, @error : Exception); end
end

struct XNT::Trace::Event::Error::InterruptParent < XNT::Trace::Event
	getter error : Exception
	def initialize(@error : Exception); end
end

struct XNT::Trace::Event::Error::Cleanup < XNT::Trace::Event
	getter error : Exception
	def initialize(@error : Exception); end
end

struct XNT::Trace::Event::Interrupted < XNT::Trace::Event
	getter event : XNT::Jiber::Event
	def initialize(@event : XNT::Jiber::Event); end
end

struct XNT::Trace::Event::ChildFinished < XNT::Trace::Event
	getter status : XNT::Jiber::Status
	def initialize(@status : XNT::Jiber::Status); end
end

struct XNT::Trace::Event::ChildError < XNT::Trace::Event
	getter status : XNT::Jiber::Status
	def initialize(@status : XNT::Jiber::Status); end
end


#struct XNT::Trace::Event:: < XNT::Trace::Event
#end
