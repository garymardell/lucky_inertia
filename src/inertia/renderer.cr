require "json"
require "http/server"
require "lucky"

require "./annotations"

module Inertia
  module Renderer
    extend self

    macro finished
      {% for cls in Lucky::HTMLPage.includers %}
        {% if ann = cls.annotation(Inertia::RootLayout) %}
          ROOT_LAYOUT = {{ cls }}
        {% end %}
      {% end %}
    end

    def render(
      component : String,
      props : Hash | NamedTuple,
      context : HTTP::Server::Context,
      action : Lucky::Action,
      view_data : Hash | NamedTuple = {} of String => String
    ) : Lucky::TextResponse
      request = context.request
      response = context.response
      if request.headers.has_key?("X-Inertia")
        response.headers["Vary"] = "Accept"
        response.headers["X-Inertia"] = "true"
        payload = make_page(component, props, context, action)
        json_response(payload.to_json, context)
      else
        return render_ssr(component, props, context, action, view_data) if Inertia.settings.ssr_enabled?
        html_response(component, props, context, action, view_data: view_data)
      end
    end

    private def render_ssr(component, props, context, action, view_data)
      page = make_page(component, props, context, action)
      uri = URI.parse(Inertia.settings.ssr_url + "/render")

      res = HTTP::Client.post(uri, body: page.to_json, headers: HTTP::Headers{"Content-Type" => "application/json"})
      json = JSON.parse(res.body)

      head = json["head"].as_a.map(&.as_s)
      body = json["body"].as_s

      html_response(component, props, context, action, view_data: view_data, head: head, content: body)
    end

    private def make_page(component, props, context, action)
      # Merge shared data with page props
      shared_data = action.responds_to?(:collect_shared_data) ? action.collect_shared_data : {} of String => JSON::Any
      all_props = merge_props(shared_data, props)
      
      # Apply partial reload filtering if applicable
      filtered_props = PartialReload.filter_props(all_props, context, component)
      
      {
        component: component,
        props:     filtered_props,
        url:       context.request.path,
        version:   Inertia.settings.version,
      }
    end
    
    private def merge_props(shared_data : Hash, page_props : Hash | NamedTuple)
      # Convert page_props to Hash(String, JSON::Any)
      merged = shared_data.dup
      
      page_props.each do |key, value|
        merged[key.to_s] = JSON.parse(value.to_json)
      end
      
      merged
    end

    private def json_response(body, context)
      Lucky::TextResponse.new(
        context,
        "application/json",
        body,
        status: context.response.status_code,
        enable_cookies: true,
      )
    end

    private def html_response(component, props, context, action, view_data = {} of String => String, head = [] of String, content = nil)
      page = make_page(component, props, context, action)
      view = ROOT_LAYOUT.new(context: context, page: page.to_json, view_data: view_data, head: head, content: content)
      Lucky::TextResponse.new(
        context,
        "text/html",
        view.perform_render,
        status: context.response.status_code,
        enable_cookies: true,
      )
    end
  end
end
