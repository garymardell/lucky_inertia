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
      before share_validation_errors_with_inertia
      after clear_validation_errors_from_flash
    end

    # Share errors from flash with Inertia as props
    # This runs before every action via the `before` pipe
    private def share_validation_errors_with_inertia
      if inertia?
        errors = errors_from_flash
        inertia_share(errors: errors) unless errors.empty?
      end
      continue
    end
    
    # Clean up flash errors after request
    # This runs after every action via the `after` pipe
    private def clear_validation_errors_from_flash
      clear_errors_from_flash
      continue
    end
  end
end
