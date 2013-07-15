 # -*- coding: utf-8 -*-
require 'rubygems'
require 'sinatra'
require 'sinatra/reloader' if development?
require 'sinatra/activerecord'
require 'sinatra/jsonp'
require './config/environments' #database configuration
require 'json'
require './helpers/authentication'
require './helpers/constants'
require './helpers/haltJsonp'
require './controllers/users_controller'
require './controllers/posts_controller'
require './controllers/friends_controller'
require './controllers/images_controller'

API_KEY = "nd6YyykHsCygZZi64F"

Dir.mkdir(Constants::DATA_PATH) unless File.exists?(Constants::DATA_PATH)
Dir.mkdir(Constants::IMAGES_PATH) unless File.exists?(Constants::IMAGES_PATH)

helpers do
	include Sinatra::Authentication
	include Sinatra::HaltJsonp
end

configure do
	mime_type :json, "application/json"
	mime_type :png, "image/png"
	ActiveRecord::Base.default_timezone = :utc
end

before do
	if ENV['RACK_ENV'] != 'test'
		query_string = env["QUERY_STRING"]
		method = query_string.scan(/&?method=(\w+)&?/).flatten
		if method.length != 0
			env["QUERY_STRING"] = query_string
			env["REQUEST_METHOD"] = method[0]
		else
			haltJsonp(400, "Invalid request. Add method to url")
	  	end
  	end
end

before do
	unless request.path =~ (%r{^/users/?}) &&
		request.request_method == "POST"
		@user = authenticate
	end
	if !(api_key = params[:api_key]) || 
		api_key != API_KEY
		halt 403, "You must add a valid API key to every request"
	end
	if (request.content_type == "application/json" &&
		(body = request.body.read) != "")
		begin
			json = JSON.parse(body)
			@json = json;
		rescue JSON::ParserError => e
			halt 400, "Invalid JSON: \n" + e.message
		end
	end
	content_type :json
end

get %r{^/friends/?$} do
	puts "innnnnnn"
	status, headers, body = call env.merge("PATH_INFO" => '/posts/', "REQUEST_METHOD" => "POST")
 	[status, headers, body.map(&:upcase)]
end

not_found do
	"Non-existing resource"
end
