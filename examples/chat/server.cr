class Server < XNT::Job

	class Shutdown < Exception; end

	struct Event::Ready < XNT::Jiber::Event; end

	struct Event::Publish < XNT::Jiber::Event
		getter line : String
		def initialize(@line : String); end
	end

	@sleeping : Bool = false
	@ready : Deque(XNT::Jiber::ID) = Deque(XNT::Jiber::ID).new
	@busy : Deque(XNT::Jiber::ID) = Deque(XNT::Jiber::ID).new

	def initialize(@count : Int32, @server : Socket)
		@count.times do
			jid = @jiber.start_child do
				XNT::Wiber.new do
					Connection.new
				end
			end
			@ready.push critical jid
		end
	end

	def handle_shutdown : Nil
		@server.close
		if @sleeping
			@sleeping = false
			Crystal::Scheduler.enqueue @jiber
		end
	end

	def handle_interrupt(event : Event::Ready) : Nil
		origin = event.origin
		return unless origin.is_a? XNT::Jiber
		return if @ready.includes? origin.id
		@busy.delete origin.id
		@ready.push origin.id
		if @sleeping
			@sleeping = false
			Crystal::Scheduler.enqueue @jiber
		end
	end

	def handle_interrupt(event : Event::Publish) : Nil
		@busy.each do |jid| XNT::Jibers.interrupt_if_running jid, Connection::Event::Write.new event.line.to_slice end
	end

	def main : Nil
		accept_loop
	rescue Shutdown
	ensure
		@server.close
	end

	protected def accept_loop : Nil
		loop do
			accepted accept
		end
	end

	protected def accepted(socket : Socket) : Nil
		jid = @ready.shift
		XNT::Jibers.interrupt_if_running jid, Connection::Event::Accepted.new socket
		@busy.push jid
	end

	protected def accept : Socket
		if @ready.empty?
			@sleeping = true
			sleep
		end
		socket = @server.accept?
		raise Shutdown.new if socket.nil?
		socket
	end

end
