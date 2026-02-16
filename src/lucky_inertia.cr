require "lucky"
require "habitat"

module Inertia
  class_property html_headers = HTTP::Headers.new

  Habitat.create do
    # Asset versioning - set to a hash or version string to enable cache busting
    setting version : String? = nil
    
    # Server-side rendering configuration
    setting ssr_enabled : Bool = false
    setting ssr_url : String = "http://localhost:13714"
    setting ssr_timeout : Time::Span = 30.seconds
    
    # Data management options
    setting deep_merge_shared_data : Bool = false
    setting include_flash : Bool = true
    setting include_errors : Bool = true
  end
end

require "./inertia/*"
require "./lucky/*"
