struct Config
  Filenames = ["tcp-latency.js"]

  alias Peers = Hash(String, Endpoint)

  JSON.mapping(
    peers: {type: Peers, default: Peers.new},
  )

  def initialize
    @peers = Peers.new
  end

  def self.from_default_files : self
    Filenames.each do |cfn|
      begin
        config = from_file cfn
        return config
      rescue x
        output_warn "config error: #{x.inspect}"
        next
      end
    end
    new
  end

  def self.from_file(fn : String) : self
    File.open fn do |fd|
      Config.from_json fd
    end
  end
end
