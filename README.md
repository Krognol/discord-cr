# discord-cr

A Discord library for Crystal!

Still needs some refinement. What you see is not the final product.

Still a WIP. Use at your own risk. Should at least be funcitonal now.

## Installation


Add this to your application's `shard.yml`:

```yaml
dependencies:
  discord-cr:
    github: Krognol/discord-cr
```


## Usage


```crystal
require "discord-cr"

# Note that the "Bot " part is very important
client = Discord::Client.new("regular token", "Bot token")
client.botLogin # Requires no arguments
# alternatively you can use 
# client.emailLogin("your email here", "your l33t p4ssword here")

# register an event
client.on_message_create do |message|
  puts message.content
end

client.connect
# better documentation will come later 👌
```

## Development

TODO: Write development instructions here

## Contributing

1. Fork it ( https://github.com/Krognol/discord-cr/fork )
2. Create your feature branch (git checkout -b my-new-feature)
3. Commit your changes (git commit -am 'Add some feature')
4. Push to the branch (git push origin my-new-feature)
5. Create a new Pull Request

## Contributors

- [[Krognol]](https://github.com/Krognol)  - creator, maintainer
