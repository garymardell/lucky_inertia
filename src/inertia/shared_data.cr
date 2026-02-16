module Inertia
  module SharedData
    # DSL macro for defining shared data
    # Usage:
    #   inertia_share(
    #     auth: -> { current_user.try(&.to_json) },
    #     flash: -> { flash.to_h }
    #   )
    macro inertia_share(**props)
      {% for key, value in props %}
        {% if value.is_a?(ProcLiteral) %}
          # Define an instance method that will be called to get the value
          private def __inertia_shared_{{key.id}}
            ({{value}}).call
          end
        {% end %}
      {% end %}
      
      # Override collect_shared_data to include these props
      def collect_shared_data : Hash(String, JSON::Any)
        data = previous_def
        
        {% for key, value in props %}
          {% if value.is_a?(ProcLiteral) %}
            # Call the instance method we defined above
            data[{{key.stringify}}] = JSON.parse(__inertia_shared_{{key.id}}.to_json)
          {% else %}
            # Static value
            data[{{key.stringify}}] = JSON.parse({{value}}.to_json)
          {% end %}
        {% end %}
        
        data
      end
    end

    # Collect shared data from the class hierarchy
    # Child classes inherit shared data from parents
    def collect_shared_data : Hash(String, JSON::Any)
      Hash(String, JSON::Any).new
    end
  end
end

# Include SharedData in all Lucky actions
class Lucky::Action
  include Inertia::SharedData
end
