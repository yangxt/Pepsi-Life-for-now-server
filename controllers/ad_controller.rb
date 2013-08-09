 # -*- coding: utf-8 -*-

require './schemas/ad_PUT'
require './helpers/haltJsonp'
require './models/ad'

put %r{^/ad/?$} do
	protected!
	content_type :json
	schema = Schemas.schemas[:ad_PUT]
	is_valid = Tools.validate_against_schema(schema, @json)
 	haltJsonp(400, is_valid[1]) unless is_valid[0]

 	ad = Ad.first
 	ad = Ad.create unless ad
 	ad.image_url = @json["image_url"]
 	ad.duration = @json["duration"]
 	haltJsonp(500, "Couldn't create the ad\n" + e.message) unless ad.save
 	jsonp({:status => 200, :body => {}})
end

get %r{^/ad/?$} do
	keyProtected!
	content_type :json
	ad = Ad.first
	haltJsonp(404, "Non-existing resource") unless ad
	result = {
		:image_url => ad.image_url,
		:duration => ad.duration
	}
	jsonp({:status => 200, :body => result})
end