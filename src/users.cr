require "json"

module Users
    class User
        JSON.mapping({
            id: {type: String},
            username: {type: String},
            discriminator: {type: String},
            avatar: {type: String},
            bot: {type: Bool, default: false},
            mfa_enabled: {type: Bool, default: false},
            verified: {type: Bool, default: false},
            email: {type: String, default: ""}
        })
    end

    class Settings
        JSON.mapping({
            render_embeds: {type: Bool},
            inline_embed_media: {type: Bool},
            inline_attachment_media: {type: Bool},
            enable_tts_command: {type: Bool},
            message_display_compact: {type: Bool},
            show_current_game: {type: Bool},
            allow_email_friend_request: {type: Bool},
            convert_emoticons: {type: Bool},
            locale: {type: String},
            theme: {type: String},
            guild_positions: {type: Array(String)},
            restricted_guilds: {type: Array(String)},
            # friend_source_flags: nil
        })
    end

    class GuildSettings
        JSON.mapping({
            suppress_everyone: {type: Bool},
            muted: {type: Bool},
            mobile_push: {type: Bool},
            message_notifications: {type: Int32},
            guild_id: {type: String},
            # channel_overrides
        })
    end

    class GuildSettingsEdit
        JSON.mapping({
            suppress_everyone: {type: Bool},
            muted: {type: Bool},
            mobile_push: {type: Bool},
            message_notifications: {type: Int32},
            #channel_overrides: 
        })
    end

    class PresenceUpdate
        JSON.mapping({
            user: {type: User},
            roles: {type: Array(Role)},
            game: {type: Gateway::Game, nilable: true},
            nick: {type: String},
            guild_id:  {type: String},
            stats: {type: String}
        })
    end

    class TypingStart
        JSON.mapping({
            channel_id: {type: String},
            user_id: {type: String},
            timestamp: {type: Int32}
        })
    end
end