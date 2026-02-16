module Inertia
  # Module to automatically share flash messages with Inertia responses
  # Include this in your base InertiaAction class to enable automatic flash sharing
  module FlashIntegration
    macro included
      before share_flash_with_inertia
    end

    private def share_flash_with_inertia
      # Only share flash for Inertia requests
      if responds_to?(:inertia?) && inertia?
        flash_data = {} of String => String
        
        # Collect all flash messages
        flash_data["success"] = flash.success if flash.success?
        flash_data["info"] = flash.info if flash.info?
        flash_data["failure"] = flash.failure if flash.failure?
        
        # Share flash using the shared data mechanism
        # Only add if there are flash messages
        unless flash_data.empty?
          inertia_share(flash: flash_data)
        end
      end
      
      continue
    end
  end
end
