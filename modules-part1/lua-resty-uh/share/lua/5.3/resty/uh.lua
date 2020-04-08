local pl_utils = require("pl.utils")
local json = require("cjson.safe")
local stream_sock = ngx.socket.tcp
local log = ngx.log
local ERR = ngx.ERR
local WARN = ngx.WARN
local DEBUG = ngx.DEBUG
local sub = string.sub
local re_find = ngx.re.find
local re_gmatch = ngx.re.gmatch
local new_timer = ngx.timer.at
local shared = ngx.shared
local debug_mode = ngx.config.debug
local concat = table.concat
local tonumber = tonumber
local tostring = tostring
local ipairs = ipairs
local ceil = math.ceil
local spawn = ngx.thread.spawn
local wait = ngx.thread.wait
local pcall = pcall

local _M = {
    _VERSION = "0.0.5"
}

if not ngx.config or not ngx.config.ngx_lua_version or ngx.config.ngx_lua_version < 9005 then
    error("ngx_lua 0.9.5+ required")
end

local ok, upstream = pcall(require, "ngx.upstream")
if not ok then
    error("ngx_upstream_lua module required")
end

local shm_hc = ngx.shared.healthcheck
if not shm_hc then
    error("shared dict 'healthcheck' mustbe set")
end

local ok, new_tab = pcall(require, "table.new")
if not ok or type(new_tab) ~= "function" then
    new_tab = function(narr, nrec)
        return {}
    end
end

local set_peer_down = upstream.set_peer_down
local get_primary_peers = upstream.get_primary_peers
local get_backup_peers = upstream.get_backup_peers
local get_upstreams = upstream.get_upstreams

-- local upstream_checker_statuses = {}

-- local ha_flag = false
local hacheck_shm_key = "ha_flag"

local function warn(...)
    log(WARN, "healthcheck: ", ...)
end

local function errlog(...)
    log(ERR, "healthcheck: ", ...)
end

local function debug(...)
    -- print("debug mode: ", debug_mode)
    if debug_mode then
        log(DEBUG, "healthcheck: ", ...)
    end
end

-- func gen the exclude_lists's record's key in SHM
local function gen_ex_key(name)
    local ex_pre_fix = "ex:"
    if (not name) or (type(name) ~= "string") then
        local msg = "gen exclude_list's key upstream must given"
        errlog(msg)
        return nil, msg
    end
    return ex_pre_fix .. name
end

-- func set the exclude_list record into shm

local function setin_ex_lists(name, ttl)
    if not name or type(name) ~= "string" then
        errlog("upstream name must be given")
        return nil, "name must be given"
    end

    local key = gen_ex_key(name)
    if not key then
        return nil, "gen exclude_list key error"
    end
    ttl = tonumber(ttl) or 0

    local ex_value = "ex"
    local ok, err = shm_hc:set(key, ex_value, ttl)
    if not ok then
        errlog("set key to shm failed", key, err)
        return nil, err
    end
    return true
end

-- func if the upstream name in exclude_lists at shm
-- while the first return as "nil",it has mean then record not in the shm
-- so if want to check the fucntion worked,should check the second return first
-- ex:
-- local ok,err = in_ex_list(name)
-- if err then
--     -- log something
-- end
-- if ok then
--     -- got the record
-- end

local function in_ex_lists(name)
    if not name or type(name) ~= "string" then
        errlog("upstream name must be given")
        return nil, "name must be given"
    end
    local key = gen_ex_key(name)
    if not key then
        errlog "gen exclude_list key error"
        return nil, "gen exclude_list key error"
    end
    local res, err = shm_hc:get(key)
    if not res then
        if err then
            errlog(err)
        end
        return nil
    end
    return true
end

-- func del the upstream name in exclude_lists at shm
local function del_ex_lists(name)
    if not name or type(name) ~= "string" then
        errlog("upstream name must be given")
        return nil, "name must be given"
    end
    local key = gen_ex_key(name)
    if not key then
        return nil, "gen exclude_list key error"
    end

    shm_hc:delete(key)

    return true
end

local function ha_status(status)
    if not status then
        local ok, err = shm_hc:set(hacheck_shm_key, "Slaver")
        if not ok then
            errlog("set ha_flag failed", err)
        end
        return
    end

    if type(status) == "boolean" then
        local ok, err = shm_hc:set(hacheck_shm_key, "Master")
        if not ok then
            errlog("set ha_flag failed", err)
        end
    else
        local ok, err = shm_hc:set(hacheck_shm_key, "Disabled")
        if not ok then
            errlog("set ha_flag failed", err)
        end
    end
