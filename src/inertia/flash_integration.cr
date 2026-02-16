module Inertia
  # Module to automatically share flash messages with Inertia responses
  # Include this in your base InertiaAction class to enable automatic flash sharing
  module FlashIntegration
    # Override collect_shared_data to include flash messages
    def collect_shared_data : Hash(String, JSON::Any)
      data = previous_def
      
      # Only add flash for Inertia requests
      if responds_to?(:inertia?) && inertia?
        flash_data = {} of String => String
        
        # Collect all flash messages
        flash_data["success"] = flash.success if flash.success?
        flash_data["info"] = flash.info if flash.info?
        flash_data["failure"] = flash.failure if flash.failure?
        
        # Only add if there are flash messages
        unless flash_data.empty?
          data["flash"] = JSON.parse(flash_data.to_json)
        end
      end
      
      data
    end
  end
end
