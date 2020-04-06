local std = require('deviant')
local web = require('web')
local json = require('cjson')

local _M = { version = '0.1' }
local defaults = { socket = '/var/run/docker.sock', APIversion = '/v1.28' }

local API_URL = function (opts)
    local opts = std.mergeTables(defaults, opts)
    return "unix:" .. opts.socket .. ":" .. opts.APIversion
end

local API = { create = [[
{
  "Hostname": "", "Domainname": "", "User": "", "AttachStdin": false, "AttachStdout": true,
  "AttachStderr": true, "Tty": false,
  "OpenStdin": false, "StdinOnce": false,
  "Cmd": {{cmd}},
  "Image": "{{image}}",
  "HostConfig": {
    "Binds": {{binds}},
    "PublishAllPorts": false,
    "Privileged": {{privileged}},
    "Dns": [ "8.8.8.8" ]
  }
}
]]

}

local list = function()
    
    local url = API_URL() .. '/containers/json'
    local res, err = web.request(url, nil, { timeout = 90000 })

    if res then
        if res.status == 200 then
            return res.body
        else
            err = res.body
        end
    end
    return nil, err

end

local create = function(containerArgsTable)

    local defaults = { privileged = 'false', binds = '', cmd = '', image = '' }
    local opts = std.mergeTables(defaults, containerArgsTable)
    opts.cmd = json.encode(opts.cmd)
    opts.binds = json.encode(opts.binds)
    local args = string.gsub(API.create,'{{(.-)}}', opts)

    local url = API_URL() .. '/containers/create'
    local res, err = web.request(url, { method = "POST", headers = { ['Content-Type'] = 'application/json' }, body = args }, { timeout = 90000 })
    if res then
        if res.status == 201 then
            local response = json.decode(res.body)
            return response.Id
        else
            err = res.body
        end
    end
    return nil, err

end

local start = function(id)
    
    local url = API_URL() .. '/containers/' .. id .. '/start'
    local res, err = web.request(url, { method = "POST" }, { timeout = 90000 })

    if res then
        if res.status == 204 then
            return true
        else
            err = res.body
        end
    end
    return nil, err

end

local wait = function(id)

    local url = API_URL() .. '/containers/' .. id .. '/wait'
    local res, err = web.request(url, { method = "POST" }, { timeout = 90000 }) 

    if res then
        if res.status == 200 then
            return true
        else
            err = res.body
        end
    end
    return nil, err

end

local logs = function(id)

    local url = API_URL() .. '/containers/' .. id .. '/logs?stdout=1'
    local res, err = web.request(url, nil, { timeout = 90000 })

    if res then
        if res.status == 200 then
            local body = string.gsub(res.body, '\1%z%z%z%z%z%z.','')
            return body
        else
            err = res.body
        end
    end
    return nil, err

end

local kill = function(id)
    
    local url = API_URL() .. '/containers/' .. id .. '?force=1'
    local res, err = web.request(url, { method = "DELETE" }, { timeout = 90000 })

    if res then
        if res.status == 204 then
            return true
        else
            err = res.body
        end
    end
    return nil, err
    
end

_M.list = list
_M.create = create
_M.start = start
_M.wait = wait
_M.logs = logs
_M.kill = kill

return _M