end

local function gen_peer_key(prefix, u, is_backup, id)
    if is_backup then
        return prefix .. u .. ":b" .. id
    end
    return prefix .. u .. ":p" .. id
end

local function set_peer_down_globally(ctx, is_backup, id, value)
    local u = ctx.upstream
    local dict = ctx.dict
    local ok, err = set_peer_down(u, is_backup, id, value)
    if not ok then
        errlog("failed to set peer down: ", err)
    end

    if not ctx.new_version then
        ctx.new_version = true
    end

    local key = gen_peer_key("d:", u, is_backup, id)
    local ok, err = dict:set(key, value)
    if not ok then
        errlog("failed to set peer down state: ", err)
    end
end

-- add a new optional input arg:gray,a boolean type arg indicate the failed from gray_require
local function peer_fail(ctx, is_backup, id, peer, gray)
    debug("peer ", peer.name, " was checked to be not ok")

    local u = ctx.upstream
    local dict = ctx.dict
    local gray_fails = ctx.fall + 1

    local key = gen_peer_key("nok:", u, is_backup, id)
    local fails, err = dict:get(key)
    if not fails then
        if err then
            errlog("failed to get peer nok key: ", err)
            return
        end
        if gray then
            fails = gray_fails
        else
            fails = 1
        end

        -- below may have a race condition, but it is fine for our
        -- purpose here.
        local ok, err = dict:set(key, fails)
        if not ok then
            errlog("failed to set peer nok key: ", err)
        end
    else
        if gray then
            fails = gray_fails
        else
            fails = fails + 1
        end

        local ok, err = dict:set(key, fails)
        if not ok then
            errlog("failed to incr peer nok key: ", err)
        end
    end

    if (fails == 1) or (gray == true) then
        key = gen_peer_key("ok:", u, is_backup, id)
        local succ, err = dict:get(key)
        if not succ or succ == 0 then
            if err then
                errlog("failed to get peer ok key: ", err)
                return
            end
        else
            local ok, err = dict:set(key, 0)
            if not ok then
                errlog("failed to set peer ok key: ", err)
            end
        end
    end

    -- print("ctx fall: ", ctx.fall, ", peer down: ", peer.down,
    -- ", fails: ", fails)

    if not peer.down and fails >= ctx.fall then
        warn("peer ", peer.name, " is turned down after ", fails, " failure(s)")
        peer.down = true
        set_peer_down_globally(ctx, is_backup, id, true)
    end
end

local function peer_ok(ctx, is_backup, id, peer)
    debug("peer ", peer.name, " was checked to be ok")

    local u = ctx.upstream
    local dict = ctx.dict

    local key = gen_peer_key("ok:", u, is_backup, id)
    local succ, err = dict:get(key)
    if not succ then
        if err then
            errlog("failed to get peer ok key: ", err)
            return
        end
        succ = 1

        -- below may have a race condition, but it is fine for our
        -- purpose here.
        local ok, err = dict:set(key, 1)
        if not ok then
            errlog("failed to set peer ok key: ", err)
        end
    else
        succ = succ + 1
        local ok, err = dict:incr(key, 1)
        if not ok then
            errlog("failed to incr peer ok key: ", err)
        end
    end

    if succ == 1 then
        key = gen_peer_key("nok:", u, is_backup, id)
        local fails, err = dict:get(key)
        if not fails or fails == 0 then
            if err then
                errlog("failed to get peer nok key: ", err)
                return
            end
        else
            local ok, err = dict:set(key, 0)
            if not ok then
                errlog("failed to set peer nok key: ", err)
            end
        end
    end

    if peer.down and succ >= ctx.rise then
        warn("peer ", peer.name, " is turned up after ", succ, " success(es)")
        peer.down = nil
        set_peer_down_globally(ctx, is_backup, id, nil)
    end
end

-- shortcut error function for check_peer()
local function peer_error(ctx, is_backup, id, peer, ...)
    if not peer.down then
        errlog(...)
    end
    peer_fail(ctx, is_backup, id, peer)
end

