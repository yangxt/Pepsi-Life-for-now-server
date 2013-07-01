module Schemas
	@schemas ||= {}
	@schemas[:friends_POST] = {
		"$schema" => "http://json-schema.org/draft-03/schema#",
		"type" => "object",
	 	"additionalProperties" => false,
	 	"required" => true,
		"properties" => {
			"friend" => {
				"type" => "number",
				"required" => true
			}
		}
	}
	def self.schemas
		@schemas
	end
end