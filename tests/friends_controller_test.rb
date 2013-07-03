require './controllers/friends_controller'
require 'test/unit'
require 'rack/test'

ENV['RACK_ENV'] = 'test'

class FriendsControllerTest < Test::Unit::TestCase
	include Rack::Test::Methods

	def app
		Sinatra::Application
	end
end