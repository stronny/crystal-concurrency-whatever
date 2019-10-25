class XNT::ByteBuffer

	@slices : Deque(Bytes) = Deque(Bytes).new

	def push(slice : Bytes) : Nil
		@slices.push slice
	end

	def gets(delim : UInt8 = 10_u8) : String | Nothing
		found_at = nil
		slice_id = @slices.index { |slice| found_at = slice.index delim }
		return nothing if slice_id.nil?
		found_at = found_at.not_nil!

		length = @slices.each.first(slice_id).sum { |slice| slice.size }
		length += found_at

		String.build length do |line|
			slice_id.times { line.write @slices.shift } # shift the slices that don't have a delim
			line.write @slices[0][0,found_at]
			@slices[0] += (found_at + 1)
			@slices.shift if @slices[0].size.zero?
		end
	end

end
