class Influx
  protected def socket_close(socket : Nothing) : Nil; end

  protected def socket_close(socket : TCPSocket) : Nil
    socket.close
  rescue x
  ensure
    @socket = nothing
  end

  protected def socket_connect(socket : Nothing) : Nil
    raise "no socket"
  end

  protected def socket_connect(socket : TCPSocket) : Nil
    @state = State::Reading.new
    output_debug "influx trying to connect to #{@host}:#{@port}"
    socket.connect @host, @port, Timeouts::Connect
    output_debug "influx connected"
    @connected = true
  rescue x : IO::Timeout
    raise Shutdown.new if @shutdown
    raise x
  ensure
    @state = State::Free.new
  end

  protected def read_reply(socket : Nothing) : HTTP::Client::Response
    raise "no socket"
  end

  protected def read_reply(socket : TCPSocket) : HTTP::Client::Response
    @state = State::Reading.new
    HTTP::Client::Response.from_io socket
  rescue x : IO::Timeout
    raise Shutdown.new
  ensure
    @state = State::Free.new
  end

  protected def write_measurements(socket : Nothing) : Bool
    raise "no socket"
  end

  protected def write_measurements(socket : TCPSocket) : Bool
    return false if @@mio.pos.zero?
    @state = State::Writing.new
    @req.body = @@bytes[0, @@mio.pos]
    @req.to_io socket
    socket.flush
    true
  rescue x : IO::Timeout
    raise Shutdown.new
  ensure
    @@mio.rewind
    @state = State::Free.new
  end
end
