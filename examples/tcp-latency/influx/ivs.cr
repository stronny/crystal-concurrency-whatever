class Influx
  module Timeouts
    Connect  = 5.seconds
    Restart  = 5.seconds
    Interval = 1.seconds
  end

  class Shutdown < Exception; end

  abstract struct State
    struct Free < State; end

    struct Sleeping < State; end

    struct Reading < State; end

    struct Writing < State; end
  end

  @state : State = State::Free.new
  @connected : Bool = false
  @shutdown : Bool = false

  @host : String
  @port : Int32

  @socket : TCPSocket | Nothing = nothing

  @req : HTTP::Request

  def initialize(@host, @port)
    hdrs = HTTP::Headers.new
    hdrs["Host"] = "#{@host}:#{@port}"
    hdrs["Connection"] = "keep-alive"
    @req = HTTP::Request.new "POST", "/write?db=latency&precision=s", hdrs
  end
end
