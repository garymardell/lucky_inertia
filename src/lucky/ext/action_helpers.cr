module Lucky::InertiaHelpers
  # Check if the current request is an Inertia request
  def inertia? : Bool
    context.request.headers.has_key?("X-Inertia")
  end

  # Check if the current request is a partial reload request
  def inertia_partial? : Bool
    inertia? && context.request.headers.has_key?("X-Inertia-Partial-Component")
  end

  # Get the list of props to include in a partial reload (nil if not a partial request)
  def partial_only : Array(String)?
    return nil unless inertia_partial?
    context.request.headers["X-Inertia-Partial-Data"]?.try(&.split(",").map(&.strip))
  end

  # Get the list of props to exclude in a partial reload (nil if not a partial request)
  def partial_except : Array(String)?
    return nil unless inertia_partial?
    context.request.headers["X-Inertia-Partial-Except"]?.try(&.split(",").map(&.strip))
  end
end

# Include helpers in all Lucky actions
class Lucky::Action
  include Lucky::InertiaHelpers
end
