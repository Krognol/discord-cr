# All known endpoints


        EndpointStatus  = "https://status.discordapp.com/api/v6/"
        EndpointSm = EndpointStatus + "scheduled-maintenances/"
        EndpointSmActive = EndpointSm + "active.json"
        EndpointSmUpcoming = EndpointSm + "upcoming.json"

        EndpointDiscord = "https://discordapp.com/"
        EndpointAPI = EndpointDiscord + "api/v6/"
        EndpointGuilds = EndpointAPI + "guilds/"
        EndpointChannels = EndpointAPI + "channels/"
        EndpointUsers = EndpointAPI + "users/"
        EndpointGateway = EndpointAPI + "gateway"

        EndpointMe = EndpointUsers + "/@me"
        EndpointAuth = EndpointAPI + "auth/"
        EndpointLogin = EndpointAuth + "login"
        EndpointLogout = EndpointAuth + "logout"
        EndpointVerify = EndpointAuth + "verify"
        EndpointVerifyResend = EndpointAuth + "verify/resend"
        EndpointForgotPassword = EndpointAuth + "forgot"
        EndpointResetPassword = EndpointAuth + "reset"
        EndpointRegister = EndpointAuth + "register"

        EndpointVoice = EndpointAPI + "/voice/"
        EndpointVoiceRegions = EndpointVoice + "regions"
        EndpointVoiceIce = EndpointVoice + "ice"

        EndpointTutorial = EndpointAPI + "tutorial/"
        EndpointTutorialIndicators = EndpointTutorial + "indicators"

        EndpointTrack = EndpointAPI + "track"
        EndpointSso = EndpointAPI + "sso"
        EndpointReport = EndpointAPI + "report"
        EndpointIntegrations = EndpointAPI + "integrations"


    # +---------------------+
    # |                     |
    # |    User Endpoints   |
    # |                     |
    # +---------------------+

        def user(uid : String)
            return EndpointUsers + uid
        end

        def userAvatar(uid, aid : String)
            return EndpointUsers + uid + "/avatars/" + aid + ".jpg"
        end

        def userSettings(uid : String)
            return EndpointUsers + uid + "/settings"
        end

        def userGuilds(uid : String)
            return EndpointUsers + uid + "/guilds"
        end

        def userGuild(uid, gid : String)
            return EndpointUsers + uid + "/guilds/" + gid
        end

        def userGuildSettings(uid, gid : String)
            return EndpointUsers + uid + "/guilds/" + gid + "/settings"
        end

        def userChannels(uid : String)
            return EndpointUsers + uid + "/channels"
        end

        def userDevices(uid : String)
            return EndpointUsers + uid + "/devices"
        end

        def userConnections(uid : String)
            return EndpointUsers + uid + "/connections"
        end

    # +---------------------+
    # |                     |
    # |   Guild Endpoints   |
    # |                     |
    # +---------------------+

        def guild(gid : String)
            return EndpointGuilds + gid
        end

        def guildInvites(gid : String)
            return EndpointGuilds + gid + "/invites"
        end

        def guildChannels(gid : String)
            return EndpointGuilds + gid + "/channels"
        end

        def guildMembers(gid : String)
            return EndpointGuilds + gid + "/members"
        end

        def guildMember(gid, uid : String)
            return EndpointGuilds + gid + "/members/" + uid
        end

        def guildBans(gid : String)
            return EndpointGuilds + gdi + "/bans"
        end

        def guildBan(gid, uid : String)
            return EndpointGuilds + gid + "/bans/" + uid
        end

        def guildIntegrations(gid : String)
            return EndpointGuilds + gid + "/integrations"
        end

        def guidIntegration(gid, iid : String)
            return EndpointGuilds + gid + "/integrations/" + iid
        end

        def guildIntegrationSync(gid, iid : String)
            return EndpointGuilds + gid + "/integrations/" + iid + "/sync"
        end

        def guildRoles(gid : String)
            return EndpointGuilds + gid + "/roles"
        end

        def guildRole(gid, rid : String)
            return EndpointGuilds + gid + "/roles/" + rid
        end

        def guildInvites(gid : String)
            return EndpointGuilds + gid + "/invites"
        end

        def guildEmbed(gid : String)
            return EndpointGuilds + gid + "/embed"
        end

        def guildPrune(gid : String)
            return EndpointGuilds + gid + "/prune"
        end

        def guildIcon(gid, has : String)
            return EndpointGuilds + gid + "/icons/" + hash + ".jpg"
        end

        def guildSplash(gid, hash : String)
            return EndpointGuilds + gid + "/splashes/" + hash + ".jpg"
        end

    # +---------------------+
    # |                     |
    # |  Channel Endpoints  |
    # |                     |
    # +---------------------+

        def channel(cid : String)
            return EndpointChannels + cid
        end

        def channelPermissions(cid : String)
            return EndpointChannels + cid + "/permissions"
        end

        def channelPremission(cid, pid : String)
            return EndpointChannels + cid + "/permissions/" + pid
        end

        def channelInvites(cid : String)
            return EndpointChannels + cid + "/invites"
        end

        def channelTyping(cid : String)
            return EndpointChannels + cid + "/typing"
        end

        def channelMessages(cid : String)
            return EndpointChannels + cid+ "/messages" 
        end

        def channelMessaeg(cid, mid : String)
            return EndpointChannels + cid + "/messages/" + mid
        end

        def channelMessageAck(cid, mid : String)
            return EndpointChannels + cid + "/messages/" + mdi + "/ack"
        end

        def channelMessagesBulkDelete(cid : String)
            return channel(cid) + "/messages/bulk_delete"
        end

        def channelMessagesPins(cid : String)
            return channel(cID) + "/pins"
        end

        def channelMessagePin(cid, mid : String)
            return channel(cid) + "/pins/" + mid
        end

    # +---------------------+
    # |                     |
    # |   Other Endpoints   |
    # |                     |
    # +---------------------+

        def invite(iid : String)
            return EndpointAPI + "invite/" + iid
        end

        def integrationsJoin(iid : String)
            return EndpointAPI + "integrations/" + iid + "/join"
        end

        def emoji(eid : String)
            return EndpointAPI + "emojis/" + eid + ".png"
        end

        def oauth2
            return EndpointAPI + "oauth2/"
        end

        def applications
            return EndpointOauth2 + "applications"
        end

        def application(aid : String)
            return EndpointApplication + "/" + aid
        end

        def applicationsBot(aid : String)
            return EndpointApplications + "/" + aid + "/bot"
        end
