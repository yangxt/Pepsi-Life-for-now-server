require 'rubygems'
require 'sinatra'
require "sinatra/reloader" if development?
require 'sinatra/activerecord'
require './config/environments' #database configuration
require 'json'
require './helpers/authentication'
require './controllers/users_controller'
require './controllers/posts_controller'
require './controllers/friends_controller'

API_KEY = "nd6YyykHsCygZZi64F"

helpers do
	include Sinatra::Authentication
end

configure do
	mime_type :json, "application/json"
	ActiveRecord::Base.default_timezone = :utc
end

before do
	if !(api_key = params[:api_key]) || 
		api_key != API_KEY
		halt 403, "You must add a valid API key to every request"
	end
	if (body = request.body.read) != ""
		begin
			json = JSON.parse(body)
			@json = json;
		rescue JSON::ParserError => e
			halt 400, "Invalid JSON: \n" + e.message
		end
	end
	content_type :json
end

before %r{^(?!/users/?$).*} do
	@user = authenticate
end

not_found do
	"Non-existing resource"
end
