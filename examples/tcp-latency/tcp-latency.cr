#!/usr/bin/env crystal

require "json"
require "http"
require "crystal-concurrency"

require "./patches"

require "./endpoint"
require "./ee"
require "./config"
require "./connection"
require "./influx"
require "./pinger"

module Globals
  Debug = ((ENV.fetch("TCPLATENCY_DEBUG", "").bytesize > 0) || ARGV.includes?("--debug"))
  Trace = ((ENV.fetch("TCPLATENCY_TRACE", "").bytesize > 0) || ARGV.includes?("--trace"))
end

def output_error(text : String) : Nil
  STDERR << "<3>" << text << "\n"
end

def output_warn(text : String) : Nil
  STDERR << "<4>" << text << "\n"
end

def output_note(text : String) : Nil
  STDERR << "<5>" << text << "\n"
end

macro output_debug(text)
	if Globals::Debug
		STDERR << "<7>" << {{ text }} << "\n"
	end
end

STDOUT.blocking = true
STDERR.blocking = true

module XNT::Jiber
  def trace(event : XNT::Trace::Event) : Nil
    return unless Globals::Trace
    previous_def
  end
end

pinger = XNT::Wiber.new do
  Pinger.new 1.seconds, Config.from_default_files, EE.from_default_files
end
Crystal::Scheduler.enqueue pinger

Signal::INT.trap { pinger.interrupt XNT::Jiber::Event::Shutdown.new }
Signal::TERM.trap { pinger.interrupt XNT::Jiber::Event::Shutdown.new }

Crystal::Scheduler.wake_me_up_after_all_of_these_children_finish({pinger.id})
