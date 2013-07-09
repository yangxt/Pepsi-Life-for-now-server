require './tests/common'
require './controllers/users_controller'

class UsersControllerTest < Test::Unit::TestCase
	include Rack::Test::Methods

	def app
		Sinatra::Application
	end

	def setup
		TestTools.delete_all
	end

	def teardown
	end

	def test_post_user
		request = TestTools.request
		response = TestTools.post(request, "/users/", nil)
		json = JSON.parse(response.body)
		assert_equal(response.status, 200, "status code doesn't match")
		assert_not_nil(json["username"], "username doesn't match")
		assert_not_nil(json["password"], "password doesn't match")

		saved_users = ApplicationUser.all
		assert_equal(saved_users.length, 1, "number of users added doesn't match")
		saved_user = saved_users[0]
		assert_equal(saved_user.username, json["username"], "username doesn't match")
		assert_equal(saved_user.password, json["password"], "passwor doesn't match")
		assert_nil(saved_user.image_url, "image_url not nil")
		assert_nil(saved_user.name, "name not nil")
		assert_nil(saved_user.description, "description not nil")
	end

	def test_put_me_geolocation
		user = TestTools.create_user
		request = TestTools.request
		TestTools.authenticate(request, user)
		body = {
			"coordinates" => {
				"lat" => 43.344,
				"long" => 56.25 
			}
		}
		response = TestTools.put(request, '/me/geolocation/', body)
		assert_equal(response.status, 200, "status code doesn't match")

		coordinate = Coordinate.first
		assert_equal(coordinate.application_user_id, user.id, "user doesn't match")
		assert_equal(coordinate.latitude, body["coordinates"]["lat"], "latitude doesn't match")
		assert_equal(coordinate.longitude, body["coordinates"]["long"], "longitude doesn't match")
	end

	def test_patch_me
		user = TestTools.create_user
		request = TestTools.request
		TestTools.authenticate(request, user)
		body = {
			"name" => "new_name",
			"image_url" => "new_image_url"
		}
		response = TestTools.patch(request, '/me/', body)
		assert_equal(response.status, 200, "status code doesn't match")

		saved_user = ApplicationUser.first
		assert_equal(saved_user, user, "user doesn't match")
		assert_equal(saved_user.name, body["name"], "name doesn't match")
		assert_equal(saved_user.image_url, body["image_url"], "image_url doesn't match")
	end

	def test_patch_me_only_name
		user = TestTools.create_user
		request = TestTools.request
		TestTools.authenticate(request, user)
		body = {
			"name" => "new_name"
		}
		response = TestTools.patch(request, '/me/', body)
		assert_equal(response.status, 200)

		saved_user = ApplicationUser.first
		assert_equal(saved_user, user, "user doesn't match")
		assert_equal(saved_user.name, body["name"], "name doesn't match")
		assert_equal(saved_user.image_url, "image_url0", "image_url doesn't match")
	end

	def test_patch_me_only_image_url
		user = TestTools.create_user
		request = TestTools.request
		TestTools.authenticate(request, user)
		body = {
			"image_url" => "new_image_url"
		}
		response = TestTools.patch(request, '/me/', body)
		assert_equal(response.status, 200, "status code doesn't match")

		saved_user = ApplicationUser.first
		assert_equal(saved_user, user, "user doesn't match")
		assert_equal(saved_user.name, "name0", "name doesn't match")
		assert_equal(saved_user.image_url, body["image_url"], "image_url doesn't match")
	end

	def test_get_me
		users = TestTools.create_x_users(10)
		posts = []
		for i in 0...users.length
			post = TestTools.create_post_with("text#{i}", "image_url#{i}", DateTime.now, users[i])
			posts << post
			TestTools.create_like_on_post_with_user(post, users[i])
			if i < 7
				TestTools.create_seen_on_post_with_user(post, users[i])
			end
		end

		me = TestTools.create_user_with("my_username", "my_password", "my_name", "my_image_url", "my_description")

		for i in 0...posts.length
			if i == 1 || i == 3
				TestTools.create_like_on_post_with_user(post, me)
			else
				TestTools.create_seen_on_post_with_user(post, me)
			end

		end

		request = TestTools.request
		TestTools.authenticate(request, me)

		response = TestTools.get(request, '/me/')
		assert_equal(response.status, 200, "status code doesn't match")

		json = JSON.parse(response.body)
		assert_equal(json["id"], me.id, "id doesn't match")
		assert_equal(json["username"], me.username, "username doesn't match")
		assert_equal(json["name"], me.name, "name doesn't match")
		assert_equal(json["seens_count"], 8, "seens_count doesn't match")
		assert_equal(json["likes_count"], 2, "likes_count doesn't match")
	end

	def test_get_users
		me = TestTools.create_user_with("my_username", "my_password", "my_name", "my_image_url", "my_description")
		users = TestTools.create_x_users(Constants::USERS_PER_PAGE + 7)
		posts = []
		users.each_index do |i|
			if i > 3
				TestTools.create_coordinate_with_user(users[i], i + 0.1, i + 1.1)
			end
			if i < Constants::USERS_PER_PAGE + 3
				TestTools.create_friendship(me, users[i])
			end
			if i < Constants::USERS_PER_PAGE+ 15
				post = TestTools.create_post_with("text#{i}", "image_url#{i}", DateTime.now, users[i])
				posts << post
				TestTools.create_like_on_post_with_user(post, users[i])
				TestTools.create_like_on_post_with_user(posts[i-1], users[i])
				TestTools.create_seen_on_post_with_user(post, users[i])
				TestTools.create_seen_on_post_with_user(posts[i-1], users[i])
			end
		end
		users.reverse!

		request = TestTools.request
		TestTools.authenticate(request, me)
		response = TestTools.get(request, "/users/?last_id=#{users[Constants::USERS_PER_PAGE - 1].id}")
		assert_equal(response.status, 200, "status code doesn't match")

		json = JSON.parse(response.body)
		retrieved_users = json["users"]
		assert_equal(retrieved_users.length, 7, "number of retrieved_users doesn't match")

		retrieved_users.each_with_index do |ru, i|
			real_user = users[i + Constants::USERS_PER_PAGE]
			assert_equal(ru["id"], real_user.id, "id doesn't match")
			assert_equal(ru["name"], real_user.name, "name doesn't match")
			assert_equal(ru["image_url"], real_user.image_url, "image_url doesn't match")

			if ru["coordinate"] == "null"
				assert_nil(real_user.coordinate)
			else
				assert_equal(ru["coordinate"]["latitude"], real_user.coordinate.latitude, "latitude doesn't match")
				assert_equal(ru["coordinate"]["longitude"], real_user.coordinate.longitude, "longitude doesn't match")
			end
			is_friend = false
			is_friend = true if Friendship.where(:user1_id => me.id, :user2_id => real_user.id).length >= 1
			assert_equal(ru["friend"], is_friend, "friend doesn't match")
			assert_equal(ru["seens_count"], real_user.seens.count, "seens_count doesn't match")
			assert_equal(ru["likes_count"], real_user.likes.count, "likes_count doesn't match")
		end
	end

	def test_get_user_with_bounds
		me = TestTools.create_user_with("my_username", "my_password", "my_name", "my_image_url", "my_description")
		users = TestTools.create_x_users(9)
		latitude_bounds = {
			:max => 23.2,
			:min => 12.4
		}
		longitude_bounds = {
			:max => 65.2,
			:min => 24.2
		}
		users_in_bounds = []
		users.each_index do |i|
			if i < 5
				latitude = Random.rand(latitude_bounds[:min]..latitude_bounds[:max])
				longitude = Random.rand(longitude_bounds[:min]..longitude_bounds[:max])
				users_in_bounds << users[i]
			else
				latitude = Random.rand(0.0..latitude_bounds[:min])
				longitude = Random.rand(longitude_bounds[:max]..100.0)
			end
			TestTools.create_coordinate_with_user(users[i], latitude, longitude)
		end
		users_in_bounds.reverse!

		request = TestTools.request
		TestTools.authenticate(request, me)
		response = TestTools.get(request, "/users/?from_lat=#{latitude_bounds[:min]}&to_lat=#{latitude_bounds[:max]}&from_long=#{longitude_bounds[:min]}&to_long=#{longitude_bounds[:max]}")
		assert_equal(response.status, 200, "status code doesn't match")

		json = JSON.parse(response.body)
		retrieved_users = json["users"]
		assert_equal(users_in_bounds.length, retrieved_users.length, "not the same number of users retrieved")
		retrieved_users.each_index do |i|
			retrieved_user = retrieved_users[i]
			real_user = users_in_bounds[i]
			assert_equal(retrieved_user["id"], real_user.id)
		end
	end
end
