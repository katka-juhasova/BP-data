# lua-resty-upstream-worker

## Name

lua-resty-upstream-worker - a consul & dns crowler/pusher for openresty.

## Table of Contents

* [Name](#Name)
* [Status](#Status)
* [Description](#Description)
* [Synopsis](#Synopsis)
* [Methods](#Methods)
    + [new](#new)
    * [forwarder](#forwarder)
    + [run](#run)

## Status

This library is production ready

## Description

This lua library provides a simple way to fetch upstream informations from multiple sources:

1. consul
2. DNS Server

Which run as a worker will keep checking the updates of upstream informations and pushes updates
to target endpoint.

## Synopsis

```lua
#!/usr/local/openresty/bin/resty
local worker = require 'resty.upstream.worker'

local f1 = worker.forwarder({
    host = '127.0.0.1',
    port = 9999,
    path = '/v1/upstreams/consul-foo'
})

local ct, e1 = worker.new({
    type = worker.TYPE_CONSUL,
    host = '127.0.0.1',
    port = 8500,
    name = 'test',   -- uses the health check route
    co = f1
})

local f2 = worker.forwarder({
    host = '127.0.0.1',
    port = 9999,
    path = '/v1/upstreams/dns-bar'
})

local dt, e2 = worker.new({
    type = worker.TYPE_DNS,
    resolver = {
        nameservers = { { '8.8.8.8', 53 }} -- see: https://github.com/openresty/lua-resty-dns#new
    }
    name = 'google.com',
    query = { ... } -- optional: see https://github.com/openresty/lua-resty-dns#query
    co = f2
})

ngx.thread.wait(ct, dt)

--- or

local w1 = {
  source = {
    type = worker.TYPE_DNS,
    resolver = {
        nameservers = { { '8.8.8.8', 53 }} -- see: https://github.com/openresty/lua-resty-dns#new
    }
    name = 'google.com',
    query = { ... } -- optional: see https://github.com/openresty/lua-resty-dns#query
  },
  dest = {
      host = '127.0.0.1',
      port = 9999,
      path = '/v1/upstreams/consul-foo'
  }
}

local thread, err = worker.run(w1)
```

## Methods

### new

New creates a new worker to fetches the backends. Currently supports [consul](https://consul.io) and normal dns records
which repect the `ttl` setting of the dns.

For consul:

```lua
local thread, e1 = worker.new({
    type = worker.TYPE_CONSUL,
    host = '127.0.0.1',
    port = 1999,
    name = 'test',
    co = forwarder
})
```

For DNS:

```lua
local thread, e2 = worker.new({
    type = worker.TYPE_DNS,
    name = 'google.com',
    resolver = {
        nameservers = { { '8.8.8.8', 53 }} -- see: https://github.com/openresty/lua-resty-dns#new
    }
    name = 'google.com',
    query = { ... } -- optional: see https://github.com/openresty/lua-resty-dns#query
    co = forwarder   -- see forwarder
})
```

### forwarder

Create a new http forwarder, it's just a co routine.

```lua
local f2 = worker.forwarder({
    host = '127.0.0.1',
    port = 9999,
    path = '/v1/upstreams/dns-bar'
})
```

### run

Run as a task which combines the `worker` and `forwarder` together:

```
local w1 = {
  source = {
    type = worker.TYPE_DNS,
    resolver = {
        nameservers = { { '8.8.8.8', 53 }} -- see: https://github.com/openresty/lua-resty-dns#new
    }
    name = 'google.com',
    query = { ... } -- optional: see https://github.com/openresty/lua-resty-dns#query
  },
  dest = {
      host = '127.0.0.1',
      port = 9999,
      path = '/v1/upstreams/consul-foo'
  }
}

local thread, err = worker.run(w1)
```

## Author

Zekai "kiddkai" Zheng kiddkai@gmail.com

## Copyright and License

This module is licensed under the BSD license.

Copyright (C) 2012-2016, by Zekai "kiddkai" Zheng kiddkaih@gmail.com. 

All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
