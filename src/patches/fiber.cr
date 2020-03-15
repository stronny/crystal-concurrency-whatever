class Fiber
  def free_resume_event
    re = @resume_event
    return if re.nil?
    re.free
    @resume_event = nil
  end
end
