local std = require('deviant')

local _M = { version = "0.2.4" }

local url = {}

url.parse = function(str)
    
    local url = {}
    url.scheme, url.host, url.port, url.path, url.query = string.match(str,'(https?)://([^:/]+):?([^/]*)(/?[^?]*)%??(.*)')
    if not url.scheme then
        url.scheme, url.socket, url.path, url.query = string.match(str, '(unix):(/[^%:]+):(/?[^?]*)%??(.*)')
        url.path = 'http:' .. url.path
    end
    if url.path == '' then url.path = '/' end
    url.port = tonumber(url.port)
    if url.query == '' then url.query = nil end
    return url

end

url.escape = function(str)

   if (str) then
     str = string.gsub (str, "\n", "\r\n")
     str = string.gsub (str, "([^%w %-%_%.%~%%])",
         function (c) return string.format ("%%%02X", string.byte(c)) end)
     str = string.gsub (str, " ", "+")
   end
   return str    

end

url.build = function (url)

    local urlString = ''
    if url.scheme then
        if url.scheme == 'unix' and url.socket then
            urlString = url.scheme .. ':' .. url.socket
            -- don't forget to remove that 'http:' part from the path
            if url.path then urlString = urlString .. ':' .. string.sub(url.path,6) end
            if url.query then urlString = urlString .. '?' .. url.query end
        else
            if url.host then urlString = url.scheme .. '://' .. url.host end
            if url.port then urlString = urlString .. ':' .. url.port end
            if url.path then urlString = urlString .. url.path end
            if url.query then urlString = urlString .. '?' .. url.query end
        end 
    else
        urlString = nil
    end
    return urlString

end

local function newAPI()
    
    local api
    api  = {
        actions = { ['nop'] = { action = function () end, pattern = '' } },
        process = function(uri)
            for name, action in pairs(api.actions) do
                if string.match(uri, action.pattern) then
                    local args = { string.match(uri, action.pattern) }
                    if table.unpack then
                        api.actions[name].action(table.unpack(args))
                    else
                        api.actions[name].action(unpack(args))
                    end
                    -- since we got our match we want to 
                    -- stop processing
                    break
                end
            end
        end   
    }
    return api

end

local function requestResty(request, connectionOpts)

    local http = require("resty.http")
    local httpc = http.new()
    httpc:set_timeout(connectionOpts.timeout)

    local ok, err 
    if request.scheme ~= 'unix' then 
        ok, err = httpc:connect(connectionOpts.address, connectionOpts.port)
        if request.scheme == 'https' then
            httpc:ssl_handshake(nil, request.headers['Host'], request.ssl_verify)
        end
    else
        ok, err = httpc:connect(connectionOpts.address)
    end
    if not ok then return nil, err end

    local res, err = httpc:request(request)
    local results = {}

    if res then 
        if res.has_body then 
            results.body = res:read_body() 
        end
        results.status = res.status
        results.headers = res.headers
        local ok, err = httpc:set_keepalive()
        return results
    end    
    return nil, err

end

local function requestSocket(request, timeout)

    local http, unix
    local ltn12 = require('ltn12')

    if request.scheme == 'https' then
        http = require('ssl.https')
    else
        http = require('socket.http')
    end
    if request.scheme == 'unix' then 
        unix = require('socket.unix') 
        request.create = unix
    end

    http.TIMEOUT = timeout -- this one should be in seconds
    local body = {}
    request.sink =  ltn12.sink.table(body)

    if #request.body > 0 then 
        request.headers['content-length'] = string.len(request.body) 
        request.source = ltn12.source.string(request.body)
    end

    local result, status, headers, statusLine = http.request(request)
        
    if result == 1 then
        return { body = table.concat(body), status = status, headers = headers }
    else
        return nil, status
    end

end

local function request(uri, httpOpts, timeout)
 
    local timeout = timeout or 1000 -- default timeout is 1 second
    local port = 80 -- default port (will be changed to 443 if the scheme is https, also you can override this in the uri)
    local server -- the actual server to connect to

    -- These are the defaults if no httpOpts table provided in the args.
    -- Even if there is one, but, say, it lacks the method field, then GET
    -- method will be used.
    local httpDefaults = { method = "GET", body = "", headers = {}, ssl_verify = false }

    local parsedUrl = url.parse(uri)

    if parsedUrl.scheme == 'unix' then
        server = 'unix:' .. parsedUrl.socket
        --[[ 'localhost' is a reasonable default for the Host header
             when connecting to a unix socket. Anyways it can be overriden
             in the httpOpts table                  ]]--
        httpDefaults.headers['Host'] = 'localhost'
    else
        server = parsedUrl.host 
        httpDefaults.headers['Host'] = parsedUrl.host
        if parsedUrl.port then 
            port = parsedUrl.port
        elseif parsedUrl.scheme == 'https' then 
            port = 443 
        end
    end

    httpDefaults.scheme = parsedUrl.scheme
    httpDefaults.path = parsedUrl.path
    httpDefaults.query = parsedUrl.query
    local httpOpts = std.mergeTables(httpDefaults, httpOpts)

    if std.moduleAvailable('resty.http') then    

        local results, err = requestResty(httpOpts, { port = port, timeout = timeout, address = server })
        return results, err
    
    elseif std.moduleAvailable('socket.http') then
    
        httpOpts.url = uri 
        if httpOpts.scheme == 'unix' then 
            httpOpts.url = nil
            httpOpts.host = parsedUrl.socket
        end
        local results, err = requestSocket(httpOpts, timeout/1000)
        return results, err

    end

end

_M.url = url
_M.request = request
_M.newAPI = newAPI

return _M

