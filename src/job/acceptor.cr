class XNT::Job::Acceptor < XNT::Job

	def initialize(@server : Socket, &@create_client : Proc(Socket, XNT::Job))
	end

	def handle_shutdown : Nil
		@server.close
	end

	def main : Nil
		accept_loop
	ensure
		@server.close
	end

	protected def accept_loop : Nil
		while socket = @server.accept?
			accepted socket
		end
	end

	protected def accepted(socket : Socket) : Nil
		@jiber.start_child do
			XNT::Wiber.new do
				@create_client.call socket
			end
		end
	end

end
