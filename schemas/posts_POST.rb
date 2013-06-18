require './schemas/module.rb'

module Schemas
	@schemas ||= {}
	@schemas[:posts_POST] = {
		"$schema" => "http://json-schema.org/draft-03/schema#",
		"type" => "object",
	 	"additionalProperties" => false,
		"properties" => {
			"text" => {
				"type" => "string",
				"required" => true
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
end