local function set_gray_peer(upstream, peer_name, ttl)
    if (not upstream) or (not peer_name) then
        return nil, "upstream name and peer_name mustbe given"
    end
    if type(upstream) ~= "string" or type(peer_name) ~= "string" then
        return nil, "upstream name and peer_name type mustbe string"
    end
    ttl = tonumber(ttl)
    if type(ttl) ~= "number" then
        return nil, "ttl mustbe a number"
    end

    local gray_key_value = "grayed"
    local gray_key = "gray:" .. upstream .. peer_name
    local ok, err = shm_hc:set(gray_key, gray_key_value, ttl)
    if not ok then
        local msg = "set gray key into shm failed" .. (err or "")
        errlog(msg)
        return nil, msg
    end
    return true
end

local function check_peer(ctx, id, peer, is_backup)
    local ok
    local name = peer.name
    local statuses = ctx.statuses
    local req = ctx.http_req

    -- before do a real check,check if the peer in the gray status
    local u = ctx.upstream
    local gray_key = "gray:" .. u .. name
    -- check gray_key if in shm
    local ok = shm_hc:get(gray_key)
    if ok then
        return peer_fail(ctx, is_backup, id, peer, true)
    end

    local sock, err = stream_sock()
    if not sock then
        errlog("failed to create stream socket: ", err)
        return
    end

    sock:settimeout(ctx.timeout)

    if peer.host then
        -- print("peer port: ", peer.port)
        ok, err = sock:connect(peer.host, peer.port)
    else
        ok, err = sock:connect(name)
    end
    if not ok then
        if not peer.down then
            errlog("failed to connect to ", name, ": ", err)
        end
        return peer_fail(ctx, is_backup, id, peer)
    end

    local bytes, err = sock:send(req)
    if not bytes then
        return peer_error(ctx, is_backup, id, peer, "failed to send request to ", name, ": ", err)
    end

    local status_line, err = sock:receive()
    if not status_line then
        peer_error(ctx, is_backup, id, peer, "failed to receive status line from ", name, ": ", err)
        if err == "timeout" then
            sock:close() -- timeout errors do not close the socket.
        end
        return
    end

    if statuses then
        local from, to, err = re_find(status_line, [[^HTTP/\d+\.\d+\s+(\d+)]], "joi", nil, 1)
        if err then
            errlog("failed to parse status line: ", err)
        end

        if not from then
            peer_error(ctx, is_backup, id, peer, "bad status line from ", name, ": ", status_line)
            sock:close()
            return
        end

        local status = tonumber(sub(status_line, from, to))
        if not statuses[status] then
            peer_error(ctx, is_backup, id, peer, "bad status code from ", name, ": ", status)
            sock:close()
            return
        end
    end

    peer_ok(ctx, is_backup, id, peer)
    sock:close()
end

local function check_peer_range(ctx, from, to, peers, is_backup)
    for i = from, to do
        check_peer(ctx, i - 1, peers[i], is_backup)
    end
end

local function check_peers(ctx, peers, is_backup)
    local n = #peers
    if n == 0 then
        return
    end

    local concur = ctx.concurrency
    if concur <= 1 then
        for i = 1, n do
            check_peer(ctx, i - 1, peers[i], is_backup)
        end
    else
        local threads
        local nthr

        if n <= concur then
            nthr = n - 1
            threads = new_tab(nthr, 0)
            for i = 1, nthr do
                if debug_mode then
                    debug("spawn a thread checking ", is_backup and "backup" or "primary", " peer ", i - 1)
                end

                threads[i] = spawn(check_peer, ctx, i - 1, peers[i], is_backup)
            end
            -- use the current "light thread" to run the last task
            if debug_mode then
                debug("check ", is_backup and "backup" or "primary", " peer ", n - 1)
            end
            check_peer(ctx, n - 1, peers[n], is_backup)
        else
            local group_size = ceil(n / concur)
            nthr = ceil(n / group_size) - 1

            threads = new_tab(nthr, 0)
            local from = 1
            local rest = n
            for i = 1, nthr do
                local to
                if rest >= group_size then
                    rest = rest - group_size
                    to = from + group_size - 1
                else
                    rest = 0
                    to = from + rest - 1
                end

                if debug_mode then
                    debug("spawn a thread checking ", is_backup and "backup" or "primary", " peers ", from - 1, " to ", to - 1)
                end

                threads[i] = spawn(check_peer_range, ctx, from, to, peers, is_backup)
                from = from + group_size
                if rest == 0 then
                    break
                end
            end
            if rest > 0 then
                local to = from + rest - 1

                if debug_mode then
                    debug("check ", is_backup and "backup" or "primary", " peers ", from - 1, " to ", to - 1)
                end

                check_peer_range(ctx, from, to, peers, is_backup)
            end
        end

        if nthr and nthr > 0 then
            for i = 1, nthr do
                local t = threads[i]
                if t then
                    wait(t)
                end
            end
        end
    end
