require './app'
require './controllers/posts_controller'
require 'test/unit'
require 'rack/test'
require 'json'
require './models/application_user'
require './models/post'
require './tests/test_tools'

ENV['RACK_ENV'] = 'test'
require './config/environments.rb'


class PostsControllerTest < Test::Unit::TestCase
	include Rack::Test::Methods

	def app
		Sinatra::Application
	end

	def setup
		ApplicationUser.delete_all
		Post.delete_all
	end

	def teardown
	end

	def test_post_post
		user = TestTools.create_user
		request = TestTools.request
		TestTools.authenticate(request, user)
		body = {
			"text" => "text1",
			"image_url" => "url1",
			"tags" => [
				"tag1",
				"tag2"
			]
		}
		response = TestTools.post(request, '/posts/', body)
	end

	def test_get_posts
	end

	def test_post_like
	end

	def test_post_seen
	end

	def test_post_comment
	end

	def test_get_comments
	end


end