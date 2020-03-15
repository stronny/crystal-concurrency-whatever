struct Nothing; end

NOTHING = Nothing.new

@[AlwaysInline]
def nothing : Nothing
  NOTHING
end

ZERO_SECONDS = 0.seconds
