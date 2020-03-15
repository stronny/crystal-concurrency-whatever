class XNT::Queue(T)
  struct Empty; end

  module Error
    class Full < Exception
      def initialize
        super "Queue is full"
      end
    end

    class Empty < Exception
      def initialize
        super "Queue is empty"
      end
    end
  end

  def initialize(capacity : UInt32)
    @size = XNT::Size.new capacity
    @first = XNT::RingIndex.new capacity
    @data = Array(T | Empty).new capacity, Empty.new
  end

  # Push operations
  #
  def push!(e : T) : Nil
    push(e) { drop_first }
  end

  def push(e : T) : Nil
    push(e) { raise Error::Full.new }
  end

  def push(e : T) : Nil
    yield if full?
    @size.increase
    @data[last] = e
  end

  # Unshift operations
  #
  def unshift!(e : T) : Nil
    unshift(e) { drop_last }
  end

  def unshift(e : T) : Nil
    unshift(e) { raise Error::Full.new }
  end

  def unshift(e : T) : Nil
    yield if full?
    @size.increase
    @first.left
    @data[first] = e
  end

  # Pop operations
  #
  def pop : T
    raise Error::Empty.new if empty?
    res = @data[last]
    drop_last
    res
  end

  def pop : T
    return yield if empty?
    pop
  end

  def pop? : T?
    return nil if empty?
    pop
  end

  # Shift operations
  #
  def shift : T
    raise Error::Empty.new if empty?
    res = @data[first]
    drop_first
    res
  end

  def shift : T
    return yield if empty?
    shift
  end

  def shift? : T?
    return nil if empty?
    shift
  end

  # Misc operations
  #
  def empty? : Bool
    @size.empty?
  end

  def full? : Bool
    @size.full?
  end

  def clear! : Nil
    @size.empty!
  end

  def inspect(io : IO) : Nil
    to_s io
  end

  #	def to_s(io : IO) : Nil
  #		io << self.class << "["
  #		if ! empty?
  #			size = @size
  #			size.decrease
  #			size.raw.times { |ofs| io << @data[real_index(ofs)] << ", " }
  #			io << @data[last]
  #		end
  #		io << ']'
  #	end

  #	def to_slice : Slice(T)
  #		Slice(T).new @size.raw { |ofs| @data[real_index(ofs)] }
  #	end

  # Helpers
  #
  #	private def real_index(n : Index) : Int32
  #		raise Error::Empty.new if empty?
  #		(@real_first + n) % N
  #	end

  private def first : Int32
    #		real_index 0
    @first.to_i32
  end

  private def last : Int32
    @first.to_i32(@size) - 1
    #		id = Index.new @size.raw
    #		id.decrease
    #		real_index(id)
  end

  private def drop_first : Nil
    #		@real_first = real_index 1
    @first.right
    @size.decrease
  end

  private def drop_last : Nil
    @size.decrease
  end
end
