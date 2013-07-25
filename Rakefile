require "./app"
require "sinatra/activerecord/rake"

module Sinatra
  module ActiveRecordTasks
    def migrations_dir
      ActiveRecord::Migrator.migrations_path
    end
  end
end