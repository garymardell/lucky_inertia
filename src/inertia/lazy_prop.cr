module Inertia
  # Wrapper for lazy-evaluated props
  # Only evaluates the block when the value is needed, then caches the result
  class LazyProp(T)
    @value : T?
    @evaluated = false

    def initialize(@block : -> T)
    end

    def call : T
      return @value.not_nil! if @evaluated
      @value = @block.call
      @evaluated = true
      @value.not_nil!
    end

    def to_json(builder : JSON::Builder)
      call.to_json(builder)
    end
  end

  # Wrapper for "always" props - always evaluated even in partial reloads
  class AlwaysProp(T)
    def initialize(@block : -> T)
    end

    def call : T
      @block.call
    end

    def to_json(builder : JSON::Builder)
      call.to_json(builder)
    end
  end

  # Helper method to create a lazy prop
  # Usage: Inertia.lazy { expensive_computation }
  def self.lazy(&block : -> T) forall T
    LazyProp(T).new(block)
  end

  # Helper method to create an always-evaluated prop
  # Usage: Inertia.always { always_needed_value }
  def self.always(&block : -> T) forall T
    AlwaysProp(T).new(block)
  end
end
