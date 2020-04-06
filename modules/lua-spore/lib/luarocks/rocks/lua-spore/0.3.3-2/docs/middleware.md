
# Spore.Middleware

---

## Interface

A middleware must use the namespace `Spore.Middleware`
and follow this caveat:

```lua
local m = {}

function m:call (req)
    ... something useful
end

return m
```

## Spore.Middleware.Auth.AWS

This middleware implements the authentication for Amazon Web Services, see the
[ref doc](http://docs.amazonwebservices.com/AmazonS3/latest/dev/index.html?RESTAuthentication.html).

This middleware requires [luacrypto](http://mkottman.github.io/luacrypto/).

This middleware should be loaded as the last middleware,
because it directly sends the request.

```lua
local client = require 'Spore'.new_from_spec('amazons3.json', {
    base_url = 'http://s3-eu-west-1.amazonaws.com',  -- the default is http://s3.amazonaws.com
})
client:enable('Parameter.Default', {
    bucket = 'mybucket',
})
client:enable('Auth.AWS', {
    aws_access_key = '0PN5J17HBGZHT7JJ3X82',
    aws_secret_key = 'uV3F3YluFJax1cknvbcGwgjvx4QpvB+leU8dUj2o',
})
```

## Spore.Middleware.Auth.Basic

This middleware adds a header `authorization` in the request.

```lua
client:enable('Auth.Basic', {
    username = 'schacon/token',
    password = '6ef8395fecf207165f1a82178ae1b984',
})
```

## Spore.Middleware.Auth.Bearer

This middleware adds a header `authorization` in the request.

```lua
client:enable('Auth.Bearer', {
    bearer_token = 'vF9dft4qmT',
})
```

## Spore.Middleware.Auth.DataPublica

This middleware implements the authentication for
[DataPublica](http://www.data-publica.com/content/api/).

This middleware requires [luacrypto](http://mkottman.github.io/luacrypto/).

This middleware should be loaded as the last middleware,
because it directly sends the request.

```lua
local client = Spore.new_from_spec 'https://raw.github.com/SPORE/api-description/master/services/datapublica.json'
client:enable 'Format.JSON'
client:enable('Auth.DataPublica', {
    key      = '356a192c7813b04c54574d18c28d46e6395428ab',
    password = '30d87add92e7b27ce4',
})
```

## Spore.Middleware.Auth.Digest

This middleware adds a header `authorization` in the request

The `nonce` retrieved in the response to the first request is stored
and used by all following requests.

This middleware requires [luacrypto](http://mkottman.github.io/luacrypto/).

```lua
client:enable('Auth.Digest', {
    username = 'Mufasa',
    password = 'Circle Of Life',
})
```

## Spore.Middleware.Auth.OAuth

This middleware adds a header `authorization` in the request.

This middleware requires [luacrypto](http://mkottman.github.io/luacrypto/).

This middleware should be loaded as the last middleware,
because it directly sends the request.

```lua
client:enable('Auth.OAuth', {
    realm                  = 'Example', -- optional
    oauth_consumer_key     = 'key',
    oauth_consumer_secret  = 'secret',
    oauth_token            = 'accesskey',
    oauth_token_secret     = 'accesssecret',
    oauth_signature_method = 'HMAC-SHA1',
})
```

## Spore.Middleware.Format.JSON

This middleware encodes the parameter `payload`
and decodes the body of the response.

This middleware adds the header `accept`
and the header `content-type` when payload,
with the value `application/json`.

```lua
client:enable 'Format.JSON'
```

## Spore.Middleware.Format.XML

This middleware encodes the parameter `payload`
and decodes the body of the response.

This middleware adds the header `accept`
and the header `content-type` when payload,
with the value `text/xml`.

This middleware requires
[LuaExpat](http://www.keplerproject.org/luaexpat/).

```lua
client:enable 'Format.XML'
```lua

```lua
client:enable('Format.XML', {
    indent      = '  ',
    key_attr    = {
        tagname = attrname,
        ...
    },
},
```

The function `to_xml( table [, options] )` is also exported
by this module.

```lua
local to_xml = require 'Spore.Middleware.Format.XML'.to_xml

print(to_xml(payload, {
    indent      = '  ',
    key_attr    = {
        tagname = attrname,
        ...
    },
}))
```

## Spore.Middleware.Format.YAML

This middleware encodes the parameter `payload`
and decodes the body of the response.

This middleware adds the header `accept`
and the header content-type when `payload`
, with the value `text/x-yaml`.

This middleware requires
[LYAML](http://github.com/gvvaughan/lyaml/).

```lua
client:enable 'Format.YAML'
```

## Spore.Middleware.Parameter.Default

This middleware set some parameters with default value.

```lua
client:enable('Parameter.Default', {
    state = 'open',
    ...
})
```

## Spore.Middleware.Parameter.Force

This middleware forces some parameters.

```lua
client:enable('Parameter.Force', {
    format = 'json',
    ...
})
```

## Spore.Middleware.Proxy.Basic

This middleware handles HTTP proxy.

```lua
client:enable('Proxy.Basic', {
    proxy    = 'http://proxy.myorg:8080',
    username = 'john',      -- optional
    password = 's3kr3t',    -- optional
})
```

```lua
client:enable 'Proxy.Basic'     -- uses HTTP_PROXY=http://john:s3kr3t@proxy.myorg:8080
```

## Spore.Middleware.Cache

This middleware supplies a local cache (implemented with a weak table).

```lua
client:enable 'Cache'
```

Note: This middleware uses only URL as unique key.

## Spore.Middleware.DoNotTrack

This middleware adds a header `x-do-not-track`
with the value `1` in the request.

```lua
client:enable 'DoNotTrack'
```

## Spore.Middleware.Logging

This middleware registers a logger in `env.sporex.logger`
for use by others middlewares.

This middleware requires
[LuaLogging](http://www.keplerproject.org/lualogging/).

```lua
require 'logging.file'

client:enable('Logging', {
    logger = logging.file 'test%s.log'
})
```

## Spore.Middleware.Mock

This middleware allows to register a set of couple (condition, response).

```lua
rules = {
    function (req) return req.method == 'HEAD' end,
    function (req) return { status = 404 } end,

    'pattern_in_url', -- shortcut for: function (req) return req.url:match 'pattern_in_url' end
    function (req) return { status = 401 } end,
}
client:enable('Mock', rules)
```

## Spore.Middleware.Redirection

This middleware handles the header `location` in the response.

```lua
client:enable 'Redirection'
```

## Spore.Middleware.Runtime

This middleware adds a header `x-spore-runtime` (unit is seconds)
in the response.

```lua
client:enable 'Runtime'
...
print(response.headers['x-spore-runtime']
```

## Spore.Middleware.UserAgent

This middleware overloads the header `useragent` in the request.

```lua
client:enable('UserAgent', {
    useragent = 'Mozilla/5.0'
})
```
