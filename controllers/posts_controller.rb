require 'sinatra'
require './helpers/tools'
require './helpers/constants'
require './models/post'
require './models/application_user'
require './models/tag'
require './models/like'
require './models/seen'
require './schemas/posts_POST'

post %r{^/posts/?$} do
	schema = Schemas.schemas[:posts_POST]
	is_valid = Tools.validate_against_schema(schema, @json)
	halt 400, is_valid[1] unless is_valid[0]

	tags = @json["tags"]
	@json.delete("tags")

	post = Post.new do |p|
		@json.each do |k, e|
			p[k] = e
		end
		p.application_user = @user
		p.creation_date = DateTime.now
	end
	begin
		Post.transaction do
			post.save!
			if tags
				tags.each do |e|
					Tag.create!(:text => e, :post => post)
				end
			end
		end
	rescue
		halt 500, "Couldn't create the post\n" + $!.message 
	end
	""
end

get %r{^/posts/?$} do
	page = params[:page].to_i
	page = 1 if page == 0
	start_page = (page - 1) * Constants::POSTS_PER_PAGE
	posts = Post.find(:all, 
			:limit => Constants::POSTS_PER_PAGE,
			:offset => start_page,
            :joins => "LEFT JOIN likes ON posts.id = likes.post_id LEFT JOIN seens ON posts.id = seens.post_id " ,
            :select => "posts.*, count(posts.id) as posts_count, count(likes.post_id) as likes_count, count(seens.post_id) as seens_count",
            :group => "posts.id",
            :order => "likes_count DESC, seens_count DESC")
	result = {:posts => [], :pages_count => (Post.count.to_f / Constants::POSTS_PER_PAGE.to_f).ceil, :page => page}
	posts.each do |p|
		array = result[:posts]
		tags = []
		p.tags.each do |t|
			tags << t.text
		end
		array << {
			:id => p.id,
			:text => p.text,
			:image_url => p.image_url,
			:tags => tags,
			:creation_date => p.creation_date,
			:likes_count => p.likes_count,
			:seens_count => p.seens_count,
			:owner => {
				:name => p.application_user.name,
				:image_url => p.application_user.image_url
			}
		}
	end
	result.to_json
end

post %r{^/posts/(\d+)/likes/?$} do
	id = params[:captures][0]
	begin
		post = Post.find(id)
		Like.where(:post_id => post.id, :application_user_id => @user.id).first_or_create!
	rescue ActiveRecord::RecordNotFound
		halt 404, "Non-existing post"
	rescue
		halt 500, "Couldn't create like"
	end
	""
end

post %r{^/posts/(\d+)/seens/?$} do
	id = params[:captures][0]
	begin
		post = Post.find(id)
		Seen.where(:post_id => post.id, :application_user_id => @user.id).first_or_create!
	rescue ActiveRecord::RecordNotFound
		halt 404, "Non-existing post"
	rescue
		halt 500, "Couldn't create like"
	end
	""
end



