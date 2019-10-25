class Connection


	protected def socket_close(socket : Nothing) : Nil; end
	protected def socket_close(socket : TCPSocket) : Nil
		socket.close
	rescue x
	ensure
		@socket = nothing
	end


	protected def socket_connect(socket : Nothing) : Nil; raise "no socket" end
	protected def socket_connect(socket : TCPSocket) : Nil
		@state = State::Writing.new
		output_debug "#{@name} trying to connect to #{@ep.sipa}"
		socket.connect @ep.sipa, Timeouts::Connect
		output_debug "#{@name} connected"
		@connected = true
		@influx_name = "#{dashes(socket.local_address)}.#{dashes(socket.remote_address)}"
	rescue x : IO::Timeout
		raise Shutdown.new if @shutdown
		raise x
	ensure
		@state = State::Free.new
	end



	protected def read_ts(socket : Nothing) : Time | Nothing; raise "no socket" end
	protected def read_ts(socket : TCPSocket) : Time | Nothing
		@state = State::Reading.new
		cmd = socket.read_byte
		raise RemoteShutdown.new unless 117_u8 == cmd
		socket.read_fully @read_buf
		ums = IO::ByteFormat::SystemEndian.decode Int64, @read_buf
		Time.unix_ms ums
	rescue x : IO::Timeout
		raise Shutdown.new if @shutdown
		nothing
	ensure
		@state = State::Free.new
	end




	protected def write_ping(socket : Nothing) : Nil; raise "no socket" end
	protected def write_ping(socket : TCPSocket) : Nil
		@state = State::Writing.new
		@mio.rewind
		@mio.write_byte 117_u8
		@mio.write_bytes Time.utc.to_unix_ms
		socket.write @write_buf
		socket.flush
	rescue x : IO::Timeout
		raise Shutdown.new
	ensure
		@state = State::Free.new
	end


end
