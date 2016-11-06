require "json"
require "time"
require "./users"

class Overwrite
    JSON.mapping(
        id: String,
        Type: String,
        allow: Int32,
        deny: Int32
    )
end

class Thumbnail
    JSON.mapping(
        url: String,
        proxy_url: String,
        height: Int32,
        width: Int32
    )
end

class Video
    JSON.mapping(
        url: String,
        height: Int32,
        width: Int32
    )
end

class Image
    JSON.mapping(
        url: String,
        proxy_url: String,
        height: Int32,
        width: Int32
    )
end

class Provider
    JSON.mapping(
        name: String,
        url: String
    )
end

class Author
    JSON.mapping(
        name: String,
        url: String,
        icon_url: String,
        proxy_icon_url: String
    )
end

class Footer
    JSON.mapping(
        text: String,
        icon_url: String,
        proxy_icon_url: String
    )
end

class Field
    JSON.mapping(
        name: String,
        value: String,
        inline: Bool
    )
end

class Attachment
    JSON.mapping(
        id: String,
        filename: String,
        size: Int32,
        url: String,
        proxy_url: String,
        height: Int32,
        width: Int32
    )
end

class Embed
    JSON.mapping(
        title: String,
        Type: String,
        description: String,
        url: String,
        timestamp: Time.date,
        color: Int32,
        footer: Footer,
        image: Image,
        thumbnail: Thumbnail,
        video: Video,
        provider: Provider,
        author: Author,
        fields: Array(Field)
    )
end

class GuildChannel
    JSON.mapping(
        id: String,
        guild_id: String,
        name: String,
        Type: String,
        position: Int32,
        is_private: Bool,
        permission_overwrites: Array(Overwrite),
        topic: String,
        last_message_id: String,
        bitrate: Int32,
        user_limit: Int32
    )
end

class DMChannel
    JSON.mapping(
        id: String,
        is_private: Bool,
        recipient: users.User,
        last_message_id: String
    )
end

class Message
    JSON.mapping(
        id: String,
        channel_id: String,
        author: users.User,
        content: String,
        timestamp: Time.date,
        edited_timestamp: Time.date,
        tts: Bool,
        mention_everyone: Bool,
        mentions: Array(user.User),
        mention_roles: Array(persmissions.Role),
        attachments: Array(Attachment),
        embeds: Array(Embed),
        nonce: String,
        pinned: Bool,
        webhook_id: String
    )
end
