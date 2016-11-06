require "json"

class VoiceState
    JSON.mapping(
        guild_id: String,
        channel_id: String,
        user_id: String,
        session_id: String,
        deaf: Bool,
        mute: Bool,
        self_deaf: Bool,
        self_mute: Bool,
        suppress: Bool
    )
end

class VoiceRegion
    JSON.mapping(
        id: String,
        name: String,
        sample_hostname: String,
        sample_port: Int32,
        vip: Bool,
        optimal: Bool,
        deprecated: Bool,
        custom: Bool
    )
end