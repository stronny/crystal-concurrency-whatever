class Connection
  def handle_shutdown : Nil
    return if @shutdown
    @shutdown = true
    interrupt_blocking_call @state
  end

  def handle_interrupt(event : Event::Ping) : Nil
    return unless @connected
    state = @state
    return unless state.is_a? State::Reading
    @ttw = true
    interrupt_blocking_call state
  end

  protected def interrupt_blocking_call(state : State::Free) : Nil
    raise "free state"
  end

  protected def interrupt_blocking_call(state : State::Sleeping) : Nil
    @jiber.resume_event.add ZERO_SECONDS
  end

  protected def interrupt_blocking_call(state : State::Reading) : Nil
    socket = @socket
    raise "no socket" if socket.is_a? Nothing
    socket.read_timeout!
  end

  protected def interrupt_blocking_call(state : State::Writing) : Nil
    socket = @socket
    raise "no socket" if socket.is_a? Nothing
    socket.write_timeout!
  end
end
