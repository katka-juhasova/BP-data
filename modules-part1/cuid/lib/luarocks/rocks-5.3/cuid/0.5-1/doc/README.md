# CUID

CUID generator for Lua.

[![Build Status](https://travis-ci.org/marcoonroad/cuid.svg?branch=master)](https://travis-ci.org/marcoonroad/cuid)
[![Coverage Status](https://coveralls.io/repos/github/marcoonroad/cuid/badge.svg?branch=master)](https://coveralls.io/github/marcoonroad/cuid?branch=master)

For more information, see: http://usecuid.org

### Installation

If available on LuaRocks:

```shell
$ luarocks --local install cuid
```

Otherwise, you could install through this root project directory:

```shell
$ luarocks --local make
```

### Usage

To load this library, just type:

```lua
local cuid = require ("cuid")
```

Once loaded, you can generate fresh CUIDs through:

```lua
local id = cuid.generate ( )
```

As an example of CUID, we have `c00p6qup20000ckkzslahp5pn`, where:

- `c` is the CUID prefix (so it's a valid variable).
- `00p6qup2` is a timestamp/continuous number.
- `0000` is the internal sequential counter.
- `ckkz` is the machine/host fingerprint.
- `slahp5pn` are pseudo-random numbers.

To generate slugs (shorter and collision-weak CUIDs), just type the following:

```lua
local slug = cuid.slug ( )
```

Slugs are made of 8 characters, and there's no prefix
(as is the case of CUIDs - "c" in the case). So, slugs
are often used as suffixes, for instance, on URLs.

### Configuration

You could as well set a custom fingerprint for CUID generation
by an environment variable. This environment variable is called
`LUA_CUID_FINGERPRINT`.

Whenever the `cuid` library is loaded, it will lookup such
environment variable to generate a fingerprint if it is
indeed defined.

It's also possible to set a custom fingerprint prior CUID/slug
generation, just type the following for both cases:

```lua
local cuid = require 'cuid'

local fingerprint_input = "It's me, Mario!"

local id   = cuid.generate (fingerprint_input)
local slug = cuid.slug (fingerprint_input)
```

Such fingerprint text is used only once per function call,
that is, on the next function call, everything remains the
same of previous state prior custom fingerprint's function
call.

### Remarks

Pull requests and issues are welcome! Happy hacking!
