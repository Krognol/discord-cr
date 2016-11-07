require "json"

class Role
    JSON.mapping({
        id: {type: String},
        name: {type: String},
        color: {type: Int32},
        hoist: {type: Bool},
        position: {type: Int32},
        permissions: {type: Int32},
        managed: {type: Bool},
        mentionable: {type: Bool}
    })
end