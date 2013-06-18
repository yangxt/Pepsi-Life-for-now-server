module Schemas
	@schemas ||= {}
	@schemas[:users_geolocation_POST] = {
		"$schema" => "http://json-schema.org/draft-03/schema#",
		"type" => "object",
		"additionalProperties" => false,
		"required" => true,
		"properties" => {
			"coordinates" => {
				"type" => "object",
				"additionalProperties" => false,
				"properties" => {
					"lat" => {
						"type" => "number",
						"required" => true
					},
					"long" => {
						"type" => "number",
						"required" => true
					}
				}
			}
		}
	}

	def self.schemas
		@schemas
	end
end