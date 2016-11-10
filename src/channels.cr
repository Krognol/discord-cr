require "json"
require "./users"
require "./permissions"

module Channels
    class Overwrite
        JSON.mapping(
            id: String,
            type: String,
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
            type: String,
            description: String,
            url: String,
            timestamp: String,
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

    class Channel
        JSON.mapping({
            id: {type: String},
            guild_id: {type: String},
            name: {type: String},
            type: {type: String},
            position: {type: Int32},
            is_private: {type: Bool},
            permission_overwrites: {type: Array(Overwrite)},
            topic: {type: String},
            last_message_id: {type: String},
            bitrate: {type: Int32},
            user_limit: {type: Int32},
            recipient: {type: Users::User, nilable: true}
        })
    end

    class Message
        JSON.mapping({
            id: {type: String},
            channel_id: {type: String},
            author: {type: Users::User},
            content: {type: String},
            timestamp: {type: String},
            edited_timestamp: {type: String, nilable: true},
            tts: {type: Bool},
            mention_everyone: {type: Bool},
            mentions: {type: Array(Users::User)},
            mention_roles: {type: Array(Role)},
            attachments: {type: Array(Attachment)},
            embeds: {type: Array(Embed)},
            nonce: {type: String, nilable: true},
            pinned: {type: Bool},
            webhook_id: {type: String, defualt: "", nilable: true}
        })
    end

    class MessageDelete
        JSON.mapping({
            id: {type: String},
            channel_id: {type: String}
        })
    end

    class MessageDeleteBulk
        JSON.mapping({
            ids: {type: Array(String)},
            channel_id: {type: String}
        })
    end
end