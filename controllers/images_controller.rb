require 'sinatra'
require 'sinatra/activerecord'
require './helpers/constants'

post %r{^/images/?$} do
	halt 400, "Content must be in png format" unless request.content_type == "image/png"
	identifier = Time.now.to_f.to_s
	identifier.gsub!(".", "")
	File.open(Constants::IMAGES_PATH + identifier, "w") do |f|
		f.write request.body.read
	end

	{
		"url" => "images/" + identifier
	}.to_json
end

get %r{^/images/(\d+)/?$} do
	identifier = params[:captures][0]
	path = Constants::IMAGES_PATH + identifier
	halt 404 unless File.exist?(path)

	file = File.open(path, "rb")
	content = file.read
	file.close

	content_type :png
	content
end