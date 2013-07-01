require 'sinatra'
require 'sinatra/activerecord'

post %r{^/images/?$} do
	halt 400, "Content must be in png format" unless request.content_type == "image/png"
	identifier = Time.now.to_f.to_s
	identifier.gsub!(".", "")
	File.open("./public/images/" + identifier, "w") do |f|
		f.puts request.body.read
	end

	{
		"url" => "images/" + identifier
	}.to_json
end

get %r{^/images/(\d+)/?$} do
	identifier = params[:captures][0]
	file = File.open("./public/images/" + identifier, "r")
	content = file.read
	file.close

	content_type :png
	content
end