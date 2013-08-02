require './tests/common'
require './controllers/friends_controller'

class FriendsControllerTest < Test::Unit::TestCase
	include Rack::Test::Methods

	def app
		Sinatra::Application
	end

	def setup
		TestTools.delete_all
	end

	def teardown
	end

 	def test_post_friend
		me = TestTools.create_user_with("my_username", "my_password", "my_name", "my_image_url", "my_description")
		other_user = TestTools.create_user

		body = {
			:friend => other_user.id
		}

		request = TestTools.request
		TestTools.authenticate(request, me)
		response = TestTools.post(request, "/me/friends/", body)
		json = JSON.parse(response.body);
		assert_equal(json["status"], 200, "status code doesn't match")

		json = json["body"]

		friendships = Friendship.find(:all)
		assert_equal(friendships.length, 1, "number of friendships doesn't match")
		assert_equal(friendships[0].user1_id, me.id)
		assert_equal(friendships[0].user2_id, other_user.id)
	end

	def test_delete_friend
		me = TestTools.create_user_with("my_username", "my_password", "my_name", "my_image_url", "my_description")
		friend = TestTools.create_user
		other_user = TestTools.create_user
		TestTools.create_friendship(me, friend)
		TestTools.create_friendship(other_user, friend)

		request = TestTools.request
		TestTools.authenticate(request, me)
		response = TestTools.delete(request, "/me/friends/#{friend.id}")
		json = JSON.parse(response.body);
		assert_equal(json["status"], 200, "status code doesn't match")
		assert_equal(Friendship.find(:all).count, 1, "friendship was not delete")
	end

	def test_post_me_as_friend
		me = TestTools.create_user_with("my_username", "my_password", "my_name", "my_image_url", "my_description")

		body = {
			:friend => me.id
		}

		request = TestTools.request
		TestTools.authenticate(request, me)
		response = TestTools.post(request, "/me/friends/", body)
		json = JSON.parse(response.body);
		assert_equal(json["status"], 400, "status code doesn't match")
	end

	def test_post_unexisting_user_as_friend
		me = TestTools.create_user_with("my_username", "my_password", "my_name", "my_image_url", "my_description")

		body = {
			:friend => me.id + 1
		}

		request = TestTools.request
		TestTools.authenticate(request, me)
		response = TestTools.post(request, "/me/friends/", body)
		json = JSON.parse(response.body);
		assert_equal(json["status"], 404, "status code doesn't match")
	end

	def test_get_friends
		me = TestTools.create_user_with("my_username", "my_password", "my_name", "my_image_url", "my_description")
		friends = TestTools.create_x_users(11)
		other_users = TestTools.create_x_users(5)

		friends_objects = []

		friends.each_with_index do |f, i|
			if i < 7
				TestTools.create_friendship(me, f)
			else
				TestTools.create_friendship(f, me)
			end
			if i < 9
				TestTools.create_coordinate_with_user(f, Random.rand(1..100), Random.rand(1..100))
			end
			if i < 3
				post = TestTools.create_post_with_user(f)
				TestTools.create_like_on_post_with_user(post, f)
				TestTools.create_seen_on_post_with_user(post, f)
			end
			friend_object = {
				"id" => f.id,
				"name" => f.name,
				"image_url" => f.image_url,
				"description" => f.description,
				"posts_count" => f.posts.count,
				"seens_count" => f.seens.count,
				"likes_count" => f.likes.count
			}
			if f.coordinate
				friend_object["coordinate"] = {
					"latitude" => f.coordinate.latitude,
					"longitude" => f.coordinate.longitude
				}
			else
				friend_object["coordinate"] = "null"
			end
			friends_objects << friend_object
		end


		request = TestTools.request
		TestTools.authenticate(request, me)
		response = TestTools.get(request, "/me/friends/")
		json = JSON.parse(response.body);
		assert_equal(json["status"], 200, "status code doesn't match")

		json = json["body"]
		retrieved_friends = json["friends"]

		assert_equal(retrieved_friends.length, friends.length)

		retrieved_friends.each do |rf|
			assert(friends_objects.include?(rf), "#{rf} is not a friend")
		end
	end

	def test_get_friends_with_bounds
		me = TestTools.create_user_with("my_username", "my_password", "my_name", "my_image_url", "my_description")
		friends = TestTools.create_x_users(13)
		other_users = TestTools.create_x_users(5)

		latitude_bounds = {
			:max => 23,
			:min => 12
		}
		longitude_bounds = {
			:max => 65,
			:min => 24
		}

		friends_objects_in_bounds = []
		friends.each_with_index do |f, i|
			TestTools.create_friendship(me, f)
			if i < 5
				latitude = Random.rand(latitude_bounds[:min]..latitude_bounds[:max])
				longitude = Random.rand(longitude_bounds[:min]..longitude_bounds[:max])
				TestTools.create_coordinate_with_user(f, latitude, longitude)
				friends_objects_in_bounds << {
					"id" => f.id,
					"name" => f.name,
					"image_url" => f.image_url,
					"coordinate" => {
						"latitude" => f.coordinate.latitude,
						"longitude" => f.coordinate.longitude
					},
					"description" => f.description,
					"posts_count" => f.posts.count,
					"seens_count" => f.seens.count,
					"likes_count" => f.likes.count
			}
			else
				latitude = Random.rand(0..latitude_bounds[:min])
				longitude = Random.rand(longitude_bounds[:max]..100)
				TestTools.create_coordinate_with_user(f, latitude, longitude)
			end
		end

		other_users.each_with_index do |u, i|
			if i < 3
				latitude = Random.rand(latitude_bounds[:min]..latitude_bounds[:max])
				longitude = Random.rand(longitude_bounds[:min]..longitude_bounds[:max])
			else
				latitude = Random.rand(0.0..latitude_bounds[:min])
				longitude = Random.rand(longitude_bounds[:max]..100.0)
			end
			TestTools.create_coordinate_with_user(u, latitude, longitude)
		end

		request = TestTools.request
		TestTools.authenticate(request, me)
		response = TestTools.get(request, "/me/friends/?from_lat=#{latitude_bounds[:min]}&to_lat=#{latitude_bounds[:max]}&from_long=#{longitude_bounds[:min]}&to_long=#{longitude_bounds[:max]}")
		json = JSON.parse(response.body);
		assert_equal(json["status"], 200, "status code doesn't match")

		json = json["body"]
		retrieved_friends = json["friends"]
		assert_equal(friends_objects_in_bounds.length, retrieved_friends.length, "number of friends retrieved doesn't match")
		retrieved_friends.each do |rf|
			assert(friends_objects_in_bounds.include?(rf), "#{rf} is not a friend")
		end
	end
end