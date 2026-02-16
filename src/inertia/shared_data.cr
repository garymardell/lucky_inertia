module Inertia
  module SharedData
    macro included
      # Storage for shared data blocks at the class level
      class_property _shared_data_blocks : Array(Proc(HTTP::Server::Context, Lucky::Action, Hash(String, JSON::Any))) = [] of Proc(HTTP::Server::Context, Lucky::Action, Hash(String, JSON::Any))
    end

    # DSL macro for defining shared data
    # Usage:
    #   inertia_share(
    #     auth: -> { current_user.try(&.to_json) },
    #     flash: -> { flash.to_h }
    #   )
    macro inertia_share(**props)
      {% for key, value in props %}
        {% if value.is_a?(ProcLiteral) %}
          # Proc literal - needs to be wrapped to capture instance context
          %proc = {{value}}
          self._shared_data_blocks << ->(ctx : HTTP::Server::Context, action : Lucky::Action) {
            result = Hash(String, JSON::Any).new
            # Call the proc in the context of the action instance
            value = action.instance_eval(&%proc)
            result[{{key.stringify}}] = JSON.parse(value.to_json)
            result
          }
        {% else %}
          # Static value
          self._shared_data_blocks << ->(ctx : HTTP::Server::Context, action : Lucky::Action) {
            result = Hash(String, JSON::Any).new
            result[{{key.stringify}}] = JSON.parse({{value}}.to_json)
            result
          }
        {% end %}
      {% end %}
    end

    # Collect shared data from the class hierarchy
    # Child classes inherit shared data from parents
    def collect_shared_data : Hash(String, JSON::Any)
      data = Hash(String, JSON::Any).new
      
      # Walk up the class hierarchy to collect all shared data
      current_class = self.class
      while current_class.responds_to?(:_shared_data_blocks)
        current_class._shared_data_blocks.each do |block|
          block.call(context, self).each do |key, value|
            # Child class values take precedence (don't overwrite)
            data[key] = value unless data.has_key?(key)
          end
        end
        break if current_class == Lucky::Action
        current_class = current_class.superclass
      end
      
      data
    end
  end
end

# Include SharedData in all Lucky actions
class Lucky::Action
  include Inertia::SharedData
end
