require 'sinatra'
require 'json-schema'

module Tools
	def self.validate_against_schema(schema, json)
		return false, "No JSON provided" if (!json || json == "")
		begin
  			JSON::Validator.validate!(schema, json)
  			[true]
		rescue JSON::Schema::ValidationError
  			return false, $!.message
		end
	end
end