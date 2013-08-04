module Schemas
	@schemas ||= {}
	@schemas[:posts_POST] = {
		"$schema" => "http://json-schema.org/draft-03/schema#",
		"type" => "object",
	 	"additionalProperties" => false,
	 	"required" => true,
		"properties" => {
			"text" => {
				"type" => "string"
			},
			"image_url" => {
				"type" => "string",
				"required" => true
			},
			"tags" => {
				"type" => "array",
				"items" => {
					"type" => "string"
				}
			}
		}
	}
	def self.schemas
		@schemas
	end
end