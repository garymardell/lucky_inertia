module Lucky::Renderable
  def inertia(
    component : String,
    props : Hash | NamedTuple = {} of String => String,
    view_data : Hash | NamedTuple = {} of String => String
  )
    Inertia::Renderer.render(component, props, context, self, view_data)
  end
end
