struct XNT::Size

	alias Type = UInt32

	module Error
		class Overflow  < Exception; def initialize(cur : Type, dx : Type, max : Type); super "New size will overflow, current: #{cur}, increase: #{dx}, max: #{max}" end end
		class Underflow < Exception; def initialize(cur : Type, dx : Type, min : Type); super "New size will underflow, current: #{cur}, decrease: #{dx}, min: #{min}" end end
	end

	def initialize(@max : Type = Type::MAX, @size : Type = Type::MIN, @min : Type = Type::MIN)
		raise ArgumentError.new "Max (#{@max}) should be > min (#{@min})" if @max <= @min
		raise Error::Overflow.new @size, 0, @max if @size > @max
		raise Error::Underflow.new @size, 0, @min if @size < @min
	end

	def increase(amount : Type = 1) : Nil
		raise Error::Overflow.new @size, amount, @max if @size > (@max - amount)
		@size += amount
	end

	def decrease(amount : Type = 1) : Nil
		raise Error::Underflow.new @size, amount, @min if @size < (@min + amount)
		@size -= amount
	end

	def empty! : Nil
		@size = @min
	end

	def empty? : Bool
		@size <= @min
	end

	def full? : Bool
		@size >= @max
	end

	def raw : Type
		@size
	end

end
