class Influx < XNT::Job

	SPACE      = " "
	FIELD_PREF = "value="
	@@bytes = Bytes.new 2 ** 20
	@@mio = IO::Memory.new @@bytes

	def self.push(name : Nothing, milsec : Float64) : Nil; end
	def self.push(name : String, milsec : Float64) : Nil
		@@mio << name << SPACE << FIELD_PREF
		milsec.to_s @@mio
		@@mio << SPACE
		Time.utc.to_unix.to_s @@mio
		@@mio.puts
#		output_debug "#{name} #{milsec}"
	end


	def main : Nil
		loop { connect_and_rescue }
	rescue x : Shutdown
		output_debug "influx shutdown"
	end


	protected def connect_and_rescue : Nil
		connect_cycle
	rescue x : Shutdown
		raise x
	rescue x
		if @connected
			output_warn "influx tcp error: #{x.inspect}"
		else
			output_warn "influx connection error: #{x.inspect}"
		end
		output_debug "influx sleeping before reconnecting"
		sleep_span Timeouts::Restart
	ensure
		@connected = false
	end


	protected def connect_cycle : Nil
		@socket = TCPSocket.new
		socket_connect @socket
		loop { write_read_cycle }
	ensure
		socket_close @socket
	end


	protected def write_read_cycle : Nil
		if write_measurements @socket
			inspect_reply read_reply @socket
		end
		sleep_span Timeouts::Interval
	end


	protected def inspect_reply(r : HTTP::Client::Response) : Nil
		return if r.success?
		output_warn "influx response #{r.status.to_i} #{r.body}"
	end


	protected def sleep_span(span : Time::Span) : Nil
		@state = State::Sleeping.new
		sleep span
		raise Shutdown.new if @shutdown
	ensure
		@state = State::Free.new
	end



end

require "./influx/*"
