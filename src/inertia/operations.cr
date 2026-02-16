module Inertia
  # Module to integrate Avram operations with Inertia's error handling
  # Automatically shares validation errors via flash and cleans them up after display
  #
  # Usage:
  #   abstract class InertiaAction < Lucky::Action
  #     include Inertia::Operations
  #   end
  #
  # Then in your actions:
  #   SaveUser.create(params) do |operation, user|
  #     if operation.saved?
  #       flash.success = "User created!"
  #       redirect to: Users::Show.with(user.id)
  #     else
  #       store_errors_in_flash(operation)
  #       flash.failure = "Please fix the errors"
  #       redirect to: Users::New
  #     end
  #   end
  module Operations
    macro included
      include Inertia::ValidationErrors
      after clear_validation_errors_from_flash
    end
    
    # Override collect_shared_data to include validation errors
    def collect_shared_data : Hash(String, JSON::Any)
      data = previous_def
      
      if inertia?
        errors = errors_from_flash
        unless errors.empty?
          data["errors"] = JSON.parse(errors.to_json)
        end
      end
      
      data
    end
    
    # Clean up flash errors after request
    # This runs after every action via the `after` pipe
    private def clear_validation_errors_from_flash
      clear_errors_from_flash
      continue
    end
  end
end
