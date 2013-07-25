require './tests/common'
require 'base64'

Dir["./models/*.rb"].each do |f|
	require f
end


module TestTools

	def self.delete_all
		ApplicationUser.delete_all
		Post.delete_all
		Tag.delete_all
		Comment.delete_all
		Like.delete_all
		Seen.delete_all
		Friendship.delete_all
		Coordinate.delete_all
	end

	#Request
	def self.request
		request = Rack::Test::Session.new(Rack::MockSession.new(Sinatra::Application))
	end

	def self.authenticate(request, user)
		base = Base64.encode64("#{user.username}:#{user.password}")
		request.header("Authorization", "Basic #{base}")
	end

	def self.send_request(request, method, path, body)
		json = ""
		json = body.to_json if body
		request.header("Content-Type", "application/json")
		api_key = "nd6YyykHsCygZZi64F"
		if path.include?("?")
			path << "&api_key=" + api_key
		else
			path << "?api_key=" + api_key
		end

		case method
		when :post
			request.post(path, params=json)
		when :put
			request.put(path, params=json)
		when :get
			request.get(path)
		when :patch
			request.patch(path, params=json)
		end
		request.last_response
	end

	def self.post(request, path, body)
		self.send_request(request, :post, path, body)
	end

	def self.put(request, path, body)
		self.send_request(request, :put, path, body)
	end

	def self.get(request, path)
		self.send_request(request, :get, path, nil)
	end

	def self.patch(request, path, body)
		self.send_request(request, :patch, path, body)
	end

	#ApplicationUser
	def self.create_user_with(username, password, name, image_url, description)
		ApplicationUser.create({
			:username => username,
			:password => password,
			:name => name,
			:image_url => image_url,
			:description => description
		})
	end

	def self.create_user
		create_user_with("username0", "password0", "name0", "image_url0", "description0")
	end

	def self.create_x_users(x)
		array = []
		for i in 0...x
			array << create_user_with("username#{i}", "password#{i}", "name#{i}", "image_url#{i}", "description#{i}")
		end
		array
	end

	#Post
	def self.create_post_with(text, image_url, creation_date, application_user)
		Post.create({
			:text => text,
			:image_url => image_url,
			:creation_date => creation_date,
			:application_user => application_user
		})
	end

	def self.create_post_with_user(user)
		create_post_with("text0", "image_url0", DateTime.now, user)
	end

	def self.create_x_posts_with_user(user, x)
		array = []
		for i in 0...x
			date = DateTime.now - i.days
			array << create_post_with("text#{i}", "image_url#{i}", date, user)
		end
		array
	end

	#Tag
	def self.create_tag_with(post, text)
		Tag.create({
			:text => text,
			:post => post
		})
	end
	def self.create_tag_with_post(post)
		self.create_tag_with(post, "tag0")
	end

	def self.create_x_tags_with_post(post, x)
		array = []
		for i in 0...x
			array << self.create_tag_with(post, "tag#{i}")
		end
	end

	#Like
	def self.create_like_on_post_with_user(post, user)
		Like.create({
			:post => post,
			:application_user => user
		})
	end

	#Seen
	def self.create_seen_on_post_with_user(post, user)
		Seen.create({
			:post => post,
			:application_user => user
		})
	end

	#Friend
	def self.create_friendship(user1, user2)
		Friendship.create({
			:user1 => user1,
			:user2 => user2
		})
	end

	#Coordinate
	def self.create_coordinate_with_user(user, lat, long)
		Coordinate.create({
			:application_user => user,
			:latitude => lat,
			:longitude => long
		})
	end

	#Comment
	def self.create_comment_with(post, user, text, date)
		Comment.create({
			:text => text,
			:post => post,
			:application_user => user,
			:creation_date => date
		})
	end

	def self.create_comment_with_post_and_user(post, user)
		self.create_comment_with(post, user, "text0", DateTime.now)
	end

	def self.create_x_comments_with_post_and_user(post, user, x)
		array = []
		for i in 0...x
			date = DateTime.now + i.days
			array << self.create_comment_with(post, user, "tag#{x}", date)
		end
		array
	end

end 