
get %r{^/admin/?$} do
	protected!
	content_type :html
	file = File.new("admin/admin.html", "r")
	data = ""
	while (line = file.gets)
    	data += line
	end
	file.close
	data
end