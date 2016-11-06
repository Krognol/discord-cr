require "time"
require "channels"
require "users"
require "permissions"
require "voice"
require "json"
class IntegrationAccount
    JSON.mapping(
        id: String,
        name: String
    )
end

class Emoji
    JSON.mapping(
        id: String,
        name: String,
        roles: Array(permissions.Role),
        require_colons: Bool,
        managed: Bool
    )
end

class Integration
    JSON.mapping(
        id: String,
        name: String,
        Type: String,
        enabled: Bool,
        syncing: Bool,
        role_id: String,
        expire_behavior: Int32,
        expire_grace_perion: Int32,
        user: users.User,
        account: IntegrationAccount,
        synced_at: Time.date
    )
end

class GuildMember
    JSON.mapping(
        user: users.User,
        nick: String,
        roles: Array(permissions.Role),
        joined_at: Time.date,
        deaf: Bool,
        mute: Bool
    )
end

class Guild
    JSON.mapping(
        id: String,
        name: String,
        icon: String,
        splash: String,
        owner_id: String,
        region: String,
        afk_channel_id: String,
        afk_timeout: Int32,
        embed_enabled: Bool,
        embed_channel_id: String,
        verification_level: Int32,
        default_message_notifications: Int32,
        roles: Array(permissions.Role),
        emojis: Array(Emoji),
        features: Array(Feature),
        mfa_level: Int32,
        joined_at: Time.date,
        large: Bool,
        unavailable: Bool,
        member_count: Int32,
        voice_states: Array(voice.VoiceState),
        members: Array(GuildMember),
        channels: Array(channels.GuildChannel),
        #presences: Array(Presence)
    )
end

class UnavailableGuild
    JSON.mapping(
        id: String,
        unavailable: Bool
    )
end

class GuildEmbed
    JSON.mapping(
        enabled: Bool,
        channel_id: String
    )
end

