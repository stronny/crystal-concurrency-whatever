struct Endpoint
	DEFAULT_PORT = 2600
	ZEROES = Socket::IPAddress.new "0.0.0.0", DEFAULT_PORT

	getter sipa : Socket::IPAddress = ZEROES

	def initialize; end

	def initialize(ipv4 : String, port : Int32 = DEFAULT_PORT)
		validate_assign ipv4, port
	end

	def initialize(pull : JSON::PullParser)
		port = DEFAULT_PORT
		case pull.kind
		when JSON::PullParser::Kind::String
			ipv4 = pull.read_string
		when JSON::PullParser::Kind::BeginArray
			pull.read_begin_array
			ipv4 = pull.read_string
			case pull.kind
			when JSON::PullParser::Kind::Int
				port = pull.read_int.to_i32
				pull.read_end_array
			when JSON::PullParser::Kind::EndArray
				pull.read_end_array
			else
				raise JSON::ParseException.new "Expecting an optional int, not #{pull.kind}", pull.@lexer.token.line_number, pull.@lexer.token.column_number
			end
		else
			raise JSON::ParseException.new "Expecting a string or an array, not #{pull.kind}", pull.@lexer.token.line_number, pull.@lexer.token.column_number
		end
		validate_assign ipv4, port
	end

	def to_json(json : JSON::Builder)
		json.array do
			json.string @sipa.address
			json.number @sipa.port
		end
	end

	protected def validate_assign(ipv4 : String, port : Int32) : Nil
		raise ArgumentError.new "Invalid port #{port}" unless 0 < port < 65536
		old = @sipa
		begin
			@sipa = Socket::IPAddress.new ipv4, port
			raise ArgumentError.new "Not an IPv4 address: #{ipv4}" unless v4?
		rescue x
			@sipa = old
			raise x
		end
	end

	protected def v4? : Bool
		Socket::Family::INET == @sipa.family
	end
end
