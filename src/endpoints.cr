# All known endpoints

module Endpoints
    Status     = "https://status.discordapp.com/api/v2/"
	Sm         = Status + "scheduled-maintenances/"
	SmActive   = Sm + "active.json"
	SmUpcoming = Sm + "upcoming.json"

	Discord  = "https://discordapp.com/"
	API      = Discord + "api/"
	Guilds   = API + "guilds/"
	Channels = API + "channels/"
	Users    = API + "users/"
	Gateway  = API + "gateway"

	Auth           = API + "auth/"
	Login          = Auth + "login"
	Logout         = Auth + "logout"
	Verify         = Auth + "verify"
	VerifyResend   = Auth + "verify/resend"
	ForgotPassword = Auth + "forgot"
	ResetPassword  = Auth + "reset"
	Register       = Auth + "register"

	Voice        = API + "/voice/"
	VoiceRegions = Voice + "regions"
	VoiceIce     = Voice + "ice"

	Tutorial           = API + "tutorial/"
	TutorialIndicators = Tutorial + "indicators"

	Track        = API + "track"
	Sso          = API + "sso"
	Report       = API + "report"
	Integrations = API + "integrations"


# +---------------------+
# |                     |
# |    User Endpoints   |
# |                     |
# +---------------------+

    def User(uid : String)
        return Users + uid
    end

    def UserAvatar(uid, aid : String)
        return Users + uid + "/avatars/" + aid + ".jpg"
    end

    def UserSettings(uid : String)
        return Users + uid + "/settings"
    end

    def UserGuilds(uid : String)
        return Users + uid + "/guilds"
    end

    def UserGuild(uid, gid : String)
        return Users + uid + "/guilds/" + gid
    end

    def UserGuildSettings(uid, gid : String)
        return Users + uid + "/guilds/" + gid + "/settings"
    end

    def UserChannels(uid : String)
        return Users + uid + "/channels"
    end

    def UserDevices(uid : String)
        return Users + uid + "/devices"
    end

    def UserConnections(uid : String)
        return Usres + uid + "/connections"
    end

# +---------------------+
# |                     |
# |   Guild Endpoints   |
# |                     |
# +---------------------+

    def Guild(gid : String)
        return Guilds + gid
    end

    def GuildInvites(gid : String)
        return Guilds + gid + "/invites"
    end

    def GuildChannels(gid: String)
        return Guilds + gid + "/channels"
    end

    def GuildMembers(gid: String)
        return Guilds + gid + "/members"
    end

    def GuildMember(gid, uid : String)
        return Guilds + gid + "/members/" + uid
    end

    def GuildBans(gid : String)
        return Guilds + gdi + "/bans"
    end

    def GuildBan(gid, uid: String)
        return Guilds + gid + "/bans/" + uid
    end

    def GuildIntegrations(gid : String)
        return Guilds + gid + "/integrations"
    end

    def GuidIntegration(gid, iid : String)
        return Guilds + gid + "/integrations/" + iid
    end

    def GuildIntegrationSync(gid, iid : String)
        return Guilds + gid + "/integrations/" + iid + "/sync"
    end

    def GuildRoles(gid : String)
        return Guilds + gid + "/roles"
    end

    def GuildRole(gid, rid : String)
        return Guilds + gid + "/roles/" + rid
    end

    def GuildInvites(gid : String)
        return Guilds + gid + "/invites"
    end

    def GuildEmbed(gid : String)
        return Guilds + gid + "/embed"
    end

    def GuildPrune(gid : String)
        return Guilds + gid + "/prune"
    end

    def GuildIcon(gid, has : String)
        return Guilds + gid + "/icons/" + hash + ".jpg"
    end

    def GuildSplash(gid, hash : String)
        return Guilds + gid + "/splashes/" + hash + ".jpg"
    end

# +---------------------+
# |                     |
# |  Channel Endpoints  |
# |                     |
# +---------------------+

    def Channel(cid : String)
        return Channels + cid
    end

    def ChannelPermissions(cid : String)
        return Channels + cid + "/permissions"
    end

    def ChannelPremission(cid, pid : String)
        return Channels + cid + "/permissions/" + pid
    end

    def ChannelInvites(cid : String)
        return Chanenls + cid + "/invites"
    end

    def ChannelTyping(cid : String)
        return Channels + cid + "/typing"
    end

    def ChannelMessages(cid: String)
        return Channels + cid+ "/messages" 
    end

    def ChannelMessaeg(cid, mid : String)
        return Channel + cid + cid + "/messages/" + mid
    end

    def ChannelMessageAck(cid, mid : String)
        return Channel + cid + "/messages/" + mdi + "/ack"
    end

    def ChannelMessagesBulkDelete(cid : String)
        return EndpointChannel(cID) + "/messages/bulk_delete"
    end

    def ChannelMessagesPins(cid : String)
        return EndpointChannel(cID) + "/pins"
    end

    def ChannelMessagePin(cid, mid : String)
        return EndpointChannel(cid) + "/pins/" + mid
    end

# +---------------------+
# |                     |
# |   Other Endpoints   |
# |                     |
# +---------------------+

    def Invite(iid : String)
        return API + "invite/" + iid
    end

    def IntegrationsJoin(iid : String)
        return API + "integrations/" + iid + "/join"
    end

    def Emoji(eid : String)
        return API + "emojis/" + eid + ".png"
    end

    def Oauth2
        return API + "oauth2/"
    end

    def Applications
        return Oauth2 + "applications"
    end

    def Application(aid : String)
        return Application + "/" + aid
    end

    def ApplicationsBot(aid : String)
        return Applications + "/" + aid + "/bot"
end