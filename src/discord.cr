require "http"
require "json"
require "colorize"
require "fiber"
require "random"
require "math"

def logInfo(text : String)
    puts "[INFO]".colorize(:yellow).toggle(true).to_s + " :: " + text + "\r\n"
end

def logWarning(text : String)
    puts "[WARNING]".colorize(:red).toggle(true).to_s + " :: " + text + " \r\n"
end

def logSuccess(text : String)
    puts "[SUCCESS]".colorize(:green).toggle(true).to_s + " :: " + text + "\r\n"
end

def logRequest(text : String)
    puts "[REQUEST]".colorize(:light_blue).toggle(true).to_s + " :: " + text + "\r\n"
end

BASE = "https://discordapp.com"
API_BASE = BASE + "/api/v6"
GATEWAY = API_BASE + "/gateway"
USERS = API_BASE + "/users"
ME = USERS + "/@me"
REGISTER = API_BASE + "/auth/register"
LOGIN = API_BASE + "/auth/login"
LOGOUT = API_BASE + "/auth/logout"
GUILDS = API_BASE + "/guilds"
CHANNELS = API_BASE + "/channels"
APPLICATIONS = API_BASE + "/oauth2/applications"

class Gateway
    JSON.mapping(
        url: String
    )
end

class Heartbeat
	JSON.mapping(
		op: Int32,
		d: Int32
	)

	def initialize(@op : Int32, @d : Int32)
	end
end

class HearbeatACK
	JSON.mapping(
		op: Int32
	)
end

class Hello
	JSON.mapping(
		hearbeat_interval: Int32,
		_trace: Array(String)
	)	
end

class Properties
	JSON.mapping({
		os: {type: String},
		browser: {type: String},
		device: {type: String},
		referrer: {type: String},
		referring_domain: {type: String},
    })
	
	def initialize(@os : String, @browser : String, @device : String, @referrer : String, @referring_domain : String)
	end
end

class Identify
	JSON.mapping({
		token: {type: String},
		properties: {type: Properties},
		compress: {type: Bool},
		large_threshold: {type: Int32},
		shard: {type: Array(Int32)},
    })

	def initialize(@token : String, @properties : Properties, @compress : Bool, @large_threshold : Int32, @shard : Array(Int32))		
	end
end

def getGateway()
    response = HTTP::Client.get(GATEWAY)
    return Gateway.from_json(response.body)
end

def jsonOrText(res : HTTP::Client::Response)
    text = res.body
    if res.headers["content-type"] == "application/json"
        return JSON.parse(text)
    end
    return text
end


class DSClient
    @user_agent : String
    def initialize(@connector : String, @session : HTTP::Client, @token : String, @bot_token : String)
    user_agent = "DiscordBot Crystal/0.19.4"
    @user_agent = user_agent
    end

    def request(method : String, url : String, kwargs : HTTP::Headers)
        headers = HTTP::Headers{"User-Agent" => @user_agent}

        if @token != nil
            headers["Authorization"] = "Bot #{@token}"
        end

        if kwargs.has_key?("json")
            headers["Content-Type"] = "application/json"
            kwargs["data"] = kwargs["json"].to_json
        end

        kwargs.merge!(headers)

        5.times do |i|
            res = @session.exec(method, url, kwargs)
            data = jsonOrText(res)
            if 300 > res.status_code >= 200
                logSuccess("#{method} #{url} with #{data} has returned #{res.status_code.to_s}")
                return data
            end

            if res.status_code == 429
                d = data["retry_after"].to_s
                i = d.to_i / 1000
                fmt = "We are being rate limited. Retrying in #{i.to_s} seconds."

                spawn do
                    sleep i.seconds
                end
            end

            if res.status_code == 502 && i <= 5
                spawn do
                    sleep (1 + i * 2).milliseconds
                end
            end

            if res.status_code == 403
                logWarning("Access forbidden #{data}")
            elsif res.status_code == 404
                logWarning("Page not found #{data}")
            else
                logWarning("Unknown HTTP error #{data}")
            end
        end
    end

    def get(url : String, headers : HTTP::Headers)
        return self.request("GET", url, headers)
    end

    def put(url : String, headers : HTTP::Headers)
        return self.request("PUT", url, headers)
    end

    def patch(url : String, headers : HTTP::Headers)
        return self.request("PATCH", url, headers)
    end

    def delete(url : String, headers : HTTP::Headers)
        return self.request("DELETE", url, headers)
    end

    def post(url : String, headers : HTTP::Headers)
        return self.request("POST", url, headers)
    end

    def close
        self.session.close
    end

    def _token(token : String, bot : String)
        @token = token
        @bot_token = bot
    end

    def emailLogin(email : String, password : String)
        payload = HTTP::Headers{"email" => email, "password" => password}
        data = self.post(LOGIN, payload).as(JSON::Any)
        self._token(data["token"].as_s, "")
    end

    def sendMessage(channel : String, msg : String, guild : String, tts : Bool)
        url = "#{CHANNELS}/#{channel}/message"
        r = Random.new                
        payload = HTTP::Headers{"content" => msg, "nonce" => r.next_int.to_s}

        if tts
            payload["tts"] = true
        end

        return self.post(url, payload)
    end
end