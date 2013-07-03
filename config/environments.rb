require 'yaml'
#The environment variable DATABASE_URL should be in the following format:

# => postgres://{user}:{password}@{host}:{port}/path
configure :production, :development, :test do
	db = YAML.load_file('./config/database.yml')[ENV['RACK_ENV'] || 'development']
	puts db
	ActiveRecord::Base.establish_connection(
			:adapter => db['adapter'] == 'postgres' ? 'postgresql' : db['adapter'],
			:host     => db['host'],
			:username => db['username'],
			:password => db['password'],
			:database => db['database'],
			:encoding => 'utf8'
	)
end