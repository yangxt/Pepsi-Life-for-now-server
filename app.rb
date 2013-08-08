 # -*- coding: utf-8 -*-
require 'rubygems'
require 'sinatra'
require 'sinatra/reloader' if development?
require 'sinatra/activerecord'
require 'sinatra/jsonp'
require 'sinatra/cross_origin'
require './config/environments' #database configuration
require 'json'
require './helpers/authentication'
require './helpers/adminAuthentication'
require './helpers/keyProtection'
require './helpers/constants'
require './helpers/haltJsonp'
require './controllers/users_controller'
require './controllers/posts_controller'
require './controllers/friends_controller'
require './controllers/images_controller'

set :protection, :except => [:http_origin]

if Rack::Utils.respond_to?("key_space_limit=")
  	Rack::Utils.key_space_limit = 400000 
end

helpers do
	include Sinatra::Authentication
	include Sinatra::HaltJsonp
  	include Sinatra::AdminAuthentication
  	include Sinatra::KeyProtection
end

configure do
	enable :cross_origin
	mime_type :json, "application/json"
	mime_type :png, "image/png"
	mime_type :html, "text/html"
	ActiveRecord::Base.default_timezone = :utc
end

before do
	if ENV['RACK_ENV'] != 'test'
		query_string = env["QUERY_STRING"]
		method = query_string.scan(/&?method=(\w+)&?/).flatten
		if method.length != 0
			env["QUERY_STRING"] = query_string
			env["REQUEST_METHOD"] = method[0]
		end
  	end

  	if (request.content_type == "application/json" &&
		(body = request.body.read) != "")
		begin
			json = JSON.parse(body)
			@json = json;
		rescue JSON::ParserError => e
			haltJsonp 400, "Invalid JSON: \n" + e.message
		end
	end
end

not_found do
	jsonp({:status => 404, :message => "Non-existing resource"})
end

get %r{^/admin/?} do
	protected!
	content_type :html
	file = File.new("admin.html", "r")
	data = ""
	while (line = file.gets)
    	data += line
	end
	file.close
	data
end
