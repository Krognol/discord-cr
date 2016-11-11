require "http"
require "json"
require "time"
require "mutex"
require "./discord"
require "./invites"
require "./permissions"

module RestAPI
    module API

        def initialize(@user_agent : String)#, @client : Discord::Client)
        end

        private def jsonOrText(res : HTTP::Client::Response)    
            if res.headers["content-type"] == "application/json"
                js = JSON.parse(res.body.to_json)
                return js
            end
            res.body.to_json
        end

        
        def request(method : String, url : String, args : HTTP::Headers)
            headers = HTTP::Headers{"User-Agent" => @user_agent, "Content-Type" => "application/json"}
            if @bot_token != ""            
                headers["Authorization"] = @bot_token
            elsif @token != ""
                headers["Authorization"] = @token
            end
            done = false
            until done
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
                    done = true
                    return data
                end

                if res.status_code == 429
                    i = data.as(JSON::Any)["retry_after"].as_i
                    i = i / 1000
                    logWarning("We are being rate limited. Retrying in #{i.to_s} seconds.")

                    spawn do
                        sleep i.second
                        request(method, url, args)
                    end
                end

                if res.status_code == 502
                    logWarning("Gateway unavailable: #{data}")
                end

                if res.status_code == 403
                    logWarning("Access forbidden: #{data}")
                elsif res.status_code == 404
                    logWarning("Page not found: #{data}")
                elsif res.status_code == 401
                    logWarning("Unauthorized: #{data}")
                else
                    logWarning("Unknown HTTP error: #{data}")
                end
            end
            data
        end

        def get(url : String, headers : HTTP::Headers)
            request("GET", url, headers)
        end

        def put(url : String, headers : HTTP::Headers)
            request("PUT", url, headers)
        end

        def patch(url : String, headers : HTTP::Headers)
            request("PATCH", url, headers)
        end

        def delete(url : String, headers : HTTP::Headers)
            request("DELETE", url, headers)
        end

        def post(url : String, headers : HTTP::Headers)
            request("POST", url, headers)
        end

        def close
            #@session.close
        end

        def emailLogin(email : String, password : String)
            payload = HTTP::Headers.new
            payload["json"] = {"email": email, "password": password}.to_json
            data = post(EndpointLogin, payload)
            if data.is_a?(JSON::Any)
                _token(JSON.parse(data.to_s)["token"].as_s, "")
            else
                logFatal("Error while logging in: #{data}")
                return
            end
        end

        def botLogin
            data = post(EndpointLogin, HTTP::Headers.new)
            if data.is_a?(JSON::Any)
                # Seems like a really weird hack
                # Will try to find a better solution
                _token("", JSON.parse(data.to_s)["token"].as_s)
            else
                logFatal("Error while logging in as a bot: #{data}")
                return
            end
        end
        
        def logout
            post(EndpointLogout, nil)
        end

        def register(username : String)
            payload = HTTP::Headers.new
            payload["json"] = {"username": username}.to_json
            res = post(EndpointRegister, payload)
            _token(res["token"].as_s, "")
        end

        def user(uid : String)
            res = get(user(uid), HTTP::Headers.new)
            Users::User.from_json(res.to_json)
        end

        def userAvatar(uid : String)
            # Not implemented yet
        end

        def userUpdate(email, password, username, avatar, newPassword : String)
            payload = HTTP::Headers.new
            payload["json"] = {"email": email, "password": password, "username": username, "avatar": avatar, "new_password": newPassword}.to_json
            res = patch(EndpointMe, payload)

            Users::User.from_json(res.to_json)
        end        

        def userSettings
            res = get(userSettings("@me"), HTTP::Headers.new)
            Users::Settings.from_json(res.to_json)
        end

        def userChannels
            res = get(userChannels("@me"), HTTP::Headers.new)
            Array(Channels::Channel).from_json(res.to_json)
        end

        def userChannelCreate(recipient : String)
            payload = HTTP::Headers.new
            payload["json"] = {"recipient_id": recipient}.to_json
            res = post(userChannels("@me"), payload)
            Channels::Channel.from_json(res.to_json)
        end

        def userGuilds
            res = get(userGuilds("@me"), HTTP::Headers.new)
            Array(Channels::Channel).from_json(res.to_json)
        end

        def userGuildSettings(gid : String, settings : Users::GuildSettingsEdit)
            payload = HTTP::Headers.new
            payload["json"] = settings.to_json
            res = patch(userGuildSettings("@me"), payload)
            Users::GuildSettings.from_json(res.to_json)
        end

        def userChannelPermissions(uid, cid : String)
            # not implemented yet
        end

        def guild(gid : String)
            res = get(guild(gid), HTTP::Headers.new)
            Guilds::Guild.from_json(res.to_json)
        end

        def guildCreate(name : String)
            payload = HTTP::Headers.new
            payload["json"] = {"name": name}.to_json

            res = post(EndponitGuilds, payload)
            Guilds::Guild.from_json(res.to_json)
        end

        def guildEdit(gid : String, params)
            # Not implemented yet
        end

        def guildDelete(gid : String)
            res = delete(guild(gid), HTTP::Headers.new)
            Guilds::Guild.from_json(res.to_json)
        end

        def guildLeave(gid : String)
            delete(userGuild("@me", gid), HTTP::Headers.new)
        end

        def guildBans(gid : String)
            res = get(guildBans(gid), HTTP::Headers.new)
            Array(Users::User).from_json(res.to_json)
        end

        def guildBanCreate(gid, uid : String, days : Int32)
            uri = guildBan(gid, uid)

            if days > 0
                uri = "#{uri}?delete-message-days=#{days.to_s}"
            end

            put(uri, HTTP::Headers.new)
        end

        def guildBanDelete(gid, uid : String)
            delete(guildBan(gid, uid), HTTP::Headers.new)
        end

        def guildMembers(gid : String, offset, limit : Int32)
            uri = guildMembers(gid)
            vals = {} of String => String
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

            Array(Guilds::GuildMember).from_json(res.to_json)
        end

        def guildMember(gid, uid : String)
            res = get(guildMember(gid, uid), HTTP::Headers.new)
            Guilds::GuildMember.from_json(res.to_json)
        end

        def guildMemberDelete(gid, uid : String)
            delete(guildMember(gid, uid), HTTP::Headers.new)
        end

        def guildMemberEdit(gid, uid : String, roles : Array(String))
            payload = HTTP::Headers.new
            payload["json"] = {"roles": roles}.to_json
            patch(guildMember(gid, uid), payload)
        end

        def guildMemberMove(gid, uid, cid : String)
            payload = HTTP::Headers.new
            payload["json"] = {"channel_id": cid}.to_json

            patch(guildMember(gid, uid), payload)
        end

        def guildMemberNickname(gid, uid, nick : String)
            payload = HTTP::Headers.new
            payload["json"] = {"nick": nick}.to_json
            patch(guildMember(gid, uid), payload)
        end

        def guildChannels(gid : String)
            res = get(guildChannels(gid), HTTP::Headers.new)
            Array(Channels::Channel).from_json(res.to_json)
        end

        def guildChannelCreate(gid, name, ctype : String)
            payload = HTTP::Headers.new
            payload["json"] = {"name": name, "type": ctype}.to_json
            res = post(guildChannels(gid), payload)
            Channels::Channel.from_json(res.to_json)
        end

        def guildChannelsReorder(gid : String, chans : Array(Channels::Channel))
            payload = HTTP::Headers.new
            payload["json"] = chans.to_json
            patch(guildChannels(gid), payload)
        end

        def guildInvites(gid : String)
            res = get(guildInvites(gid), HTTP::Headers.new)
            Array(Invites::Invite).from_json(res.to_json)
        end

        def guildRoles(gid : String)
            res = get(guildRoles(gid), HTTP::Headers.new)
            Array(Role).from_json(res.to_json)
        end

        def guildRoleCreate(gid : String)
            res = post(guildRoles(gid), HTTP::Headers.new)
            Role.from_json(res.to_json)
        end

        def guildRoleEdit(gid, rid, name : String, color : Int32, hoist : Bool, perm : Int)
            if color > 0xFFFFFF
                logWarning("Color value is larger than 0xFFFFFF.")
                return
            end

            payload = HTTP::Headers.new
            payload["json"] = {"name": name, "color": color, "hoist": hoist, "permissions" : perm}.to_json
            res = patch(guildRole(gid, rid), payload)
            Role.from_json(res.to_json)
        end
        
        def guildRoleReorder(gid : String, roles : Array(Role))
            payload = HTTP::Headers.new
            payload["json"] = roles.to_json
            res = patch(guildRoles(gid), payload)
            Array(Role).from_json(res.to_json)
        end

        def guildRoleDelete(gid, rid : String)
            delete(guildRole(gid, rid), HTTP::Headers.new)
        end

        def guildIntegrations(gid : String)
            res = get(guildIntegrations(gid), HTTP::Headers.new)
            Array(Guilds::Integration).from_json(res.to_json)
        end

        def guildIntegrationCreate(gid, itype, iid : String)
            payload = HTTP::Headers.new
            payload["json"] = {"type": itype, "id": iid}.to_json
            post(guildIntegrations(gid), payload)
        end

        def guildIntegrationsEdit(gid, iid : String, expire, grace : Int32, emotes : Bool)
            payload = HTTP::Headers.new
            payload["json"] = {"expire_behavior": expire, "expire_grace_period": grace, "enable_emoticons": emotes}.to_json
            patch(guildIntegration(gid, iid), payload)
        end

        def guildIntegrationDelete(gid, iid : String)
            delete(guildIntegration(gid, iid), HTTP::Headers.new)
        end

        def guildIcon(gid : String)
            # not implemented yet
        end

        def guildSplash(gid : String)
            # not implemented yet
        end

        def guildEmbed(gid : String)
            res = get(guildEmbed(gid), HTTP::Headers.new)
            Guilds::GuildEmbed.from_json(res.to_json)
        end

        def guildEmbedEdit(gid : String, enabled : Bool, channel : String)
            payload = HTTP::Headers.new
            payload["json"] = {"enabled": enabled, "channel_id": channel}.to_json
            patch(guildEmbed(gid), payload)
        end

        def channel(cid : String)
            res = get(channel(cid), HTTP::Headers.new)
            Channels::Channel.from_json(res.to_json) 
        end

        def channelEdit(cid, name : String)
            payload = HTTP::Headers.new
            payload["json"] = {"name": name}.to_json
            res = patch(channel(cid), payload)
            Channels::Channel.from_json(res.to_json)
        end

        def channelDelete(cid : String)
            res = delete(channel(cid), HTTP::Headers.new)
            Channels::Channel.from_json(res.to_json)
        end

        def channelTyping(cid : String)
            post(channelTyping(cid), HTTP::Headers.new)
        end

        def channelMessages(cid : String, limit : Int32, before, after : String)
            uri = channelMessages(cid)
            v = {} of String => String
            if limit > 0
                v["limit"] = limit.to_s
            end

            if after != ""
                v["after"] = after
            end

            if before != ""
                v["before"] = before
            end

            if v.size > 0
                uri = "#{uri}?#{URI.escape(v)}"
            end

            res = get(uri, HTTP::Headers.new)
            Array(Channels::Message).from_json(res.to_json)
        end

        def channelMessage(cid, mid : String)
            res = get(channelMessage(cid, mid), HTTP::Headers.new)
            Channels::Message.from_json(res.to_json)
        end

        def channelMessageAck(cid, mid : String)
            post(channelMessageAck(cid, mid), HTTP::Headers.new)
        end 

        private def channelMessageSend(cid, content : String, tts : Bool)
            payload = HTTP::Headers.new
            payload["json"] = {"content": content, "tts": tts}.to_json
            res = post(channelMessages(cid), payload)
            Channels::Message.from_json(res.to_json)
        end

        def sendMessage(cid, content : String)
            channelMessageSend(cid, content, false)
        end

        def sendTTSMessage(cid, content : String)
            channelMessageSend(cid, content, true)
        end

        def channelMessageEdit(cid, mid, content : String)
            payload = HTTP::Headers.new
            payload["json"] = {"content": content}.to_json
            res = patch(channelMessage(cid, mid), payload)
            Channels::Message.from_json(res.to_json)
        end

        def channelMessageDelete(cid, mid : String)
            delete(channelMessage(cid, mid), payload)
        end

        def channelMessagesBulkDelete(cid : String, messages : Array(String))
            if messages.size == 0
                return
            end

            if messages.size == 1
                channelMessageDelete(cid, messages[0])
            end

            if messages.size > 100
                until messages.size == 100
                    messages.chomp
                end
            end
            payload = HTTP::Headers.new
            payload["json"] = {"messages": messages}.to_json
            post(channelMessagesBulkDelete(cid), payload)
        end

        def channelMessagePin(cid, mid : String)
            put(channelMessagePin(cid, mid), HTTP::Headers.new)
        end

        def channelMessageUnpin(cid, mid : String)
            delete(channelMessagePin(cid, mid), HTTP::Headers.new)
        end

        def channelMessagesPinned(cid : String)
            res = get(channelMessagesPins(cid), HTTP::Headers.new)
            Array(Channels::Message).from_json(res.to_json)
        end

        def channelFileSend()
            # not implemented yet
        end

        def channelInvites(cid : String)
            res = get(channelInvites(cid), HTTP::Headers.new)
            Array(Invites::Invite).from_json(res.to_json)
        end

        def channelInviteCreate(cid : String, i : Invites::InviteMetadata, xkcd : Bool)
            payload = HTTP::Headers.new
            payload["json"] = {"max_age": i.max_age, "max_uses": i.max_uses, "temporary": i.temporary, "xkcdpass": xkcd}.to_json
            res = post(channelInvites(cid), payload)
            Invites::Invite.from_json(res.to_json)
        end

        def channelPermissionsSet(cid, tid, ttype : String, allow, deny : Int32)
            payload = HTTP::Headers.new
            payload["json"] = {"id": tid, "type": ttype, "allow": allow, "deny": deny}.to_json
            put(channelPermission(cid, tid), payload)
        end

        def invite(iid : String)
            res = get(invite(iid), HTTP::Headers.new)
            Invites::Invite.from_json(res.to_json)
        end

        def inviteDelete(iid : String)
            res = delete(invite(iid), HTTP::Headers.new)
            Invites::Invite.from_json(res.to_json)
        end

        def inviteAccept(iid : String)
            res = post(invite(iid), HTTP::Headers.new)
            Invites::Invite.from_json(res.to_json)
        end

        def voiceRegions
            res = get(EndpointVoiceRegions, HTTP::Headers.new)
            Array(Voice::VoiceRegion).from_json(res.to_json)
        end

        def voiceICE
            # not implemented yet
        end
    end
end