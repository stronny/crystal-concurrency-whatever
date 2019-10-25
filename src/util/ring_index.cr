struct XNT::RingIndex

	module Error
		class Overflow  < Exception; end
		class Underflow < Exception; end
	end

	alias Type = UInt32

	def initialize(@size : Type, @i : Type = Type::MIN)
		rotate!
	end

	def right(amount : Type = 1)
		@i += amount
		rotate!
	end

	def left(amount : Type = 1)
		@i -= amount
		rotate!
	end

	def to_i32 : Int32
		raise Error::Overflow.new if @i > Int32::MAX
		raise Error::Underflow.new if @i < Int32::MIN
		@i.to_i32
	end

	def to_i32(offset : Size) : Int32
		id = dup
		id.right offset.raw
		id.to_i32
	end

	def to_i32(offset : Int32) : Int32
		id = dup
		if offset > 0
			id.right offset.to_u32
		elsif offset < 0
			id.left (-offset).to_u32
		end
		id.to_i32
	end

	private def rotate! : Nil
		@i = @i % @size
	end

end
