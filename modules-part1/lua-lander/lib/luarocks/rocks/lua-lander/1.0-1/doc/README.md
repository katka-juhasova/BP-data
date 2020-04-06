# Lua Lander

A modern utility library for Lua, offering tons of supplemental goodness for your projects.

* [Installation](#Installation)
* [Getting Started](#Getting-Started)
* [Acknowledgements](#Acknowledgements)
* [License](#License)

## Installation

**Direct Download**

1. Download the latest release from the [release page](https://github.com/skrolikowski/Lua-Lander/releases).
2. Unpack and upload to a folder that is recognized by `LUA_PATH`.

**LuaRocks**

...soon!

## Getting Started

Step 1: Add the following _once_  in your project:

```lua
require 'lua-lander'
```

Step 2: Start using!

```bash
> _:camelCase('Hello World!')          # => 'helloWorld'
> _:fill({'a', 'b', 'c'}, 'd', 2, 3)   # => {'a', 'd', 'd'}
> _:color('gray-100')                  # => 0.97, 0.98, 0.99
```

> Find more in the ([Documentation](http://shanekrolikowski.com/Lua-Lander/)).

## Acknowledgements

* This package is heavily inspired by [Lodash](https://lodash.com/).
* Default color palettes inspired by [tailwindcss](https://tailwindcss.com/docs/customizing-colors/#default-color-palette).

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details

