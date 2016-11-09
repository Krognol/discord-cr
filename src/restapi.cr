require "http"
require "json"
require "time"
require "./discord"
require "./invites"
require "./permissions"

module RestAPI
    class API
        def initialize(@user_agent : String, @client : Discord::Client)
        end
        def request(client : Discord::Client, method : String, url : String, args : HTTP::Headers)
            headers = HTTP::Headers{"User-Agent" => @user_agent, "Content-Type" => "application/json"}

            if client.bot_token != ""            
                headers["Authorization"] = client.bot_token
            elsif client.token != ""
                headers["Authorization"] = client.token
            end

            res = nil
            if args.has_key?("json")
                logRequest("Method: #{method}, Url: #{url}, Headers: #{headers.to_s}, Body: #{args["json"]}")
                res = HTTP::Client.exec(method, URI.parse(url), headers: headers, body: args["json"])
            else
                logRequest("Method: #{method}, Url: #{url}, Headers: #{headers.to_s}")
                res = HTTP::Client.exec(method, URI.parse(url), headers)
            end            
            data = jsonOrText(res)

            if 300 > res.status_code >= 200
                logSuccess("#{method} #{url} with #{data} has returned #{res.status_code.to_s}")
                return data
            end

            if res.status_code == 429
                dat = data.as(JSON::Any)
                d = dat["retry_after"].to_s
                i = d.to_i
                i = i / 1000
                logWarning("We are being rate limited. Retrying in #{i.to_s} seconds.")

                spawn do
                    sleep i.as(Int32).second
                end
            end

            if res.status_code == 502
                logWarning("Gateway unavailable")
            end

            if res.status_code == 403
                logWarning("Access forbidden #{data}")
            elsif res.status_code == 404
                logWarning("Page not found #{data}")
            elsif res.status_code == 401
                logWarning("Unauthorized #{data}")
            else
                logWarning("Unknown HTTP error #{data}")
            end
            
        end

        def get(url : String, headers : HTTP::Headers)
            return request("GET", url, headers)
        end

        def put(url : String, headers : HTTP::Headers)
            return request("PUT", url, headers)
        end

        def patch(url : String, headers : HTTP::Headers)
            return request("PATCH", url, headers)
        end

        def delete(url : String, headers : HTTP::Headers)
            return request("DELETE", url, headers)
        end

        def post(url : String, headers : HTTP::Headers)
            return request("POST", url, headers)
        end

        def close(client :: Discord::Client)
            client.session.close
        end
        
        def sendPrivateMessage(user : Users::User)
            payload = HTTP::Headers.new
            payload["json"] = {"recipient_id": user.id}.to_json
            return post(EndpointMe + "/channels", payload)
        end

        def sendMessage(channel : String, msg : String, guild : String, tts : Bool)
            url = channelMessages(channel)
            r = Random.new                
            payload = HTTP::Headers.new
            payload["json"] = {"content" => msg, "nonce" => r.next_int.to_s, "tts": tts}.to_json
            return post(url, payload)
        end

        def emailLogin(email : String, password : String)
            payload = HTTP::Headers.new
            payload["json"] = {"email": email, "password": password}.to_json
            data = post(EndpointLogin, payload).as(JSON::Any)        
            @client._token(data["token"].as_s, "")
        end

        def botLogin
            data = post(EndpointLogin, HTTP::Headers.new).as(JSON::Any)
            @client._token("", data["token"].as_s)
        end
        
        def logout
            return post(EndpointLogout, nil)
        end

        def register(username : String)
            payload = HTTP::Headers.new
            payload["json"] = {"username": username}.to_json
            res = post(EndpointRegister, payload)
            @client._token(res["token"].as_s, "")
        end

        def user(uid : String)
            res = get(EndpointUser(uid), HTTP::Headers.new)
            return Users::User.from_json(res.to_json)
        end

        def userAvatar(uid : String)
            # Not implemented yet
        end

        def userUpdate(email, password, username, avatar, newPassword : String)
            payload = HTTP::Headers.new
            payload["json"] = {"email": email, "password": password, "username": username, "avatar": avatar, "new_password": newPassword}.to_json
            res = patch(EndpointMe, payload)

            return Users::User.from_json(res.to_json)
        end        

        def userSettings
            res = get(EndpointUserSettings("@me"), HTTP::Headers.new)
            return Users::Settings.from_json(res.to_json)
        end

        def userChannels
            res = get(EndpointUserChannels("@me"), HTTP::Headers.new)
            return Array(Channels::DMChannel).from_json(res.to_json)
        end

        def userChannelCreate(recipient : String)
            payload = HTTP::Headers.new
            payload["json"] = {"recipient_id": recipient}.to_json
            res = post(EndpointUserChannels("@me"), payload)
            return Channels::DMChannel.from_json(res.to_json)
        end

        def userGuilds
            res = get(EndpointUserGuilds("@me"), HTTP::Headers.new)
            return Array(Channels::GuildChannel).from_json(res.to_json)
        end

        def userGuildSettings(gid : String, settings : Users::GuildSettingsEdit)
            payload = HTTP::Headers.new
            payload["json"] = settings.to_json
            res = patch(EndpointUserGuildSettings("@me"), payload)
            return Users::GuildSettings.from_json(res.to_json)
        end

        def userChannelPermissions(uid, cid : String)
            # not implemented yet
        end

        def guild(gid : String)
            res = get(EndpointGuild(gid), HTTP::Headers.new)
            return Guilds::Guild.from_json(res.to_json)
        end

        def guildCreate(name : String)
            payload = HTTP::Headers.new
            payload["json"] = {"name": name}.to_json

            res = post(EndponitGuilds, payload)
            return Guilds::Guild.from_json(res.to_json)
        end

        def guildEdit(gid : String, params)
            # Not implemented yet
        end

        def guildDelete(gid : String)
            res = delete(EndpointGuild(gid), HTTP::Headers.new)
            return Guilds::Guild.from_json(res.to_json)
        end

        def guildLeave(gid : String)
            return delete(EndponitUserGuild("@me", gid), HTTP::Headers.new)
        end

        def guildBans(gid : String)
            res = get(EndpointGuildBans(gid), HTTP::Headers.new)
            return Array(Users::User).from_json(res.to_json)
        end

        def guildBanCreate(gid, uid : String, days : Int32)
            uri = EndpointGuildBan(gid, uid)

            if days > 0
                uri = "#{uri}?delete-message-days=#{days.to_s}"
            end

            return put(uri, HTTP::Headers.new)
        end

        def guildBanDelete(gid, uid : String)
            return delete(EndpointGuildBan(gid, uid), HTTP::Headers.new)
        end

        def guildMembers(gid : String, offset, limit : Int32)
            uri = EndpointGuildMembers(gid)
            vals = {}
            if offset > 0
                vals["offset"] = offset.to_s
            end

            if limit > 0
                vals["limit"] = limit.to_s
            end

            if limit.size > 0
                uri = "#{uri}?#{URI.escape(vals)}"
            end

            res = get(uri, HTTP::Headers.new)

            return Array(Guilds::GuildMember).from_json(res.to_json)
        end

        def guildMember(gid, uid : String)
            res = get(EndpointGuildMember(gid, uid), HTTP::Headers.new)
            return Guilds::GuildMember.from_json(res.to_json)
        end

        def guildMemberDelete(gid, uid : String)
            return delete(EndpointGuildMember(gid, uid), HTTP::Headers.new)
        end

        def guildMemberEdit(gid, uid : String, roles : Array(String))
            payload = HTTP::Headers.new
            payload["json"] = {"roles": roles}.to_json
            return patch(EndpointGuildMember(gid, uid), payload)
        end

        def guildMemberMove(gid, uid, cid : String)
            payload = HTTP::Headers.new
            payload["json"] = {"channel_id": cid}.to_json

            return patch(EndpointGuildMember(gid, uid), payload)
        end

        def guildMemberNickname(gid, uid, nick : String)
            payload = HTTP::Headers.new
            payload["json"] = {"nick": nick}.to_json
            return patch(EndpointGuildMember(gid, uid), payload)
        end

        def guildChannels(gid : String)
            res = get(EndpointGuildChannels(gid), HTTP::Headers.new)
            return Array(Channels::GuildChannel).from_json(res.to_json)
        end

        def guildChannelCreate(gid, name, ctype : String)
            payload = HTTP::Headers.new
            payload["json"] = {"name": name, "type": ctype}.to_json
            res = post(EndpointGuildChannels(gid), payload)
            return Channels::GuildChannel.from_json(res.to_json)
        end

        def guildChannelsReorder(gid : String, chans : Array(Channels::GuildChannel))
            payload = HTTP::Headers.new{"json" => chans.to_json}
            
            return patch(EndpointGuildChannels(gid), payload)
        end

        def guildInvites(gid : String)
            res = get(EndpointGuildInvites(gid), HTTP::Headers.new)
            return Array(Invites::Invite).from_json(res.to_json)
        end

        def guildRoles(gid : String)
            res = get(EndpointGuildRoles(gid), HTTP::Headers.new)
            return Array(Role).from_json(res.to_json)
        end

        def guildRoleCreate(gid : String)
            res = post(EndpointGuildRoles(gid), HTTP::Headers.new)
            return Role.from_json(res.to_json)
        end

        def guildRoleEdit(gid, rid, name : String, color : Int32, hoist : Bool, perm : Int)
            if color > 0xFFFFFF
                logWarning("Color value is larger than 0xFFFFFF.")
                return
            end

            payload = HTTP::Headers.new
            payload["json"] = {"name": name, "color": color, "hoist": hoist, "permissions" : perm}.to_json
            res = patch(EndpointGuildRole(gid, rid), payload)
            return Role.from_json(res.to_json)
        end
        
    end
end