require './tests/common'
require './controllers/posts_controller'

class PostsControllerTest < Test::Unit::TestCase
	include Rack::Test::Methods

	def app
		Sinatra::Application
	end

	def setup
		TestTools.delete_all
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

			]
		}
		response = TestTools.post(request, '/posts/', body)
		assert_equal(response.status, 200, "status code doesn't match")

		saved_posts = Post.all
		assert_equal(saved_posts.length, 1, "number of posts added doesn't match")

		saved_post = saved_posts[0]
		assert_equal(saved_post.text, body["text"], "text doesn't match")
		assert_equal(saved_post.image_url, body["image_url"], "image_url doesn't match")

		saved_tags = saved_post.tags
		tags = body["tags"]
		assert_equal(saved_tags.length, tags.length, "number of tags added doesn't match")
		tags.each_index do |i|
			assert_equal(tags[i], saved_tags[i].text)
			assert_equal(saved_tags[i].post, saved_post)
		end
	end

	def test_get_posts
		me = TestTools.create_user_with("my_username", "my_password", "my_name", "my_image_url", "my_description")
		users = TestTools.create_x_users(Constants::POSTS_PER_PAGE + 5)
		posts = []
		users.each_with_index do |u, i|
			post = TestTools.create_post_with("text1", "image_url1", DateTime.now - i.days, u)
			if i < Constants::POSTS_PER_PAGE + 3
				TestTools.create_x_tags_with_post(post, 2)
				TestTools.create_like_on_post_with_user(post, u)
				TestTools.create_seen_on_post_with_user(post, u)
				TestTools.create_like_on_post_with_user(post, me)
			end
			posts << post
		end

		TestTools.create_x_posts_with_user(me, 3)

		request = TestTools.request
		TestTools.authenticate(request, me)
		response = TestTools.get(request, "/posts/?page=2")
		assert_equal(response.status, 200, "status code doesn't match")

		json = JSON.parse(response.body)
		assert_equal(json["pages_count"], 2, "pages_count doesn't match")
		assert_equal(json["page"], 2, "page doesn't match")
		retrieved_posts = json["posts"]
		assert_equal(retrieved_posts.length, 5, "number of posts doesn't match")

		retrieved_posts.each_index do |i|
			retrieved_post = retrieved_posts[i]		
			real_post = posts[Constants::POSTS_PER_PAGE + i]
			assert_equal(retrieved_post["id"], real_post.id, "id doesn't match")
			assert_equal(retrieved_post["text"], real_post.text, "text doesn't match")
			assert_equal(retrieved_post["image_url"], real_post.image_url, "image_url doesn't match")
			assert_equal(DateTime.parse(retrieved_post["creation_date"].to_s), real_post.creation_date.to_s, "creation_date doesn't match")
			assert_equal(retrieved_post["likes_count"], real_post.likes.count, "likes_count doesn't match")
			assert_equal(retrieved_post["seens_count"], real_post.seens.count, "seens_count doesn't match")
			assert_equal(retrieved_post["owner"]["name"], real_post.application_user.name, "post's owner's name doesn't match")
			assert_equal(retrieved_post["owner"]["image_url"], real_post.application_user.image_url, "post's owner's image_url doesn't match")

			retrieved_tags = retrieved_post["tags"]
			if retrieved_tags
				real_tags = []
				real_post.tags.each do |t|
					real_tags << t.text
				end
				retrieved_tags.each do |t|
					assert(real_tags.include?(t))
				end
			end
		end
	end

	def test_get_posts_only_friend
		me = TestTools.create_user_with("my_username", "my_password", "my_name", "my_image_url", "my_description")
		users = TestTools.create_x_users(5)
		names_of_friends = []
		users.each_index do |i|
			posts = TestTools.create_x_posts_with_user(users[i], 2)
			if i < 3
				TestTools.create_friendship(users[i], me)
				names_of_friends << users[i].name
			end
		end

		request = TestTools.request
		TestTools.authenticate(request, me)
		response = TestTools.get(request, "/posts/?only_friends=true")
		assert_equal(response.status, 200, "status code doesn't match")

		json = JSON.parse(response.body)
		retrieved_posts = json["posts"]
		assert_equal(retrieved_posts.length, 6, "number of posts doesn't match")
		retrieved_posts.each do |p|
			assert(names_of_friends.include?(p["owner"]["name"]))
		end
	end

	def test_get_posts_only_tag
		me = TestTools.create_user_with("my_username", "my_password", "my_name", "my_image_url", "my_description")
		user = TestTools.create_user
		posts_ids_with_tag = []
		for i in 0...10
			post = TestTools.create_post_with_user(user)
			if i < 5
				TestTools.create_tag_with(post, "tag1")
			else
				TestTools.create_tag_with(post, "tag2")
				posts_ids_with_tag << post.id
			end
		end
		
		request = TestTools.request
		TestTools.authenticate(request, me)
		response = TestTools.get(request, "/posts/?tag=tag2")
		assert_equal(response.status, 200, "status code doesn't match")

		json = JSON.parse(response.body)
		retrieved_posts = json["posts"]
		assert_equal(retrieved_posts.length, 5, "number of posts doesn't match")
		retrieved_posts.each do |p|
			assert(posts_ids_with_tag.include?(p["id"]))
		end
	end

	def test_post_like
		me = TestTools.create_user_with("my_username", "my_password", "my_name", "my_image_url", "my_description")
		user = TestTools.create_user
		post = TestTools.create_post_with_user(user)

		request = TestTools.request
		TestTools.authenticate(request, me)
		response = TestTools.post(request, "/posts/#{post.id}/likes/", nil)
		assert_equal(response.status, 200, "status code doesn't match")

		assert_equal(post.likes.count, 1)
		assert_equal(post.likes[0].application_user, me)

		request = TestTools.request
		TestTools.authenticate(request, user)
		response = TestTools.post(request, "/posts/#{post.id}/likes/", nil)
		assert_equal(response.status, 200, "status code doesn't match")

		assert_equal(post.likes.count, 2)
	end

	def test_post_like_multiple_times
		me = TestTools.create_user_with("my_username", "my_password", "my_name", "my_image_url", "my_description")
		user = TestTools.create_user
		post = TestTools.create_post_with_user(user)

		for i in 0...2
			request = TestTools.request
			TestTools.authenticate(request, me)
			response = TestTools.post(request, "/posts/#{post.id}/likes/", nil)
			assert_equal(response.status, 200, "status code doesn't match")

			assert_equal(post.likes.count, 1)
			assert_equal(post.likes[0].application_user, me)
		end
	end

	def test_post_like_non_existing_post
		me = TestTools.create_user
		request = TestTools.request
		TestTools.authenticate(request, me)
		response = TestTools.post(request, "/posts/5/likes/", nil)
		assert_equal(response.status, 404, "status code doesn't match")
	end

	def test_post_seen
		me = TestTools.create_user_with("my_username", "my_password", "my_name", "my_image_url", "my_description")
		user = TestTools.create_user
		post = TestTools.create_post_with_user(user)

		request = TestTools.request
		TestTools.authenticate(request, me)
		response = TestTools.post(request, "/posts/#{post.id}/seens/", nil)
		assert_equal(response.status, 200, "status code doesn't match")

		assert_equal(post.seens.count, 1)
		assert_equal(post.seens[0].application_user, me)

		request = TestTools.request
		TestTools.authenticate(request, user)
		response = TestTools.post(request, "/posts/#{post.id}/seens/", nil)
		assert_equal(response.status, 200, "status code doesn't match")

		assert_equal(post.seens.count, 2)
	end

	def test_post_seen_multiple_times
		me = TestTools.create_user_with("my_username", "my_password", "my_name", "my_image_url", "my_description")
		user = TestTools.create_user
		post = TestTools.create_post_with_user(user)

		for i in 0...2
			request = TestTools.request
			TestTools.authenticate(request, me)
			response = TestTools.post(request, "/posts/#{post.id}/seens/", nil)
			assert_equal(response.status, 200, "status code doesn't match")

			assert_equal(post.seens.count, 1)
			assert_equal(post.seens[0].application_user, me)
		end
	end

	def test_post_seen_non_existing_post
		me = TestTools.create_user
		request = TestTools.request
		TestTools.authenticate(request, me)
		response = TestTools.post(request, "/posts/5/seens/", nil)
		assert_equal(response.status, 404, "status code doesn't match")
	end

	def test_post_comment
		me = TestTools.create_user
		post = TestTools.create_post_with_user(me)

		request = TestTools.request
		TestTools.authenticate(request, me)

		body = {
			:text => "text0"
		}
		response = TestTools.post(request, "/posts/#{post.id}/comments/", body)
		assert_equal(response.status, 200, "status code doesn't match")
		comments = Comment.all
		assert_equal(comments.length, 1, "number of comments doesn't match")
		assert_equal(comments[0].text, body[:text], "text doesn't match")
	end

	def test_post_comment_non_exising_post
		me = TestTools.create_user

		request = TestTools.request
		TestTools.authenticate(request, me)

		response = TestTools.post(request, "/posts/5/comments/", nil)
		assert_equal(response.status, 404, "status code doesn't match")
	end

	def test_get_comments
	 	me = TestTools.create_user_with("my_username", "my_password", "my_name", "my_image_url", "my_description")
	 	users = TestTools.create_x_users(Constants::COMMENTS_PER_PAGE + 5)
	 	post = TestTools.create_post_with_user(users[0])
	 	fake_post = TestTools.create_post_with_user(me)
	 	TestTools.create_x_comments_with_post_and_user(fake_post, me, 3)
	 	comments = []
	 	users.each_index do |i|
	 		comments << (TestTools.create_comment_with(post, users[i], "text#{i}", DateTime.now - i.days))
	 	end

	 	request = TestTools.request
	 	TestTools.authenticate(request, me)
	 	response = TestTools.get(request, "/posts/#{post.id}/comments/?page=2")
	 	assert_equal(response.status, 200, "status code doesn't match")

	 	json = JSON.parse(response.body)
	 	assert_equal(json["pages_count"], 2, "pages_count doesn't match")
	 	assert_equal(json["page"], 2, "page doesn't match")

	 	retrieved_comments = json["comments"]
	 	puts "comments : #{retrieved_comments}"
	 	puts "real_comments : #{comments}"
	 	assert_equal(retrieved_comments.length, 5)
	 	for i in 0...retrieved_comments.length
	 		retrieved_comment = retrieved_comments[i]
	 		real_comment = comments[i + Constants::COMMENTS_PER_PAGE]
	 		assert_equal(retrieved_comment["id"], real_comment.id, "id doesn't match")
	 		assert_equal(retrieved_comment["text"], real_comment.text, "text doesn't match")
	 		assert_equal(DateTime.parse(retrieved_comment["creation_date"].to_s), real_comment.creation_date.to_s, "creation_date doesn't match")
	 		assert_equal(retrieved_comment["owner"]["name"], real_comment.application_user.name, "owner's name doesn't match")
	 		assert_equal(retrieved_comment["owner"]["image_url"], real_comment.application_user.image_url, "owner's image_url doesn't match")
	 	end
	end

	def test_get_my_posts
		me = TestTools.create_user_with("my_username", "my_password", "my_name", "my_image_url", "my_description")
		user = TestTools.create_user
		posts = TestTools.create_x_posts_with_user(me, 5 + Constants::POSTS_PER_PAGE)
		for i in 0...posts.length
			if i < Constants::POSTS_PER_PAGE + 3
				TestTools.create_x_tags_with_post(posts[i], 2)
				TestTools.create_like_on_post_with_user(posts[i], user)
				TestTools.create_seen_on_post_with_user(posts[i], user)
				TestTools.create_seen_on_post_with_user(posts[i], me)
			end
		end
		TestTools.create_x_posts_with_user(user, 10)

		request = TestTools.request
		TestTools.authenticate(request, me)
		response = TestTools.get(request, "/me/posts/?page=2")
		assert_equal(response.status, 200, "status code doesn't match")

		json = JSON.parse(response.body)
		assert_equal(json["pages_count"], 2, "pages_count doesn't match")
		assert_equal(json["page"], 2, "page doesn't match")

		retrieved_posts = json["posts"]
		assert_equal(retrieved_posts.length, 5, "number of posts doesn't match")

		retrieved_posts.each_index do |i|
			retrieved_post = retrieved_posts[i]
			real_post = posts[i + Constants::POSTS_PER_PAGE]
			assert_equal(retrieved_post["id"], real_post.id, "id doesn't match")
			assert_equal(retrieved_post["text"], real_post.text, "text doesn't match")
	  		assert_equal(DateTime.parse(retrieved_post["creation_date"].to_s), real_post.creation_date.to_s, "creation_date doesn't match")
	  		assert_equal(retrieved_post["likes_count"], real_post.likes.count, "likes count doesn't match")
	  		assert_equal(retrieved_post["seens_count"], real_post.seens.count, "seens_count doesn't match")
	  		
	  		retrieved_tags = retrieved_post["tags"]
	  		if retrieved_tags
	  			real_tags = []
	  			real_post.tags.each do |t|
	  				real_tags << t.text
	  			end
	  			retrieved_tags.each do |t|
	  				assert(real_tags.include?(t))
	  			end
	  		end
		end
	end
end