require './models/application_user'

module Sinatra
    module Authentication
    def auth
        @auth ||= Rack::Auth::Basic::Request.new(request.env)
    end

    def unauthorized!(realm="myApp.com")
        headers 'WWW-Authenticate' => %(Basic realm="#{realm}")
        throw :halt, [ 401, 'Authorization Required' ]
    end

    def bad_request!
        throw :halt, [ 400, 'Bad Request' ]
    end

    def authorize(username, password)
        return nil unless user = ApplicationUser.where(:username => username, :password => password).first
        user
    end

    def authenticate!
        unauthorized! unless auth.provided?
        bad_request! unless auth.basic?
        unauthorized! unless user = authorize(*auth.credentials)
        user
    end
    end
end