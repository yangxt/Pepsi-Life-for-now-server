module Schemas
	@schemas ||= {}
	@schemas[:comments_POST] = {
		"$schema" => "http://json-schema.org/draft-03/schema#",
		"type" => "object",
	 	"additionalProperties" => false,
	 	"required" => true,
		"properties" => {
			"text" => {
				"type" => "string",
				"required" => true
			}
		}
	}
	def self.schemas
		@schemas
	end
end