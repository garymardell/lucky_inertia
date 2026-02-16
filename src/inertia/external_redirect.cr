module Inertia
  # Module to handle external redirects properly for Inertia
  # Inertia requires a 409 status code for external redirects
  module ExternalRedirect
    # Check if a URL is external (has a scheme and host)
    def external_redirect?(url : String) : Bool
      uri = URI.parse(url)
      !uri.scheme.nil? && !uri.host.nil?
    rescue URI::Error
      false
    end

    # Handle a redirect, using 409 status for Inertia external redirects
    def handle_redirect(url : String, status : Int32 = 302)
      if responds_to?(:inertia?) && inertia? && external_redirect?(url)
        # Inertia external redirect - use 409 with X-Inertia-Location header
        context.response.status_code = 409
        context.response.headers["X-Inertia-Location"] = url
        Lucky::TextResponse.new(context, "text/html", "", status: 409, enable_cookies: true)
      else
        # Normal redirect for non-Inertia requests or internal URLs
        redirect to: url, status: status
      end
    end
  end
end

# Include ExternalRedirect in all Lucky actions
class Lucky::Action
  include Inertia::ExternalRedirect
end
