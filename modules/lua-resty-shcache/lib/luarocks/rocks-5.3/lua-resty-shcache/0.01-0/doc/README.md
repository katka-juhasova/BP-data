shcache - simple cache object atop ngx.shared.DICT
==================================================

shcache is an attempt at using ngx.shared.DICT with a caching state machine layed on top

it assumes that you're using some slower external lookup (memc, *sql, redis, etc) that you
want to cache the result of, inside your ngx_lua application code.

it aims at :

* being very simple to use from a user perspective
* minimizing the number of external lookup, notably by caching negative lookups and preventing
external lookup stampeded via the usage of locks
* minimizing the amount of serialization / de-serialization to store/load the in cache
* be as fault-tolerant as possible, in case the external lookup fails ( see: cache load stale )


This is based on the lock mechanism devised by Yichun "agentzh" Zhang, and available here:
http://github.com/agentzh/lua-resty-lock

It assumes that a "locks" shared dict, has been created using the directive
`lua_shared_dict` in your Nginx conf.

This fork of the original version that can be found in https://github.com/mtourne/ngx.shcache and
https://github.com/cloudflare/lua-resty-shcache has been modified to:

* Run in a standard OpenResty installation
* Do not return stale data. If stale data found, then it tries to pull the data of the remote lookup service. It is
  possible to change the behaviour modifying the flag DEFAULT_STALE_BEHAVIOUR. Now, default value is STALE_DATA_CLEAN.
* Use standard logging features.


Usage
=====

First you need to add these lines to your nginx configuration:

```
env MOOCHERIO_URL;
env MOOCHERIO_LOCAL_CACHE_TTL;
env MOOCHERIO_AUTH_TOKEN;
...
http {
    lua_shared_dict cache_dict 1m;
    lua_shared_dict locks 1m;
    ...

```

This example shows how to use the Reputation and Abuse API service of Moocher.io to test if the IP of the client is
in any of the blacklists. If so, then the IP is pulled from remote moocher.io lookup service and cached locally
for the Time To Live given.

For example to filter the access to a folder:
```
    server {
        listen 80;
        lua_code_cache on;
        error_log /dev/stderr debug;

        # Sample access filter to static content
        location /static/ {
            alias static/;
            access_by_lua_file      "shcache_filter.lua";
            resolver 8.8.8.8;       # use Google's open DNS server for an example
        }
```

The shcache_filter.lua file looks like this:

```
local shcache = require("resty.shcache")
local http    = require("resty.http")

local moocher_url  = os.getenv("MOOCHERIO_URL") .. "/badip/"
local cache_ttl    = tonumber(os.getenv("MOOCHERIO_LOCAL_CACHE_TTL"))
local x_auth_token = os.getenv("MOOCHERIO_AUTH_TOKEN")

local all_headers = {}

if x_auth_token then
    all_headers = { ["X-Auth-Token"] = x_auth_token }
end

local function load_from_cache(key)

    -- closure to perform external lookup to moocher.io services
    local lookup = function ()

        local httpc = http.new()
              local res, err = httpc:request_uri(moocher_url .. key,  {
                method = "GET",
                ssl_verify = false,
                headers = all_headers
              })

        -- Something went wrong...
        if not res then
          ngx.say("failed to request: ", err)
          return nil, err
        end

        local status = tonumber(res.status)

        ngx.log(ngx.DEBUG, status)

        if status == 200 then
          return 200, nil
        else
          return nil, nil
        end
    end

    local moocherio_table = shcache:new(
        ngx.shared.cache_dict,
        { external_lookup = lookup
        },
        { positive_ttl = cache_ttl,            -- cache good data for 10s
          negative_ttl = cache_ttl,            -- cache failed lookup for 3s
          actualize_ttl = 0,                   -- do not cache updates
          name = 'moocherio',                  -- "named" cache, useful for debug / report
        }
    )

    local from_local, from_remote = moocherio_table:load(key)

    if from_local then
        if from_remote then
            -- cache_status == "HIT" (or "STALE")
            ngx.log(ngx.DEBUG, "Data at local for sure. CACHE HIT")
            return ngx.exit(ngx.HTTP_FORBIDDEN)
        else
            -- cache_status == "MISS"
            ngx.log(ngx.DEBUG, "No data at local but there is at remote. CACHE MISS (valid data)")
            return ngx.exit(ngx.HTTP_FORBIDDEN)
        end
    else
        if from_remote then
            -- cache_status == "HIT_NEGATIVE"
            ngx.log(ngx.DEBUG, "Negative data at local and I don't know at remote. CACHE HIT NEGATIVE")
        else
            -- cache_status == "NO_DATA"
            ngx.log(ngx.DEBUG, "No data at local and there is at remote. CACHE MISS (bad data)")
        end
    end

end

local ip = ngx.var.remote_addr
load_from_cache(ip)
```

Methods
=======

new
---

`syntax: cache_obj = shcache:new(ngx.shared.DICT, callbacks, opts?)`

Creates an shcache object which implements the caching state machine in the attached documents

`ngx.shared.DICT` is the shared dictionnary (declared in Nginx conf by `lua_shared_dict` directive) to use

`callbacks.external_lookup` is the only required function, it's the closure necessary to lookup data. It should return the value if one exists, and optionally an error string to be logged, and/or an optional TTL value which overrides the positive_ttl option when saving a positive lookup.

`callbacks.encode` and `callbacks.decode` are optional (default to identity), if you intend to store a complex
Lua type (tables for instance), they should be declared as ngx.shared.DICT can only store text.

The `opts` table accepts the following options :

* `opts.positive_ttl`
save a valid external loookup for, in seconds
* `opts.positive_ttl`
save a invalid loookup for, in seconds
* `opts.actualize_ttl`
re-actualize a stale record for, in seconds
* `opts.lock_options`
set option to lock see : http://github.com/agentzh/lua-resty-lock for more details.
* `opts.name`
if shcache object is named, it will automatically register itself in ngx.ctx.shcache (useful for logging).

load
----

`syntax: data, from_cache = shcache:load(key)`

Use key to load data from cache, if no cache is available `callbacks.external_lookup` will be called

if data is available from cache `callbacks.decode` will be called before returning the data


Author
======

Matthieu Tourne <matthieu.tourne@gmail.com>
Rajeev Sharma  <rajeev@cloudflare.com>
John Graham Cumming <john@cloudflare.com>

Luarocks packaging and extra features by Logroñoide <logronoide@protonmail.com>

Copyright and License
=====================

This module is licensed under the BSD license.

Copyright (C) 2016, by MoocherIO SL.
Copyright (C) 2013-2014, by CloudFlare Inc.

All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

* Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
