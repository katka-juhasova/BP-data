
# Spore

---

# Reference

## Global Functions

#### new_from_spec( desc1, [desc2, ...][, { options }] )

Instanciate a ReST client from one or more descriptions defined by
a filename or an URL.

The optional table `options` allows to overwrite some parameters
of the description:

- `authentication`,
- `base_url`,
- `expected_status`,
- `formats`,
- `unattended_params`

```lua
local client = require 'Spore'.new_from_spec 'github.json'
```

#### new_from_string( desc1, [desc2, ...][, { options }] )

Same as `new_from_spec`, but works with _inline_ description.

```lua
local client = require 'Spore'.new_from_string [[
{
    "base_url" : "http://smolder.parrot.org",
    "name" : "smolder",
    "methods" : {
        "upload" : {
            "path" : "/app/projects/process_add_report/:project_id",
            "method" : "POST",
            "form-data" : {
                "architecture"  : ":architecture",
                "platform"      : ":platform",
                "tags"          : ":tags",
                "comments"      : ":comments",
                "username"      : ":username",
                "password"      : ":password",
                "project_id"    : ":project_id",
                "report_file"   : "@:report_file"
            },
            "required_params" : [
                "project_id",
                "report_file",
                "username",
                "password"
            ],
            "optional_params" : [
                "architecture",
                "platform",
                "tags",
                "comments"
            ],
            "expected_status" : [ 302 ]
        }
    }
}
]]

local r = client:upload{
    tags         = 'linux, i686-linux-gnu-thread-multi, lua, 5.1',
    comments     = 'experiment with lua-Spore',
    username     = 'parrot-autobot',
    password     = 'qa_rocks',
    project_id   = 7,
    report_file  = 'test_lua51.tar.gz',
}
print(r.body)
```

#### new_from_lua( desc [, { options }] )

Instanciate a ReST client from a Lua table.

The optional table `options` allows to overwrite some parameters
of the description (see `new_from_spec`).

```lua
local client = require 'Spore'.new_from_lua{
    base_url = 'http://services.org/restapi/',
    methods = {
        get_info = {
            path = '/show',
            method = 'GET',
        },
        get_user_info = {
            path = '/show',
            method = 'GET',
            required_params = {
                'user',
            },
        },
    },
}

local r = client:get_user_info{ user = 'John' }
```

## Instance Methods

These methods are inherited from `Spore.Core`
(so, do not use these name in API description).

#### enable( middleware [, args] )

Enable a middleware with the optional table `args`.

#### enable_if( cond, middleware [, args] )

Enable a conditional middleware.

```lua
client:enable_if(function (req)
                     return req.env.spore.caller ~= 'get_attachment'
                 end,
                 'Format.JSON')
```

#### reset_middlewares()

Removes all middlewares.

#### http_request( env )

Never directly called.

## Global Variables

These variables allow to do some configuration.

#### debug

The default value is `nil`.

```lua
require 'Spore'.debug = io.stdout
```

#### errors

The default value is `io.stderr`.

#### methname_modifier

The default value is `nil`.

This function allows to alter the name of the method during the instanciation.

```lua
require 'Spore'.methname_modifier = function (name)
    local lowerCamelCase = name:gsub('_(%w)', function (c) return c:upper() end)
    return lowerCamelCase
end
```

# Examples

## GitHub via http

```lua
local Spore = require 'Spore'

local github = Spore.new_from_spec 'https://raw.github.com/SPORE/api-description/master/services/github.json'
github:enable 'Format.JSON'
github:enable('Auth.Basic', {
    username = 'schacon/token',
    password = '6ef8395fecf207165f1a82178ae1b984',
})
local res = github:get_info{format = 'json', username = 'schacon'}
print(res.status)               --> 200
print(res.headers['x-runtime']) --> 126ms
print(res.body.user.name)       --> Scott Chacon
```

## GitHub via https

