require "./users"
require "time"
require "json"

module Invites
    class Invite
        JSON.mapping({
            code: {type: String},
            guild: {type: InviteGuild},
            channel: {type: InviteChannel}
        })
    end

    class InviteChannel
        JSON.mapping(
            id: String,
            name: String,
            type: String
        )
    end

    class InviteGuild
        JSON.mapping(
            id: String,
            name: String,
            splash_hash: String
        )
    end

    class Invite
        JSON.mapping(
            code: String,
            guild: InviteGuild,
            channel: InviteChannel
        )
    end

    class InviteMetadata
        JSON.mapping(
            inviter: Users::User,
            uses: Int32,
            max_uses: Int32,
            max_age: Int32,
            temporary: Bool,
            created_at: String,
            revoked: Bool 
        )
    end
end