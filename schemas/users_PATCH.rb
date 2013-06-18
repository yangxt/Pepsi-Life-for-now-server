module Schemas
	@schemas ||= {}
	@schemas[:users_PATCH] = {
		"$schema" => "http://json-schema.org/draft-03/schema#",
		"type" => "object",
	 	"additionalProperties" => false,
	 	"required" => true,
		"properties" => {
			"name" => {
				"type" => "string"
			},
			"image_url" => {
				"type" => "string"
			}
		}
	}
	def self.schemas
		@schemas
	end
end