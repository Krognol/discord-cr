require "users"
require "time"
require "json"
class InviteChannel
    JSON.mapping(
        id: String,
        name: String,
        Type: String
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
        inviter: users.User,
        uses: Int32,
        max_uses: Int32,
        max_age: Int32,
        temporary: Bool,
        created_at: Time.date,
        revoked: Bool 
    )
end