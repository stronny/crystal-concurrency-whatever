class Connection < XNT::Job
  def main : Nil
    loop { connect_and_rescue }
  rescue x : Shutdown
    output_debug "#{@name} shutdown"
  end

  protected def connect_and_rescue : Nil
    connect_cycle
  rescue x : Shutdown
    raise x
  rescue x
    if @connected
      output_warn "#{@name} tcp error: #{x.inspect}"
    else
      output_warn "#{@name} connection error: #{x.inspect}"
    end
    output_debug "#{@name} sleeping before reconnecting"
    sleep_span Timeouts::Restart
  ensure
    @connected = false
  end

  protected def connect_cycle : Nil
    @socket = TCPSocket.new
    socket_connect @socket
    loop { read_write_cycle }
  ensure
    socket_close @socket
  end

  protected def read_write_cycle : Nil
    use read_ts @socket
    if @ttw
      write_ping @socket
      @ttw = false
    end
  end

  protected def use(ts : Nothing) : Nil; end

  protected def use(ts : Time) : Nil
    milsec = (Time.utc - ts).total_milliseconds
    Influx.push @influx_name, milsec
  end

  protected def sleep_span(span : Time::Span) : Nil
    @state = State::Sleeping.new
    sleep span
    raise Shutdown.new if @shutdown
  ensure
    @state = State::Free.new
  end
end

require "./connection/*"
