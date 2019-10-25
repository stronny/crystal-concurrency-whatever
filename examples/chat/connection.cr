class Connection < XNT::Job

	class Shutdown < Exception; end

	class Error::NotReady < Exception; end

	enum State
		FREE
		WAITING
		READING
		WRITING
	end

	struct Event::Accepted < XNT::Jiber::Event
		getter socket : Socket
		def initialize(@socket : Socket); end
	end

	struct Event::Write < XNT::Jiber::Event
		getter bytes : Bytes
		def initialize(@bytes : Bytes); end
	end

	@state : State = State::FREE
	@socket : Socket | Nothing = nothing
	@write_deq : Deque(Bytes) = Deque(Bytes).new
	@read_buf : Bytes = Bytes.new 2048
	@shutdown : Bool = false
	@pjid : XNT::Jiber::ID

	@string_buf : String::Builder = String::Builder.new

	def initialize
		parent = @jiber.parent
		raise "Parent should be a Jiber" unless parent.is_a? XNT::Jiber
		@pjid = parent.id
	end

	def handle_interrupt(event : Event::Accepted) : Nil
		raise Error::NotReady.new unless @socket.is_a? Nothing
		@socket = event.socket
		if @state.waiting?
			@state = :free
			Crystal::Scheduler.enqueue @jiber
		end
	end

	def main : Nil
		loop do
			XNT::Jibers.interrupt_if_running @pjid, Server::Event::Ready.new
			socket = @socket
			if socket.is_a? Nothing
				@state = :waiting
				sleep
				raise Shutdown.new if @shutdown
			end
			socket = @socket
			next if socket.is_a? Nothing
			read_parse_response_loop socket
			@socket = nothing
		end
	rescue Shutdown
	end

	protected def read_parse_response_loop(socket : Socket) : Nil
		socket.read_buffering = false
		socket.sync = true
		@write_deq.clear
		loop do
			count = read socket
			process count if count > 0
			write_all socket
			return if count.zero?
		end
	ensure
		socket.close
	end

	protected def process(count : Int32) : Nil
#		XNT::Jibers.interrupt_if_running @timeout_jid, XNT::Job::Timeout::Event::Rewind.new
		buf = @read_buf[0,count]
		while n = buf.index 10_u8
			@string_buf.write buf[0, n]
			process_line @string_buf.to_s.chomp
			buf += (n + 1)
			@string_buf = String::Builder.new
		end
		@string_buf.write buf if buf.size > 0
	end

	protected def process_line(line : String) : Nil
		XNT::Jibers.interrupt_if_running @pjid, Server::Event::Publish.new line
	end


	protected def read(socket : Socket) : Int32 # -1: interrupted, 0: EOF
		@state = :reading
		socket.read @read_buf
	rescue x : IO::Timeout
		raise Shutdown.new if @shutdown
		-1
	ensure
		@state = :free
	end

	protected def write_all(socket : Socket) : Nil
		@state = :writing
		while ! @write_deq.empty?
			bytes = @write_deq.shift
			socket.write bytes
			socket.write_byte 10_u8
		end
	rescue x : IO::Timeout
		raise Shutdown.new
	ensure
		@state = :free
	end

	def handle_shutdown : Nil
		return if @shutdown
		@shutdown = true
		interrupt_blocking_call
	end

	def handle_interrupt(event : Event::Write) : Nil
		socket = @socket
		return if socket.is_a? Nothing
		@write_deq.push event.bytes
		interrupt_blocking_call if @state.reading?
	end

	protected def interrupt_blocking_call : Nil
		socket = @socket
		case @state
			when State::FREE then return
			when State::WAITING then Crystal::Scheduler.enqueue @jiber
			when State::READING then socket.read_timeout!  unless socket.is_a? Nothing
			when State::WRITING then socket.write_timeout! unless socket.is_a? Nothing
		end
	end

end