The HTTPS protocol requires
[LuaSec](http://github.com/brunoos/luasec).

```lua
local Spore = require 'Spore'

local github = Spore.new_from_spec('https://raw.github.com/SPORE/api-description/master/services/github.json', {
    base_url = "https://github.com/api/v2/",
})
github:enable 'Format.JSON'
local res = github:get_info{format = 'json', username = 'schacon'}
print(res.status)               --> 200
print(res.headers['x-runtime']) --> 126ms
print(res.body.user.name)       --> Scott Chacon
```

## CouchDB

This example comes from the book
[CouchDB, The Definitif Guide](http://guide.couchdb.org/draft/api.html).

```lua
local base = 'https://raw.github.com/SPORE/api-description/master/apps/couchdb/'
local couchdb = require 'Spore'.new_from_spec(
    base .. 'server.json',
    base .. 'database.json',
    base .. 'document.json',
    base .. 'design.json',
    { base_url = 'http://127.0.0.1:5984/' })
couchdb:enable_if(function (req) return req.env.spore.caller ~= 'get_attachment' end, 'Format.JSON')

local r = couchdb:get_root()
print(r.body.couchdb)
print(r.body.version)

local r = couchdb:create_db{ db = 'albums' }
assert(r.body.ok)
local r = couchdb:create_db{ db = 'albums' }
print("error", r.body.error)
print("reason", r.body.reason)

local r = couchdb:add_document{
    db = 'albums',
    id = '6e1295ed6c29495e54cc05947f18c8af',
    payload = {
        title = "There is Nothing Left to Lose",
        artist = "Foo Fighters",
    },
}
assert(r.body.ok)
print("id", r.body.id)
print("rev", r.body.rev)

local r = couchdb:get_uuids()
assert(#r.body.uuids == 1)
for i, v in ipairs(r.body.uuids) do print("uuid",i, v) end

local r = couchdb:get_document{
    db = 'albums',
    id = '6e1295ed6c29495e54cc05947f18c8af',
}
print("_id", r.body._id)
print("_rev", r.body._rev)
print("title", r.body.title)
print("artist", r.body.artist)
local rev1 = r.body._rev

local r = couchdb:add_document{
    db = 'albums',
    id = '6e1295ed6c29495e54cc05947f18c8af',
    payload = {
        title = "There is Nothing Left to Lose",
        artist = "Foo Fighters",
        year = 1997,
    },
}
print("error", r.body.error)
print("reason", r.body.reason)

local r = couchdb:add_document{
    db = 'albums',
    id = '6e1295ed6c29495e54cc05947f18c8af',
    payload = {
        _rev = rev1,
        title = "There is Nothing Left to Lose",
        artist = "Foo Fighters",
        year = 1997,
    },
}
assert(r.body.ok)
print("id", r.body.id)
print("rev", r.body.rev)
local rev2 = r.body.rev

local r = couchdb:add_document{
    db = 'albums',
    id = '70b50bfa0a4b3aed1f8aff9e92dc16a0',
    payload = {
        title = "Blackened Sky",
        artist = "Biffy Clyro",
        year = 2002,
    },
}
print("Location", r.headers['location'])
assert(r.body.ok)
print("id", r.body.id)
print("rev", r.body.rev)

local slurp = require 'Spore.Protocols'.slurp
local r = couchdb:add_attachment{
    db = 'albums',
    id = '6e1295ed6c29495e54cc05947f18c8af',
    rev = rev2,
    file = 'api.png',
    content_type = 'image/png',
    payload = slurp'api.png',
}
assert(r.body.ok)
print("id", r.body.id)
print("rev", r.body.rev)

local r = couchdb:get_attachment{
    db = 'albums',
    id = '6e1295ed6c29495e54cc05947f18c8af',
    file = 'api.png',
}
print("Content-Type", r.headers['content-type'])
print("Content-Length", r.headers['content-length'])

local r = couchdb:get_document{
    db = 'albums',
    id = '6e1295ed6c29495e54cc05947f18c8af',
}
print("_id", r.body._id)
print("_rev", r.body._rev)
print("title", r.body.title)
print("artist", r.body.artist)
for k, v in pairs(r.body._attachments) do
    print(k)
    for kk, vv in pairs(v) do print(kk, vv) end
end
```

## with Google & OAuth 1.0

This example uses the service Google URL Shortener.

```lua
local url = require 'socket.url'
local Spore = require 'Spore'
--Spore.debug = io.stdout

local function get_google_keys (scope, keys)
    local oauth = require 'Spore'.new_from_spec 'https://raw.github.com/SPORE/api-description/master/services/googleoauth.json'
    oauth:enable('Auth.OAuth', keys)
    local r1 = oauth:get_request_token{
        scope = scope,
    }
    print("request", r1.body)
    for k, v in r1.body:gmatch'([^&=]+)=([^&=]*)&?' do keys[k] = url.unescape(v) end

    local r2 = oauth:authorize_token{ oauth_token = keys.oauth_token }
    print("authorize", r2.status, r2.headers.location)

    os.execute("x-www-browser " .. r2.headers.location)

    print "enter oauth_verifier:"
    local input = io.stdin:read('*l')
    print("oauth_verifier=]" .. input .. "[")
    keys.oauth_verifier = input

    local r3 = oauth:get_access_token()
    print("access", r3.body)
    for k, v in r3.body:gmatch'([^&=]+)=([^&=]*)&?' do keys[k] = url.unescape(v) end

    keys.oauth_callback_confirmed = nil
    keys.oauth_verifier = nil
    return keys
end


local client = require 'Spore'.new_from_spec 'https://raw.github.com/SPORE/api-description/master/services/googleshortener.json'
client:enable 'Format.JSON'
client:enable('Auth.OAuth', get_google_keys('https://www.googleapis.com/auth/urlshortener', {
    oauth_consumer_key    = '000000000000.apps.googleusercontent.com',
    oauth_consumer_secret = 'XXXXXXXXXXXXXXXXXXXXXXXX',
}))

local r = client:insert{ payload = { longUrl = 'http://www.google.com/' } }
print(r.body.id, r.body.longUrl)

local r = client:list()
print "\nAUTHORIZED\n"
for k, v in pairs(r.body) do
    print(k, v)
end
```
