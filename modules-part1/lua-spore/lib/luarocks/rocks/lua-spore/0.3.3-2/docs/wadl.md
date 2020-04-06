
# Spore.WADL

---

# Reference

This module allows to use a
[Web Application Description Language](http://www.w3.org/Submission/wadl/)
document as a SPORE specification.

__LIMITATION__ : cross-references are not supported.

This module requires [LuaExpat](http://www.keplerproject.org/luaexpat/).

## Global Functions

#### new_from_wadl( desc, [, { options }] )

Instanciate a ReST client from a [WADL](http://www.w3.org/Submission/wadl/)
document defined by an URL or a filename.

The optional table `options` allows to overwrite some parameters
of the description (see `Spore.new_from_spec`).

```lua
local wadl = require 'Spore.WADL'
local client = wadl.new_from_wadl 'yahoo_news_search.wadl'
```

#### convert( wadl )

Converts a [WADL](http://www.w3.org/Submission/wadl/)
document into a SPORE specification (represented by a `table`).

## Utilities

#### wadl2spore url

Converts a WADL document into a Spore Specification. By this way, the SPORE specification could be edited/modified before use.

```
$ wadl2spore yahoo_news_search.wadl > yahoo_news_search.json
```

# Examples

Not yet.
