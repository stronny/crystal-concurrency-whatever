module IO::Evented

	def read_timeout! : Nil
		ev = @read_event.get?
		return unless ev
		ev.add ZERO_SECONDS
	end

	def write_timeout! : Nil
		ev = @write_event.get?
		return unless ev
		ev.add ZERO_SECONDS
	end

end
