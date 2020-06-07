
# Rotas

---

# Manual

## The instanciation : `app = Rotas([ table ])`

The instanciation of a `dispatcher` is done by the call of `Rotas`
with an optional table parameter.

## The registration : `app.METH[matcher] = function`

The allowed HTTP methods are stored in the array `http_methods` (which contains
by default : `DELETE`, `HEAD`, `GET`, `OPTIONS`, `PATCH`, `POST`, `PUT`
and `TRACE`). The pseudo method `ALL` could be also used.

The `matcher` is typically an instance of [Silva](https://fperrad.frama.io/lua-Silva).

## The matching : `fn, capture = app(METH, uri)`

If a pattern matches the `uri` for the given HTTP method, the registered function
is returned, plus the parameters captured by the matcher.

If no match, `nil` is returned.

# Examples

## Hello, World

First, the *app* created with **Rotas**

```lua
-- hello.lua

local uri = require'Silva.template'
local rotas = require'Rotas'
local app = rotas()

app.GET[uri'/hello'] = function ()
    return "Hello, World"
end

app.GET[uri'/hello{/name}'] = function (params)
    return "Hello, " .. params.name or ''
end

return app
```

Here, the `nginx.conf` used by an [OpenResty](https://openresty.org/) server.

```lua
worker_processes  1;

events {
    worker_connections 1024;
}

http {
    server {
        listen 8080;

        location /hello {
            content_by_lua_block {

                local fn, capture = require'hello'(ngx.req.get_method(), ngx.var.request_uri)
                if not fn then
                    ngx.status = ngx.HTTP_NOT_FOUND
                else
                    ngx.status = ngx.HTTP_OK
                    ngx.header['Content-Type'] = 'text/plain'
                    ngx.say(fn(capture))
                end

            }
        }
    }
}
```

And now, some tests:

```
    $ curl "http://localhost:8080/hello"
    Hello, World
    $ curl "http://localhost:8080/hello/bob"
    Hello, bob
```

## a calculator

First, the service `calc` created with **Rotas**.

The parameters are validated by [lua-LIVR](https://fperrad.frama.io/lua-LIVR).

```lua
-- calc.lua

local livr = require'LIVR.Validator'

local function livr_helper (spec, fn)
    local validator = livr.new(spec)
    return function (capture)
        local params, err = validator:validate(capture)
        if err then
            return { errmsg = err }
        else
            return fn(params)
        end
    end
end

local uri = require'Silva.template'
local rotas = require'Rotas'
local calc = rotas()

calc.GET[uri'/calc/mul{?x,y}'] = livr_helper({
    x = { 'required', 'decimal' },
    y = { 'required', 'decimal' },
}, function (params)
    return { ret = params.x * params.y }
end)

calc.GET[uri'/calc/div{?x,y}'] = livr_helper({
    x = { 'required', 'decimal' },
    y = { 'required', 'decimal' },
}, function (params)
    if params.y == 0 then
        return { errmsg = "Division by zero" }
    end
    return { ret = params.x / params.y }
end)

return calc
```

Here, the specific [Xavante](https://keplerproject.github.io/xavante/) part.

The responses are formated in JSON by [dkjson](http://dkolf.de/src/dkjson-lua.fsl/home).

```lua
-- calc_xavante.lua

local xavante = require'xavante'
local encode = require'dkjson'.encode

local function json_fmt (req, res, obj, status)
    if status then
        res.statusline = 'HTTP/1.1 ' .. status
        obj = obj or { errmsg = status }
    elseif obj and obj.errmsg then
        res.statusline = 'HTTP/1.1 400 Bad Request'
    elseif req.cmd_mth == 'POST' then
        res.statusline = 'HTTP/1.1 201 Created'
    else
        res.statusline = 'HTTP/1.1 200 OK'
    end
    if obj then
        res.headers['Content-Type'] = 'application/json'
        res.content = encode(obj)
    end
    return res
end

local function handler (req, res, router, formatter)
    print(req.cmd_mth, req.cmd_url)
    local fn, capture = router(req.cmd_mth, req.cmd_url)
    if not fn then
        return formatter(req, res, nil, '404 Not Found')
    else
        return formatter(req, res, fn(capture))
    end
end

xavante.HTTP{
    server = { host = '*', port = 8080 },
    defaultHost = {
        rules = {
            {
                match = '^/calc/',
                with = function (req, res) return handler(req, res, require'calc', json_fmt) end,
            }
        }
    }
}

xavante.start()
```

And now, some tests with a server:

```
    $ curl "http://localhost:8080/calc/div?x=3.0&y=2.0"
    {"ret":1.5}
    $ curl "http://localhost:8080/calc/div?x=3.0&y=0.0"
    {"errmsg":"Division by zero"}
    $ curl "http://localhost:8080/calc/div?x=a&y=b"
    {"errmsg":{"y":"NOT_DECIMAL","x":"NOT_DECIMAL"}}
    $ curl "http://localhost:8080/calc/div"
    {"errmsg":{"y":"REQUIRED","x":"REQUIRED"}}
    $ curl "http://localhost:8080/calc/idiv"
    {"errmsg":"404 Not Found"}
    $ curl "http://localhost:8080/calc/div?z=top"
    {"errmsg":"404 Not Found"}
```

But, unit tests of the service are also feasible:
```lua
-- test_calc.lua

require 'Test.More'

plan(10)

local calc = require'calc'

local fn, capture, res
fn, capture = calc('GET', '/calc/div?x=3.0&y=2.0')
res = fn(capture)
is( res.ret, 1.5 )

fn, capture = calc('GET', '/calc/div?x=3.0&y=0.0')
res = fn(capture)
is( res.errmsg, "Division by zero" )

fn, capture = calc('GET', '/calc/div?x=a&y=b')
res = fn(capture)
is( res.errmsg.x, 'NOT_DECIMAL' )
is( res.errmsg.y, 'NOT_DECIMAL' )

fn, capture = calc('GET', '/calc/div')
res = fn(capture)
is( res.errmsg.x, 'REQUIRED' )
is( res.errmsg.y, 'REQUIRED' )

fn, capture = calc('GET', '/calc/idiv')
nok( fn )
nok( capture )

fn, capture = calc('GET', '/calc/div?z=top')
nok( fn )
nok( capture )
```

## two levels of dispatch

A first level of dispatch is done between the two previous services `hello` and `calc`.

Here, the library [lua-http](https://github.com/daurnimator/lua-http)
is used in order to build a server.

```lua
-- 2level_http.lua

local http_server = require'http.server'
local http_headers = require'http.headers'
local encode = require'dkjson'.encode
local re = require'Silva.lua'
local rotas = require'Rotas'
local app = rotas()

local function json_fmt (stream, req_method, obj, status)
    local res_headers = http_headers.new()
    res_headers:append('access-control-allow-origin', '*')
    if status then
        res_headers:append(':status', status)
    elseif obj and obj.errmsg then
        res_headers:append(':status', '400')    -- Bad Request
    elseif req_method == 'POST' then
        res_headers:append(':status', '201')    -- Created
    else
        res_headers:append(':status', '200')    -- OK
    end
    if obj then
        res_headers:append('content-type', 'application/json')
        stream:write_headers(res_headers, false)
        stream:write_body_from_string(encode(obj))
    else
        stream:write_headers(res_headers, true)
    end
end

app.ALL[re'^/calc/'] = function (stream, req_headers)
    local req_method = req_headers:get':method'
    local req_path = req_headers:get':path'
    print(req_method, req_path)
    local fn, capture = require'calc'(req_method, req_path)
    if not fn then
        json_fmt(stream, req_method, { errmsg = '404 Not Found' }, '404')
    else
        json_fmt(stream, req_method, fn(capture))
    end
end

app.ALL[re'^/hello'] = function (stream, req_headers)
    local req_method = req_headers:get':method'
    local req_path = req_headers:get':path'
    print(req_method, req_path)
    local fn, capture = require'hello'(req_method, req_path)
    local res_headers = http_headers.new()
    if not fn then
        res_headers:append(':status', '404')
        stream:write_headers(res_headers, true)
    else
        local txt = fn(capture)
        res_headers:append(':status', '200')
        res_headers:append('content-type', 'text/plain')
        stream:write_headers(res_headers, false)
        stream:write_body_from_string(txt)
    end
end

local myserver = http_server.listen{
    host = 'localhost',
    port = 8080,
    onstream = function (server, stream)
        local req_headers = stream:get_headers()
        local hdl = app(req_headers:get':method', req_headers:get':path')
        if not hdl then
            local res_headers = http_headers.new()
            res_headers:append(':status', '404')
            stream:write_headers(res_headers, true)
        else
            hdl(stream, req_headers)
        end
    end,
    onerror = function (server, context, op, err, errno)
        local msg = op .. ' on ' .. tostring(context) .. ' failed'
        if err then
            msg = msg .. ': ' .. tostring(err)
        end
        io.stderr:write(msg, "\n")
    end,
}

myserver:listen()
io.stderr:write(string.format("Now listening on port %d\n", select(3, myserver:localname())))
myserver:loop()
```

## WebDAV extension

The WebDAV methods could be easily added to **Rotas**.

```lua
local m = require'Rotas'

m.http_methods = {
    'DELETE', 'GET', 'HEAD', 'OPTIONS', 'PATCH', 'POST', 'PUT', 'TRACE',        -- HTTP
    'COPY', 'LOCK', 'MKCOL', 'MOVE', 'PROPFIND', 'PROPPATCH', 'UNLOCK',         -- WebDAV
}

return m
```