end

local function upgrade_peers_version(ctx, peers, is_backup)
    local dict = ctx.dict
    local u = ctx.upstream
    local n = #peers
    for i = 1, n do
        local peer = peers[i]
        local id = i - 1
        local key = gen_peer_key("d:", u, is_backup, id)
        local down = false
        local res, err = dict:get(key)
        if not res then
            if err then
                errlog("failed to get peer down state: ", err)
            end
        else
            down = true
        end
        if (peer.down and not down) or (not peer.down and down) then
            local ok, err = set_peer_down(u, is_backup, id, down)
            if not ok then
                errlog("failed to set peer down: ", err)
            else
                -- update our cache too
                peer.down = down
            end
        end
    end
end

local function check_peers_updates(ctx)
    local dict = ctx.dict
    local u = ctx.upstream
    local key = "v:" .. u
    local ver, err = dict:get(key)
    if not ver then
        if err then
            errlog("failed to get peers version: ", err)
            return
        end

        if ctx.version > 0 then
            ctx.new_version = true
        end
    elseif ctx.version < ver then
        debug("upgrading peers version to ", ver)
        upgrade_peers_version(ctx, ctx.primary_peers, false)
        upgrade_peers_version(ctx, ctx.backup_peers, true)
        ctx.version = ver
    end
end

local function get_lock(ctx)
    local dict = ctx.dict
    local key = "l:" .. ctx.upstream

    -- the lock is held for the whole interval to prevent multiple
    -- worker processes from sending the test request simultaneously.
    -- here we substract the lock expiration time by 1ms to prevent
    -- a race condition with the next timer event.
    local ok, err = dict:add(key, true, ctx.interval - 0.001)
    if not ok then
        if err == "exists" then
            return nil
        end
        errlog('failed to add key "', key, '": ', err)
        return nil
    end
    return true
end

local function do_check(ctx)
    debug("healthcheck: run a check cycle")

    -- check if the master node

    local dict = ctx.dict
    local res, err = dict:get(hacheck_shm_key)
    if res and res == "Slaver" then
        if err then
            return nil, err
        end
        -- this is not master node,skip the health check
        return true
    end
    check_peers_updates(ctx)

    if get_lock(ctx) then
        check_peers(ctx, ctx.primary_peers, false)
        check_peers(ctx, ctx.backup_peers, true)
    end

    if ctx.new_version then
        local key = "v:" .. ctx.upstream
        local dict = ctx.dict

        if debug_mode then
            debug("publishing peers version ", ctx.version + 1)
        end

        dict:add(key, 0)
        local new_ver, err = dict:incr(key, 1)
        if not new_ver then
            errlog("failed to publish new peers version: ", err)
        end

        ctx.version = new_ver
        ctx.new_version = nil
    end
end

local function update_upstream_checker_status(ctx, success)
    local dict = ctx.dict
    local u = ctx.upstream

    if not success then
        cnt = 0
    else
        cnt = 1
    end
    local ok, err = dict:set(u, cnt)
    if not ok then
        errlog("update checker status failed: ", err)
    end
end

local check
check = function(premature, ctx)
    if premature then
        return
    end

    -- check the upstream name in ex_lists or not
    local name = ctx.upstream
    local val, err = in_ex_lists(name)

    if err then
        errlog(err)
    end

    if not val then
        local ok, err = pcall(do_check, ctx)
        if not ok then
            errlog("failed to run healthcheck cycle: ", err)
        end
        update_upstream_checker_status(ctx, true)
    else
        update_upstream_checker_status(ctx, false)
    end

    local ok, err = new_timer(ctx.interval, check, ctx)
    if not ok then
        if err ~= "process exiting" then
            errlog("failed to create timer: ", err)
        end

        update_upstream_checker_status(ctx, false)
        return
    end
end

