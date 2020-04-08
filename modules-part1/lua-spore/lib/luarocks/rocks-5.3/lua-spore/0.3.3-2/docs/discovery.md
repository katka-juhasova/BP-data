
# Spore.GoogleDiscovery

---

# Reference

With this module, lua-Spore becomes a
[Google APIs Client Library](http://code.google.com/apis/discovery/libraries.html)
for Lua.
The list of supported APIs could be found
[here](http://code.google.com/apis/explorer/).

## Global Functions

#### new_from_discovery( desc, [, { options }] )

Instanciate a ReST client from a
[Google Discovery Document](http://code.google.com/apis/discovery/)
defined by an URL or a table with keys `api` and `version`.

The optional table `options` allows to overwrite some parameters of the description
(see `Spore.new_from_spec`).

```lua
local discovery = require 'Spore.GoogleDiscovery'
local client = discovery.new_from_discovery 'https://www.googleapis.com/discovery/v1/apis/urlshortener/v1/rest'
```

```lua
local client = discovery.new_from_discovery { api = 'urlshortener', version = 'v1' }
```

#### convert( gdoc )

Converts a [Google Discovery Document](http://code.google.com/apis/discovery/)
into a SPORE specification (both are represented by a table).

## Utilities

#### discovery2spore url

Converts a Google Discovery Document into a SPORE specification.
By this way, the SPORE specification could be edited/modified before use.

```sh
$ discovery2spore https://www.googleapis.com/discovery/v1/apis/urlshortener/v1/rest > urlshortener.json
```

# Examples

## Translate "Hello World"

```lua
local client = require 'Spore.GoogleDiscovery'.new_from_discovery{
    api = 'translate',
    version = 'v2',
}
client:enable 'Format.JSON'
client:enable('Parameter.Force', { key = '===========<INSERT-YOUR-KEY>===========' })
client.translate = client.translations_list -- alias

local r = client:translate{ source='en', target='fr', q=[[Hello World]] }
for _, v in ipairs(r.body.data.translations) do
    print(v.translatedText)
end
```

## The Discovery of Discovery

Retrieve the list of Google APIs which are described by a Discovery Document.

```lua
local discovery = require 'Spore.GoogleDiscovery'
local client = discovery.new_from_discovery 'https://www.googleapis.com/discovery/v1/apis/discovery/v1/rest'
client:enable 'Format.JSON'

local r = client:apis_list()
for _, item in ipairs(r.body.items) do
    print(item.name, item.version)
end
```

## URL Shortener

```lua
local client = require 'Spore.GoogleDiscovery'.new_from_discovery{
    api = 'urlshortener',
    version = 'v1',
}
client:enable 'Format.JSON'
local r = client:url_insert{ payload = { longUrl = 'http://www.google.com/' } }
print(r.body.id, r.body.longUrl)
```
