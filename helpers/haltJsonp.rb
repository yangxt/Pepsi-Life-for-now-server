require 'sinatra'
require 'sinatra/jsonp'

module Sinatra
    module HaltJsonp
    def haltJsonp(status, message = nil)
        halt 200, jsonp({"status" => status, "message" => message})
    end
end
end