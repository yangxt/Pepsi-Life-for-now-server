require './helpers/haltJsonp'

module Sinatra
    module KeyProtection

    API_KEY = "nd6YyykHsCygZZi64F"
    def keyProtected!
        if (!(api_key = params[:api_key]) || api_key != API_KEY)
            haltJsonp 403, "You must add a valid API key to every request"
        end
    end
	end
end