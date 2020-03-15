module XNT::STDOUT
  @@write_deq : Deque(String) = Deque(String).new
  @@sleeping : Bool = true

  @@jiber : XNT::Jiber | Nothing = nothing

  def self.eq?(other : XNT::Jiber) : Bool
    jiber == other
  end

  def self.jiber : XNT::Jiber
    jiber = @@jiber
    return jiber unless jiber.is_a? Nothing
    jiber = XNT::Wiber.new do
      Writer.new
    end
    p stdout: jiber
    @@jiber = jiber
  end

  def self.write_deq : Deque(String)
    @@write_deq
  end

  def self.puts(line : String) : Nil
    @@write_deq.push line
    if @@sleeping
      @@sleeping = false
      Crystal::Scheduler.enqueue jiber
    end
  end

  def self.report_sleep : Nil
    @@sleeping = true
  end

  def self.deport_sleep : Nil
    @@sleeping = false
  end

  def self.sleeping? : Bool
    @@sleeping
  end
end

class XNT::STDOUT::Writer < XNT::Job
  @shutdown : Bool = false

  def handle_shutdown : Nil
    return if @shutdown
    @shutdown = true
    wakeup
  end

  def wakeup : Nil
    return unless XNT::STDOUT.sleeping?
    XNT::STDOUT.deport_sleep
    Crystal::Scheduler.enqueue @jiber
  end

  def main : Nil
    loop do
      while line = XNT::STDOUT.write_deq.shift?
        ::STDOUT.puts line
      end
      XNT::STDOUT.report_sleep
      sleep
      return if @shutdown
    end
  end
end
