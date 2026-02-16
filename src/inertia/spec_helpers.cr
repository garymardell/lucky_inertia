module Inertia::SpecHelpers
  # Assert that the response is an Inertia response
  def assert_inertia_response(response : HTTP::Client::Response)
    response.headers["X-Inertia"]?.should eq("true")
    response.headers["Vary"]?.should eq("Accept")
  end

  # Assert that the Inertia response renders a specific component
  def assert_inertia_component(response : HTTP::Client::Response, component : String)
    assert_inertia_response(response)
    data = JSON.parse(response.body)
    data["component"].as_s.should eq(component)
  end

  # Assert specific props in the Inertia response
  # Yields the props hash for custom assertions
  def assert_inertia_props(response : HTTP::Client::Response, &block)
    assert_inertia_response(response)
    data = JSON.parse(response.body)
    props = data["props"].as_h
    yield props
  end

  # Assert the Inertia version matches
  def assert_inertia_version(response : HTTP::Client::Response, version : String)
    assert_inertia_response(response)
    data = JSON.parse(response.body)
    data["version"]?.try(&.as_s).should eq(version)
  end

  # Create HTTP headers for an Inertia request
  def inertia_headers(version : String? = nil) : HTTP::Headers
    headers = HTTP::Headers.new
    headers["X-Inertia"] = "true"
    headers["X-Inertia-Version"] = version if version
    headers
  end

  # Create HTTP headers for an Inertia partial reload request
  def inertia_partial_headers(
    component : String,
    only : Array(String)? = nil,
    except : Array(String)? = nil
  ) : HTTP::Headers
    headers = inertia_headers
    headers["X-Inertia-Partial-Component"] = component
    headers["X-Inertia-Partial-Data"] = only.join(",") if only
    headers["X-Inertia-Partial-Except"] = except.join(",") if except
    headers
  end
end
