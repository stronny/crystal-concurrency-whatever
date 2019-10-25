class XNT::Jibers



	module Error

		class NotFound < Exception
			getter jid : XNT::Jiber::ID
			def initialize(@jid : XNT::Jiber::ID)
				super "JID not found: #{jid}"
			end
		end

		class Unrelated < Exception
			getter status : XNT::Jiber::Status
			def initialize(@status : XNT::Jiber::Status)
				super "Jiber is unrelated: #{status}"
			end
		end

		class Conflict < Exception
			getter status : XNT::Jiber::Status
			getter jid : XNT::Jiber::ID
			def initialize(@status, @jid)
				super "Existing status #{status} conflicts with JID #{jid}"
			end
		end

		class UnexpectedState(T) < Exception
			getter status : XNT::Jiber::Status
			def initialize(@status)
				super "Expecting #{T}, not #{status}"
			end
		end

		class Exists < Exception; end

	end





	@@table = Hash(XNT::Jiber::ID, XNT::Jiber::Status).new

	@@next_jid : XNT::Jiber::ID = XNT::Jiber::ID.new 0

	@@wakeup_table_any   : Hash(Fiber, Hash(XNT::Jiber::ID, Nothing)) = Hash(Fiber, Hash(XNT::Jiber::ID, Nothing)).new
	@@wakeup_table_every : Hash(Fiber, Hash(XNT::Jiber::ID, Nothing)) = Hash(Fiber, Hash(XNT::Jiber::ID, Nothing)).new

	def self.new_jid : XNT::Jiber::ID
		this_jid = @@next_jid
		@@next_jid += 1
		raise "JID space exhausted" unless @@next_jid > this_jid # FIXME good enough for a prototype
		this_jid
	end

	def self.interrupt_if_running(jid : XNT::Jiber::ID, event : XNT::Jiber::Event) : Nil
		status = @@table[jid]?
		status.interrupt event if status.is_a? XNT::Jiber::Status::Running
	end

	def self.shutdown_if_running(jid : XNT::Jiber::ID) : Nil
		status = @@table[jid]?
		status.shutdown if status.is_a? XNT::Jiber::Status::Running
	end

	def self.ensure_all_exist_and_children(jids : Indexable(XNT::Jiber::ID)) : Nil
		jids.each do |jid|
			case status = @@table[jid]
				when XNT::Jiber::Status::Created
					raise Error::Unrelated.new status unless Fiber.current == status.jiber.parent
				when XNT::Jiber::Status::Running
					raise Error::Unrelated.new status unless Fiber.current == status.jiber.parent
				when XNT::Jiber::Status::Finished
					raise Error::Unrelated.new status unless Fiber.current == status.parent
			end
		end
	end

	def self.any_finished?(jids : Indexable(XNT::Jiber::ID)) : Bool
		jids.any? { |jid| @@table[jid].is_a? XNT::Jiber::Status::Finished }
	end

	def self.all_finished?(jids : Indexable(XNT::Jiber::ID)) : Bool
		jids.all? { |jid| @@table[jid].is_a? XNT::Jiber::Status::Finished }
	end

	def self.any_running_or_finished?(jids : Indexable(XNT::Jiber::ID)) : Bool
		jids.any? { |jid| @@table[jid].is_a? XNT::Jiber::Status::Running || @@table[jid].is_a? XNT::Jiber::Status::Finished }
	end

	def self.all_running_or_finished?(jids : Indexable(XNT::Jiber::ID)) : Bool
		jids.all? { |jid| @@table[jid].is_a? XNT::Jiber::Status::Running || @@table[jid].is_a? XNT::Jiber::Status::Finished }
	end

	def self.select_unfinished(jids : Indexable(XNT::Jiber::ID)) : Nil
		jids.each do |jid|
			next if @@table[jid].is_a? XNT::Jiber::Status::Finished
			yield jid
		end
	end

	def self.select_created(jids : Indexable(XNT::Jiber::ID)) : Nil
		jids.each do |jid|
			next unless @@table[jid].is_a? XNT::Jiber::Status::Created
			yield jid
		end
	end

	def self.register(jiber : XNT::Jiber) : Nil
		raise Error::Conflict.new @@table[jiber.id], jiber.id if @@table.has_key? jiber.id
		@@table[jiber.id] = XNT::Jiber::Status::Created.new jiber
	end

	def self.make_jiber_running(jiber : XNT::Jiber) : Nil
		status = @@table.delete jiber.id do |k| raise Error::NotFound.new k end
		raise Error::Unrelated.new status unless Fiber.current == jiber
		status = make_jiber_running_typecase status
		@@table[jiber.id] = status.make_running
		check_and_wakeup_my_parent jiber
	end

	protected def self.make_jiber_running_typecase(status : XNT::Jiber::Status::Created) : XNT::Jiber::Status::Created
		status
	end

	protected def self.make_jiber_running_typecase(status : XNT::Jiber::Status::Running) : XNT::Jiber::Status::Created
		raise Error::UnexpectedState(XNT::Jiber::Status::Created).new status
	end

	protected def self.make_jiber_running_typecase(status : XNT::Jiber::Status::Finished) : XNT::Jiber::Status::Created
		raise Error::UnexpectedState(XNT::Jiber::Status::Created).new status
	end



	private def self.check_and_wakeup_my_parent(me : XNT::Jiber) : Nil
		wakeup = false
		wakeup = true if check_wakeup_table_any me
		wakeup = true if check_wakeup_table_every me
		Crystal::Scheduler.enqueue me.parent if wakeup
	end

	private def self.check_wakeup_table_any(me : XNT::Jiber) : Bool
		return false unless jids = @@wakeup_table_any[me.parent]?
		raise "Anytable is empty for #{me.parent}" if jids.empty?
		return false unless jids.has_key? me.id
		@@wakeup_table_any.delete me.parent
		true
	end

	private def self.check_wakeup_table_every(me : XNT::Jiber) : Bool
		return false unless jids = @@wakeup_table_every[me.parent]?
		jids.delete me.id
		return false unless jids.empty?
		@@wakeup_table_every.delete me.parent
		true
	end




	def self.debrief_finished_jiber(jiber : XNT::Jiber, error : XNT::Jiber::Status::Error) : Nil
		status = @@table.delete jiber.id do |k| raise Error::NotFound.new k end
		raise Error::Unrelated.new status unless Fiber.current == jiber
		status = debrief_finished_jiber_typecase status
		@@table[jiber.id] = status.make_finished jiber.parent, error
	end

	protected def self.debrief_finished_jiber_typecase(status : XNT::Jiber::Status::Created) : XNT::Jiber::Status::Running
		raise Error::UnexpectedState(XNT::Jiber::Status::Running).new status
	end

	protected def self.debrief_finished_jiber_typecase(status : XNT::Jiber::Status::Running) : XNT::Jiber::Status::Running
		status
	end

	protected def self.debrief_finished_jiber_typecase(status : XNT::Jiber::Status::Finished) : XNT::Jiber::Status::Running
		raise Error::UnexpectedState(XNT::Jiber::Status::Running).new status
	end


	def self.reap_finished_child(jid : XNT::Jiber::ID) : XNT::Jiber::Status::Finished
		status = @@table.delete jid do |k| raise Error::NotFound.new k end
		reap_finished_child_typecase status
	end

	protected def self.reap_finished_child_typecase(status : XNT::Jiber::Status::Created) : XNT::Jiber::Status::Finished
		raise Error::UnexpectedState(XNT::Jiber::Status::Finished).new status
	end

	protected def self.reap_finished_child_typecase(status : XNT::Jiber::Status::Running) : XNT::Jiber::Status::Finished
		raise Error::UnexpectedState(XNT::Jiber::Status::Finished).new status
	end

	protected def self.reap_finished_child_typecase(status : XNT::Jiber::Status::Finished) : XNT::Jiber::Status::Finished
		raise Error::Unrelated.new status unless Fiber.current == status.parent
		status
	end



	def self.wake_me_up_after_first_of_these_children_start(jids : Indexable(XNT::Jiber::ID)) : Nil
		return if jids.empty?
		ensure_all_exist_and_children jids
		return if any_running_or_finished? jids
		raise Error::Exists.new "wakeup_table_any: #{Fiber.current}" if @@wakeup_table_any.has_key? Fiber.current
		@@wakeup_table_any[Fiber.current] = Hash(XNT::Jiber::ID, Nothing).new
		jids.each { |jid| @@wakeup_table_any[Fiber.current][jid] = nothing }
		if @@wakeup_table_any[Fiber.current].empty?
			@@wakeup_table_any.delete Fiber.current
			return
		end
		sleep
	end

	def self.wake_me_up_after_all_of_these_children_start(jids : Indexable(XNT::Jiber::ID)) : Nil
		return if jids.empty?
		ensure_all_exist_and_children jids
		return if all_running_or_finished? jids
		raise Error::Exists.new "wakeup_table_every: #{Fiber.current}" if @@wakeup_table_every.has_key? Fiber.current
		@@wakeup_table_every[Fiber.current] = Hash(XNT::Jiber::ID, Nothing).new
		select_created jids do |jid| @@wakeup_table_every[Fiber.current][jid] = nothing end
		if @@wakeup_table_every[Fiber.current].empty?
			@@wakeup_table_every.delete Fiber.current
			return
		end
		sleep
	end

end
