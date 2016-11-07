require "json"

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


