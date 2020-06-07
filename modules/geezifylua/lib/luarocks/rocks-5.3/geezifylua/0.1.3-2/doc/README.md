# Geezify-Lua

geezifylua is a luarock(i.e. package for the lua language) that converts geez-script numbers to arabic and viceversa.

## Installation

```lua
luarocks install geezifylua
```

## Usage

```lua
geezifylua = require "geezifylua""
geezifylua.geezify.geezify(12)                   #=> '፲፪'
geezifylua.geezify.geezify(3033)                 #=> '፴፻፴፫'
geezifylua.geezify.geezify(100200000)            #=> '፼፳፼'
geezifylua.geezify.geezify(333333333)            #=> '፫፼፴፫፻፴፫፼፴፫፻፴፫'
geezifylua.arabify.arabify('፲፪')                 #=> 12
geezifylua.arabify.arabify('፴፻፴፫')               #=> 3033
geezifylua.arabify.arabify('፼፳፼')                #=> 100200000
geezifylua.arabify.arabify('፫፼፴፫፻፴፫፼፴፫፻፴፫')      #=> 333333333

```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/yilkalargaw/geezify-lua. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

This lua-rock is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the geezify-lua project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/yilkalargaw/geezify-lua/blob/master/CODE_OF_CONDUCT.md).