local function preprocess_peers(peers)
    local n = #peers
    for i = 1, n do
        local p = peers[i]
        local name = p.name

        if name then
            local from, to, err = re_find(name, [[^(.*):\d+$]], "jo", nil, 1)
            if from then
                p.host = sub(name, 1, to)
                p.port = tonumber(sub(name, to + 2))
            end
        end
    end
    return peers
end

function _M.spawn_checker(opts)
    local typ = opts.type
    if not typ then
        return nil, '"type" option required'
    end

    if typ ~= "http" then
        return nil, 'only "http" type is supported right now'
    end

    local http_req = opts.http_req
    if not http_req then
        return nil, '"http_req" option required'
    end

    local timeout = opts.timeout
    if not timeout then
        timeout = 1000
    end

    local interval = opts.interval
    if not interval then
        interval = 1
    else
        interval = interval / 1000
        if interval < 0.002 then -- minimum 2ms
            interval = 0.002
        end
    end

    local valid_statuses = opts.valid_statuses
    local statuses
    if valid_statuses then
        statuses = new_tab(0, #valid_statuses)
        for _, status in ipairs(valid_statuses) do
            -- print("found good status ", status)
            statuses[status] = true
        end
    end

    -- debug("interval: ", interval)

    local concur = opts.concurrency
    if not concur then
        concur = 1
    end

    local fall = opts.fall
    if not fall then
        fall = 5
    end

    local rise = opts.rise
    if not rise then
        rise = 2
    end

    local u = opts.upstream
    if not u then
        return nil, "no upstream specified"
    end

    local ppeers, err = get_primary_peers(u)
    if not ppeers then
        return nil, "failed to get primary peers: " .. err
    end

    local bpeers, err = get_backup_peers(u)
    if not bpeers then
        return nil, "failed to get backup peers: " .. err
    end

    local ctx = {
        upstream = u,
        primary_peers = preprocess_peers(ppeers),
        backup_peers = preprocess_peers(bpeers),
        http_req = http_req,
        timeout = timeout,
        interval = interval,
        dict = shm_hc,
        fall = fall,
        rise = rise,
        statuses = statuses,
        version = 0,
        concurrency = concur
    }

    if debug_mode and opts.no_timer then
        check(nil, ctx)
    else
        local ok, err = new_timer(0, check, ctx)
        if not ok then
            return nil, "failed to create timer: " .. err
        end
    end

    return true
end

local function get_ha_lock(ctx)
    local dict = ctx.dict
    local key = "l:"

    -- the lock is held for the whole interval to prevent multiple
    -- worker processes from sending the test request simultaneously.
    -- here we substract the lock expiration time by 1ms to prevent
    -- a race condition with the next timer event.
    local ok, err = dict:add(key, true, ctx.ha_interval - 0.001)
    if not ok then
        if err == "exists" then
            return nil
        end
        errlog('failed to add key "', key, '": ', err)
        return nil
    end
    return true
end

local function do_ha_check(ctx)
    local flag
    if get_ha_lock(ctx) then
        local cmds = {
            "/usr/sbin/ip -f inet -4 address show bond0",
            "/usr/sbin/ip -f inet -4 address show eth0",
            "/usr/sbin/ip -f inet -4 address show em2",
            "/sbin/ip -f inet -4 address show bond0",
            "/sbin/ip -f inet -4 address show eth0",
            "/sbin/ip -f inet -4 address show em2"
        }

        for i, cmd in ipairs(cmds) do
            if not flag then
                local regex = [[inet\s\d{1,3}.\d{1,3}.\d{1,3}.\d{1,3}\/\d{1,2}]]

                local _, _, ret = pl_utils.executeex(cmd)
                if ret then
                    local f, t = re_find(ret, regex, "mjo")
                    if f then
                        local new_ret = string.sub(ret, t + 1, #ret) or ""
                        local s = re_find(new_ret, regex, "mjo")
                        -- master node
                        if s then
                            flag = true
                        end
                    end
                end
            end
        end

        if not flag then
            errlog("set to slave mode")
        else
            errlog("set to master mode")
        end

        -- update the flag to shm
        ha_status(flag)
        return true
    end
end

-- ha check timer
local ha_check
ha_check = function(premature, ctx)
    if premature then
        return
    end

    local ok, err = pcall(do_ha_check, ctx)
    if not ok then
        errlog("failed to run ha_timer cycle: ", err)
    end

    local ok, err = new_timer(ctx.ha_interval, ha_check, ctx)
    if not ok then
        if err ~= "process exiting" then
            errlog("failed to create ha_timer: ", err)
        end
        return
    end
end

-- main function
function _M.checker(opts)
    -- ha timer
    local ha_interval = tonumber(opts.ha_interval)

    if ha_interval then
        if ha_interval < 10 then
            ha_interval = 10 --set default ha check interval 10 secs
        end

        local ctx = {
            ha_interval = ha_interval,
            dict = shm_hc
        }

        local ok, err = new_timer(0, ha_check, ctx)
        if not ok then
            return nil, "failed to create ha_timer: " .. err
        end
    else
        ha_status("Disabled")
    end

    -- exclude_lists
    local ex_lists = opts.exclude_lists or {}
    if type(ex_lists) ~= "table" then
        errlog('"exclude_lists" type error')
        return nil, '"exclude_lists" type must be table'
    end

    for _, name in ipairs(ex_lists) do
        local ok, err = setin_ex_lists(name)
        if not ok then
            errlog(err)
            return nil, err
        end
    end

    local ups = get_upstreams()
    for _, name in ipairs(ups) do
        -- rewrite the opts.upstream as the new name
        opts["upstream"] = nil
        opts["upstream"] = name

        -- call the former spawn_checker func
        local ok, err = _M.spawn_checker(opts)
        if not ok then
            return nil, err
        end
    end

    return true
end

local function gen_peers_status_info(peers, bits, idx)
    local npeers = #peers
    for i = 1, npeers do
        local peer = peers[i]
        bits[idx] = "        "
        bits[idx + 1] = peer.name
        if peer.down then
            bits[idx + 2] = " DOWN\n"
        else
            bits[idx + 2] = " UP\n"
        end
        idx = idx + 3
    end
    return idx
end

function _M.status_page()
    -- generate an HTML page
    local us, err = get_upstreams()
    if not us then
        return "failed to get upstream names: " .. err
    end

    local n = #us
    local bits = new_tab(n * 20, 0)
    local idx = 1

    -- add ha mode
    local ha_flag = shm_hc:get(hacheck_shm_key)
    if ha_flag ~= "Disabled" then
        if ha_flag == "Master" then
            bits[idx] = "HA Mode: Master\n"
        elseif ha_flag == "Slaver" then
            bits[idx] = "HA Mode: Slaver\n"
            return concat(bits)
        end
        idx = idx + 1
    end

    for i = 1, n do
        if i > 1 then
            bits[idx] = "\n"
            idx = idx + 1
        end

        local u = us[i]

        bits[idx] = "Upstream "
        bits[idx + 1] = u
        idx = idx + 2

        local ncheckers, err = shm_hc:get(u)

        if not ncheckers or ncheckers == 0 then
            bits[idx] = " (NO checkers)"
            idx = idx + 1
        end

        bits[idx] = "\n    Primary Peers\n"
        idx = idx + 1

        local peers, err = get_primary_peers(u)
        if not peers then
            return "failed to get primary peers in upstream " .. u .. ": " .. err
        end

        idx = gen_peers_status_info(peers, bits, idx)

        bits[idx] = "    Backup Peers\n"
        idx = idx + 1

        peers, err = get_backup_peers(u)
        if not peers then
            return "failed to get backup peers in upstream " .. u .. ": " .. err
        end

        idx = gen_peers_status_info(peers, bits, idx)
    end
    return concat(bits)
end

local function render_json(status, msg, err)
    local tb = {}
    tb.status = status
    tb.msg = msg or ""
    tb.err_msg = err or ""
    return json.encode(tb)
end

local function all_status()
    local tb = {}
    local upstreams, err = get_upstreams()
    if not upstreams then
        return render_json("err", nil, "failed to get upstream names: " .. err)
    end

    local ha_flag = shm_hc:get(hacheck_shm_key)
    if not ha_flag then
        return render_json("err", nil, "faild to get ha_flag from shm")
    end
    tb.ha_mode = ha_flag
    if ha_flag == "Slaver" then
        return render_json("ok", tb, err)
    end

    tb.upstreams = {}
    for _, upstream in ipairs(upstreams) do
        local p_peers = get_primary_peers(upstream)
        local b_peers = get_backup_peers(upstream)

        local checked
        local checkers = shm_hc:get(upstream)
        if not checkers or checkers == 0 then
            checked = false
        else
            checked = true
        end

        -- add upstream info to the table
        local up = {}
        up.name = upstream
        up.checked = checked
        up.primary = p_peers
        up.backup = b_peers

        table.insert(tb.upstreams, up)
    end

    return render_json("ok", tb, err)
end

-- fetch all the args once,and set to the upvalue req
local function collect_args(req)
    req.method = ngx.req.get_method()
    req.uri_args = ngx.req.get_uri_args() or false
end

-- valid the req args
local function valid(req)
    local method = req.method
    if method ~= "GET" then
        return nil, "Method not supported"
    end

    local uri_args = req.uri_args
    if uri_args and type(uri_args) ~= "table" then
        return nil, "Request args error"
    end

    for key, value in pairs(uri_args) do
        if type(value) == "table" then
            return nil, "Request args error"
        end
    end
    return true
end

local function api_ex_list(req)
    local uri_args = req.uri_args
    local name = uri_args.u
    local act = uri_args.a
    local ttl = uri_args.ttl or 0

    if type(name) ~= "string" then
        return render_json("err", nil, "Arg 'u' type error")
    end

    if type(act) ~= "string" then
        return render_json("err", nil, "Arg 'a' type error")
    end

    if act ~= "set" and act ~= "del" and act ~= "get" then
        return render_json("err", nil, "Arg 'a' action error")
    end

    if type(tonumber(ttl)) ~= "number" then
        ttl = 0
    end

    if act == "set" then
        local ok, err = setin_ex_lists(name, ttl)
        if not ok then
            return render_json("err", nil, err)
        end
        return render_json("ok", "Set into shm succeded", nil)
    end

    if act == "get" then
        local ok, err = in_ex_lists(name)
        if err then
            return render_json("err", nil, err)
        end
        if not ok then
            return render_json("ok", "not found", nil)
        end
        return render_json("ok", "found", nil)
    end

    if act == "del" then
        local ok, err = del_ex_lists(name)
        if not ok then
            return render_json("err", nil, err)
        end
        return render_json("ok", "Delete succeded", nil)
    end
end

local function api_gray_peer(req)
    local uri_args = req.uri_args
    local name = uri_args.u
    local peer = uri_args.p
    local act = uri_args.a
    local ttl = uri_args.ttl

    if type(name) ~= "string" then
        return render_json("err", nil, "Arg 'u' type error")
    end
    if type(peer) ~= "string" then
        return render_json("err", nil, "Arg 'p' type error")
    end

    if type(act) ~= "string" then
        return render_json("err", nil, "Arg 'a' type error")
    end

    if act == "set" then
        if type(tonumber(ttl)) ~= "number" or ttl == 0 then
            return render_json("err", nil, "Arg 'ttl' error")
        end

        local ok, err = set_gray_peer(name, peer, ttl)
        if not ok then
            return render_json("err", nil, err)
        end
        return render_json("ok", "Set into shm succeded", nil)
    end

    if act == "get" then
        local gray_key = "gray:" .. name .. peer
        local val = shm_hc:get(gray_key)
        if val then
            return render_json("ok", "found", nil)
        end
        return render_json("ok", "not found", nil)
    end

    if act == "del" then
        local gray_key = "gray:" .. name .. peer
        shm_hc:delete(gray_key)
        return render_json("ok", "Delete succeded", nil)
    end
end

local function api_debug(req)
    local keys = shm_hc:get_keys(0)
    local tb = {}
    for i, key in ipairs(keys) do
        local val = shm_hc:get(key)
        tb[key] = val or "false"
    end
    return render_json("ok", tb, nil)
end

local router = {
    ex = api_ex_list,
    gray = api_gray_peer,
    debug = api_debug
}

-- api main endpoint
function _M.status()
    local req = {}

    -- fetch request args
    collect_args(req)

    -- request args valid
    -- local ok, err = valid(req)
    -- if not ok then
    --     return render_json("err", nil, err)
    -- end

    local uri_args = req.uri_args
    if type(uri_args) ~= "table" then
        return render_json("err", nil, err)
    end

    if uri_args.t then
        if router[uri_args.t] then
            return router[uri_args.t](req)
        else
            return render_json("err", nil, "Target not supported")
        end
    else
        return all_status()
    end
end

return _M
