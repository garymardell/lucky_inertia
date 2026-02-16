module Inertia
  module PartialReload
    extend self

    # Filter props based on partial reload headers
    def filter_props(
      all_props : Hash,
      context : HTTP::Server::Context,
      component : String
    ) : Hash
      return all_props unless partial_reload?(context, component)

      only = get_only_props(context)
      except = get_except_props(context)

      # Start with all props
      filtered = all_props

      # Apply "only" filter
      if only && !only.empty?
        filtered = filter_only(filtered, only)
      end

      # Apply "except" filter
      if except && !except.empty?
        filtered = filter_except(filtered, except)
      end

      # Evaluate lazy props that were requested
      evaluate_lazy_props(filtered, only)
    end

    private def partial_reload?(context : HTTP::Server::Context, component : String) : Bool
      return false unless context.request.headers.has_key?("X-Inertia-Partial-Component")
      context.request.headers["X-Inertia-Partial-Component"] == component
    end

    private def get_only_props(context) : Array(String)?
      context.request.headers["X-Inertia-Partial-Data"]?.try(&.split(",").map(&.strip))
    end

    private def get_except_props(context) : Array(String)?
      context.request.headers["X-Inertia-Partial-Except"]?.try(&.split(",").map(&.strip))
    end

    private def filter_only(props : Hash, only : Array(String)) : Hash
      result = Hash(String, JSON::Any).new
      only.each do |key|
        if props.has_key?(key)
          result[key] = props[key]
        end
      end
      result
    end

    private def filter_except(props : Hash, except : Array(String)) : Hash
      result = props.dup
      except.each { |key| result.delete(key) }
      result
    end

    private def evaluate_lazy_props(props : Hash, only : Array(String)?) : Hash
      props.transform_values do |value|
        case value
        when LazyProp
          # Only evaluate if in "only" list or no filter specified
          (only.nil? || only.empty?) ? value : value
        when AlwaysProp
          # Always evaluate
          value.call
        else
          value
        end
      end
    end
  end
end
