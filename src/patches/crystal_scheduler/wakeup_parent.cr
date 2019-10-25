class Crystal::Scheduler

	@wakeup_table_any   : Hash(Fiber, Hash(XNT::Jiber::ID, Nothing)) = Hash(Fiber, Hash(XNT::Jiber::ID, Nothing)).new
	@wakeup_table_every : Hash(Fiber, Hash(XNT::Jiber::ID, Nothing)) = Hash(Fiber, Hash(XNT::Jiber::ID, Nothing)).new

	def self.wake_me_up_after_first_of_these_children_finish(jids : Indexable(XNT::Jiber::ID)) : Nil
		Thread.current.scheduler.wake_me_up_after_first_of_these_children_finish jids
	end

	def self.wake_me_up_after_all_of_these_children_finish(jids : Indexable(XNT::Jiber::ID)) : Nil
		Thread.current.scheduler.wake_me_up_after_all_of_these_children_finish jids
	end

	def wake_me_up_after_first_of_these_children_finish(jids : Indexable(XNT::Jiber::ID)) : Nil
		return if jids.empty?
		XNT::Jibers.ensure_all_exist_and_children jids
		return if XNT::Jibers.any_finished? jids
		fatal_resume_error @current, "reassigning wakeup_table_any" if @wakeup_table_any.has_key? @current
		@wakeup_table_any[@current] = Hash(XNT::Jiber::ID, Nothing).new
		jids.each { |jid| @wakeup_table_any[@current][jid] = nothing }
		if @wakeup_table_any[@current].empty?
			@wakeup_table_any.delete @current
			return
		end
		reschedule
	end

	def wake_me_up_after_all_of_these_children_finish(jids : Indexable(XNT::Jiber::ID)) : Nil
		return if jids.empty?
		XNT::Jibers.ensure_all_exist_and_children jids
		return if XNT::Jibers.all_finished? jids
		fatal_resume_error @current, "reassigning wakeup_table_every" if @wakeup_table_every.has_key? @current
		@wakeup_table_every[@current] = Hash(XNT::Jiber::ID, Nothing).new
		XNT::Jibers.select_unfinished jids do |jid| @wakeup_table_every[@current][jid] = nothing end
		if @wakeup_table_every[@current].empty?
			@wakeup_table_every.delete @current
			return
		end
		reschedule
	end

	private def check_and_wakeup_my_parent(me : XNT::Jiber) : Nil
		wakeup = false
		wakeup = true if check_wakeup_table_any me
		wakeup = true if check_wakeup_table_every me
		enqueue me.parent if wakeup
	end

	private def check_wakeup_table_any(me : XNT::Jiber) : Bool
		return false unless jids = @wakeup_table_any[me.parent]?
		raise "Anytable is empty for #{me.parent}" if jids.empty?
		return false unless jids.has_key? me.id
		@wakeup_table_any.delete me.parent
		true
	end

	private def check_wakeup_table_every(me : XNT::Jiber) : Bool
		return false unless jids = @wakeup_table_every[me.parent]?
		jids.delete me.id
		return false unless jids.empty?
		@wakeup_table_every.delete me.parent
		true
	end

end
