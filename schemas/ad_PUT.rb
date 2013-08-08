module Schemas
	@schemas ||= {}
	@schemas[:ad_PUT] = {
		"$schema" => "http://json-schema.org/draft-03/schema#",
		"type" => "object",
	 	"additionalProperties" => false,
	 	"required" => true,
		"properties" => {
			"image_url" => {
				"type" => "string",
				"required" => true
			},
			"duration" => {
				"type" => "number",
				"required" => true
			}
		}
	}
	def self.schemas
		@schemas
	end
end