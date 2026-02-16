module Inertia
  module ValidationErrors
    # Session key for storing Inertia validation errors
    FLASH_ERRORS_KEY = "_inertia_errors"

    # Store operation errors in session for redirect
    # This allows errors to survive the POST-Redirect-GET pattern
    def store_errors_in_flash(operation : Avram::Operation)
      errors_hash = {} of String => Array(String)

      operation.errors.each do |attribute, messages|
        errors_hash[attribute.to_s] = messages
      end

      session.set(FLASH_ERRORS_KEY, errors_hash.to_json)
    end

    # Retrieve errors from session
    # Returns an empty hash if no errors are stored
    def errors_from_flash : Hash(String, Array(String))
      if json = session.get?(FLASH_ERRORS_KEY)
        Hash(String, Array(String)).from_json(json)
      else
        {} of String => Array(String)
      end
    end

    # Clear errors from session
    # Called automatically after the request to prevent errors from persisting
    def clear_errors_from_flash
      session.delete(FLASH_ERRORS_KEY)
    end
  end
end
