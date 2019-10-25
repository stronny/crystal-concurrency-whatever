class Connection

	module Timeouts
		Connect = 5.seconds
		Restart = 5.seconds
	end


	class Shutdown < Exception; end
	class RemoteShutdown < Exception; end


	struct Event::Ping < XNT::Jiber::Event; end


	abstract struct State
		struct Free < State; end
		struct Sleeping < State; end
		struct Reading < State; end
		struct Writing < State; end
	end


	@state : State = State::Free.new
	@connected : Bool = false
	@ttw : Bool = false
	@shutdown : Bool = false

	@name : String
	@ep : Endpoint
	@influx_name : String | Nothing = nothing

	@socket : TCPSocket | Nothing = nothing

	@read_buf : Bytes = Bytes.new 8
	@write_buf : Bytes = Bytes.new 9
	@mio : IO::Memory


	def initialize(@name, @ep)
		@mio = IO::Memory.new @write_buf
	end


end
