 # -*- coding: utf-8 -*-
require 'sinatra'
require 'sinatra/activerecord'
require './helpers/constants'
require './helpers/s3'
require "base64"

post %r{^/images/?$} do
	base64 = request.body.read
	haltJsonp 400, "No content provided" unless base64

	data = Base64.decode64(base64['data:image/png;base64,'.length .. -1])

	s3 = S3.instance
	bucket = s3.bucket("pepsi-app")
	timestamp = Time.now.to_f.to_s
	object = bucket.objects[timestamp]
	object.write(data, {:acl => :public_read, :cache_control => "public"})
	url = s3.url("pepsi-app") + timestamp
	jsonp({:status => 200, :body => {:image_url => url}})
end