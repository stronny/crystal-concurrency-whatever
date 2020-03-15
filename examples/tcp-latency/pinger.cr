class Pinger < XNT::Job::SleepLoop
  @influx_jid : XNT::Jiber::ID

  def initialize(@span, @config : Config, @ee : EE)
    @influx_jid = @jiber.start_child do
      XNT::Wiber.new do
        Influx.new @ee.influxdb.host, @ee.influxdb.port.to_i32
      end
    end
    critical @influx_jid
  end

  protected def setup : Nil
    @config.peers.each do |name, ep|
      jid = @jiber.start_child do
        XNT::Wiber.new do
          Connection.new name, ep
        end
      end
      critical jid
    end
  end

  protected def after_sleep : Nil
    @jiber.children_jids.each do |jid|
      next if jid == @influx_jid
      XNT::Jibers.interrupt_if_running jid, Connection::Event::Ping.new
    end
  end
end
