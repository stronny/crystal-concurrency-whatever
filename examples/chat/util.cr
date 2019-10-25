#module Connections
#	@@table : Hash(XNT::Jiber::ID, Nothing) = Hash(XNT::Jiber::ID, Nothing).new
#	def self.register(jid : XNT::Jiber::ID) : Nil
#		@@table[jid] = nothing
#	end
#	def self.leave(jid : XNT::Jiber::ID) : Nil
#		@@table.delete jid
#	end
#	def self.publish(jid : XNT::Jiber::ID, line : String) : Nil
#		@@table.keys.each { |jid| XNT::Jibers.interrupt_if_running jid, Connection::Event::Write.new line.to_slice }
#	end
#end



class Ticker < XNT::Job::SleepLoop
	TICK = "tick".to_slice
	protected def after_sleep : Nil
		parent = @jiber.parent
		parent.interrupt Connection::Event::Write.new TICK if parent.is_a? XNT::Jiber
	end
end
