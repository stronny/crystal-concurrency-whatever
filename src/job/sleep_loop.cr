class XNT::Job::SleepLoop < XNT::Job

	@shutdown : Bool = false

	def initialize(@span : Time::Span)
	end

	def handle_shutdown : Nil
		return if @shutdown
		@shutdown = true
		@jiber.resume_event.add ZERO_SECONDS
	end

	def main : Nil
		setup
		loop do
			before_sleep
			sleep @span
			return if @shutdown
			after_sleep
		end
	end

	protected def setup : Nil
	end

	protected def before_sleep : Nil
	end

	protected def after_sleep : Nil
	end

end
