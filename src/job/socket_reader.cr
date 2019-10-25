abstract class XNT::Job::SocketReader < XNT::Job

	class Shutdown < Exception; end

	enum State
		FREE
		READING
		WRITING
	end

	struct Event::Write < XNT::Jiber::Event
		getter bytes : Bytes
		def initialize(@bytes : Bytes); end
	end

	@state : State = State::FREE
	@shutdown : Bool = false
	@write_deq : Deque(Bytes) = Deque(Bytes).new
	@read_buf : Bytes

	def initialize(@socket : Socket)
		@read_buf = create_read_buffer
		@socket.read_buffering = false
		@socket.sync = true
	end

	abstract def process(count : Int32) : Nil

	def main : Nil
		setup
		loop do
			count = read
			process count if count > 0
			write_all
			return if count.zero?
		end
	rescue Shutdown
	ensure
		cleanup
	end

	protected def create_read_buffer : Bytes
		Bytes.new 2048
	end

	protected def setup : Nil
	end

	protected def cleanup : Nil
		@socket.close
	end

	protected def read : Int32 # -1: interrupted, 0: EOF
		@state = :reading
		@socket.read @read_buf
	rescue x : IO::Timeout
		raise Shutdown.new if @shutdown
		-1
	ensure
		@state = :free
	end

	protected def write_all : Nil
		@state = :writing
		while ! @write_deq.empty?
			bytes = @write_deq.shift
			write bytes
		end
	rescue x : IO::Timeout
		raise Shutdown.new
	ensure
		@state = :free
	end

	protected def write(bytes : Bytes) : Nil
		@socket.write bytes
	end

	def handle_interrupt(event : Event::Write) : Nil
		@write_deq.push event.bytes
		interrupt_blocking_call if @state.reading?
	end

	def handle_shutdown : Nil
		return if @shutdown
		@shutdown = true
		interrupt_blocking_call
	end

	protected def interrupt_blocking_call : Nil
		return if @state.free?
		case @state
			when State::READING then @socket.read_timeout!
			when State::WRITING then @socket.write_timeout!
		end
	end

end
