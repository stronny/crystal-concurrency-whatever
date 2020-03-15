struct EE
  DEF_FILENAME = "environment.json"

  struct Influx
    JSON.mapping(
      host: {type: String, getter: true},
      port: {type: Int64, getter: true},
    )
  end

  JSON.mapping(
    influxdb: {type: Influx, getter: true},
  )

  def self.from_default_files : self
    File.open DEF_FILENAME do |fd|
      from_json fd
    end
  end

  def influx_ep : Endpoint
    Endpoint.new @influxdb.host, @influxdb.port.to_i32
  end
end
