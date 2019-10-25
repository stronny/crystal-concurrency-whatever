abstract class XNT::Job

	module Error
		class NoHandler < Exception; end
	end

	abstract def handle_shutdown : Nil
	abstract def main : Nil

	@jiber : XNT::Jiber = current_jiber

	@criticals : Hash(XNT::Jiber::ID, Nothing) = Hash(XNT::Jiber::ID, Nothing).new

	protected def self.current_jiber : XNT::Jiber
		jiber = Fiber.current
		raise "Job is run outside of a Jiber" unless jiber.is_a? Jiber
		jiber
	end


	def handle_finished(status : XNT::Jiber::Status::Finished) : Nil
		if status.error.is_a? Nothing
#p jchild_finished: status
@jiber.trace XNT::Trace::Event::ChildFinished.new status
		else
			handle_finished_error status
		end
		handle_finished_custom status
		if @criticals.has_key? status.jid
#			@criticals.delete status.jid       # maybe? not sure
			handle_shutdown
		end
	end


	def handle_finished_error(status : XNT::Jiber::Status::Finished) : Nil
#p jchild_error: status
@jiber.trace XNT::Trace::Event::ChildError.new status

XNT::STDOUT.puts status.error.as(Exception).inspect_with_backtrace
	end

	def handle_finished_custom(status : XNT::Jiber::Status::Finished) : Nil
		# override this for additional logic
	end

	def handle_interrupt(event : XNT::Jiber::Event) : Nil
		raise Error::NoHandler.new "No interrupt handler for #{event}"
	end


	def critical(jid : XNT::Jiber::ID) : XNT::Jiber::ID
		@criticals[jid] = nothing
		jid
	end


end
