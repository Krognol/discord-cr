require "./users"
require "json"

class Webhook
    JSON.mapping(
        id: String,
        guild_id: String,
        channel_id: String,
        user: Users::User,
        name: String,
        avatar: String,
        token: String
    )
end
