#!/usr/bin/env crystal

require "crystal-concurrency"

class Hello < XNT::Job
  def initialize(@gen : Int32 = 1)
  end

  def handle_shutdown : Nil
    p :jshutdown
  end

  def main : Nil
    pjid = nil
    parent = @jiber.parent
    pjid = parent.id if parent.is_a? XNT::Jiber
    p jhello: {@gen, pjid, @jiber.id}
    return if @gen > 3

    children = @gen.times.map do
      @jiber.start_child { XNT::Wiber.new { Hello.new(@gen + 1) } }
    end

    Crystal::Scheduler.wake_me_up_after_all_of_these_children_finish children.to_a
    p woke: self
  end
end

p :hi

# h = Hello.new

jiber = XNT::Wiber.new { Hello.new }
Crystal::Scheduler.enqueue jiber

Crystal::Scheduler.wake_me_up_after_first_of_these_children_finish({jiber.id})
p :bye
