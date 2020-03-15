#!/usr/bin/env crystal

require "crystal-concurrency"

require "./util"
require "./connection"
require "./server"

p :hi
count = ARGV.first.to_i
server = TCPServer.new "localhost", 3001
jiber = XNT::Wiber.new do
  Server.new count, server
end
Crystal::Scheduler.enqueue jiber

Signal::INT.trap { jiber.interrupt XNT::Jiber::Event::Shutdown.new }

Crystal::Scheduler.wake_me_up_after_first_of_these_children_finish({jiber.id})
p :bye
