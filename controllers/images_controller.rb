 # -*- coding: utf-8 -*-
require 'sinatra'
require 'sinatra/activerecord'
require './helpers/constants'
require './helpers/s3'
require "base64"

post %r{^/images/?$} do
	keyProtected!
	content_type :json
	
	base64 = request.body.read
	haltJsonp 400, "No content provided" unless base64

	base64.sub!(/data:image\/(png|jpeg);base64,/, "")
	data = Base64.decode64(base64)

	s3 = S3.instance
	bucket = s3.bucket("pepsiapp")
	timestamp = Time.now.to_f.to_s
	object = bucket.objects[timestamp]
	object.write(data, {:acl => :public_read, :cache_control => "public"})
	url = s3.url("pepsiapp") + timestamp
	jsonp({:status => 200, :body => {:image_url => url}})
end