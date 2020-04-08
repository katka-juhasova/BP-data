local hiredis = require 'hiredis'

local _M = {}
local mt = { __index = _M }

local bit   = require "bit"

local bxor      = bit.bxor
local band      = bit.band
local lshift    = bit.lshift
local rshift    = bit.rshift

local len       = string.len
local sub       = string.sub
local gsub      = string.gsub
local format    = string.format


local crc16tab  = {
    0x0000, 0x1021, 0x2042, 0x3063, 0x4084, 0x50a5, 0x60c6, 0x70e7,
    0x8108, 0x9129, 0xa14a, 0xb16b, 0xc18c, 0xd1ad, 0xe1ce, 0xf1ef,
    0x1231, 0x0210, 0x3273, 0x2252, 0x52b5, 0x4294, 0x72f7, 0x62d6,
    0x9339, 0x8318, 0xb37b, 0xa35a, 0xd3bd, 0xc39c, 0xf3ff, 0xe3de,
    0x2462, 0x3443, 0x0420, 0x1401, 0x64e6, 0x74c7, 0x44a4, 0x5485,
    0xa56a, 0xb54b, 0x8528, 0x9509, 0xe5ee, 0xf5cf, 0xc5ac, 0xd58d,
    0x3653, 0x2672, 0x1611, 0x0630, 0x76d7, 0x66f6, 0x5695, 0x46b4,
    0xb75b, 0xa77a, 0x9719, 0x8738, 0xf7df, 0xe7fe, 0xd79d, 0xc7bc,
    0x48c4, 0x58e5, 0x6886, 0x78a7, 0x0840, 0x1861, 0x2802, 0x3823,
    0xc9cc, 0xd9ed, 0xe98e, 0xf9af, 0x8948, 0x9969, 0xa90a, 0xb92b,
    0x5af5, 0x4ad4, 0x7ab7, 0x6a96, 0x1a71, 0x0a50, 0x3a33, 0x2a12,
    0xdbfd, 0xcbdc, 0xfbbf, 0xeb9e, 0x9b79, 0x8b58, 0xbb3b, 0xab1a,
    0x6ca6, 0x7c87, 0x4ce4, 0x5cc5, 0x2c22, 0x3c03, 0x0c60, 0x1c41,
    0xedae, 0xfd8f, 0xcdec, 0xddcd, 0xad2a, 0xbd0b, 0x8d68, 0x9d49,
    0x7e97, 0x6eb6, 0x5ed5, 0x4ef4, 0x3e13, 0x2e32, 0x1e51, 0x0e70,
    0xff9f, 0xefbe, 0xdfdd, 0xcffc, 0xbf1b, 0xaf3a, 0x9f59, 0x8f78,
    0x9188, 0x81a9, 0xb1ca, 0xa1eb, 0xd10c, 0xc12d, 0xf14e, 0xe16f,
    0x1080, 0x00a1, 0x30c2, 0x20e3, 0x5004, 0x4025, 0x7046, 0x6067,
    0x83b9, 0x9398, 0xa3fb, 0xb3da, 0xc33d, 0xd31c, 0xe37f, 0xf35e,
    0x02b1, 0x1290, 0x22f3, 0x32d2, 0x4235, 0x5214, 0x6277, 0x7256,
    0xb5ea, 0xa5cb, 0x95a8, 0x8589, 0xf56e, 0xe54f, 0xd52c, 0xc50d,
    0x34e2, 0x24c3, 0x14a0, 0x0481, 0x7466, 0x6447, 0x5424, 0x4405,
    0xa7db, 0xb7fa, 0x8799, 0x97b8, 0xe75f, 0xf77e, 0xc71d, 0xd73c,
    0x26d3, 0x36f2, 0x0691, 0x16b0, 0x6657, 0x7676, 0x4615, 0x5634,
    0xd94c, 0xc96d, 0xf90e, 0xe92f, 0x99c8, 0x89e9, 0xb98a, 0xa9ab,
    0x5844, 0x4865, 0x7806, 0x6827, 0x18c0, 0x08e1, 0x3882, 0x28a3,
    0xcb7d, 0xdb5c, 0xeb3f, 0xfb1e, 0x8bf9, 0x9bd8, 0xabbb, 0xbb9a,
    0x4a75, 0x5a54, 0x6a37, 0x7a16, 0x0af1, 0x1ad0, 0x2ab3, 0x3a92,
    0xfd2e, 0xed0f, 0xdd6c, 0xcd4d, 0xbdaa, 0xad8b, 0x9de8, 0x8dc9,
    0x7c26, 0x6c07, 0x5c64, 0x4c45, 0x3ca2, 0x2c83, 0x1ce0, 0x0cc1,
    0xef1f, 0xff3e, 0xcf5d, 0xdf7c, 0xaf9b, 0xbfba, 0x8fd9, 0x9ff8,
    0x6e17, 0x7e36, 0x4e55, 0x5e74, 0x2e93, 0x3eb2, 0x0ed1, 0x1ef0
}


local function crc16(str)
    local crc = 0
    for i=1, #str do
        crc = bxor(lshift(crc, 8), crc16tab[band(bxor(rshift(crc, 8), str:byte(i)), 0x00ff) + 1]);
    end

    return crc
end

local commands = {
    "append",            --[["auth",]]        --[["bgrewriteaof",]]
    --[["bgsave",]]      --[["blpop",]]    --[["brpop",]]
    --[["brpoplpush",]]  --[["config", ]]   --[["dbsize",]]
    --[["debug", ]]      "decr",              "decrby",
    "del",         --[["discard",           "echo",]]
    --[["eval",]]              "exec",              "exists",
    --[["expire",            "expireat",          "flushall",
    "flushdb",]]           "get",               "getbit",
    "getrange",          "getset",            "hdel",
    "hexists",           "hget",              "hgetall",
    "hincrby",           "hkeys",             "hlen",
    "hmget",             "hmset",             "hset",
    "hsetnx",            "hvals",             "incr",
    "incrby",           --[["info",]]         --[["keys",]]
    --[["lastsave", ]]  "lindex",            "linsert",
    "llen",              "lpop",              "lpush",
    "lpushx",            "lrange",            "lrem",
    "lset",              "ltrim",             "mget",
    "monitor",           --[["move",]]        "mset",
    "msetnx",            --[[["multi",]]      --[["object",]]
    --[["persist",]]     --[["ping",]]        --[["psubscribe",]]
   --[[ "publish",           "punsubscribe",      "quit",]]
    --[["randomkey",         "rename",            "renamenx",]]
    "rpop",              --[["rpoplpush",]]   "rpush",
    "rpushx",            "sadd",              --[["save",]]
    "scard",             --[["script",]]
    --[["sdiff",             "sdiffstore",]]
    --[["select",]]            "set",               "setbit",
    "setex",             "setnx",             "setrange",
    --[["shutdown",          "sinter",            "sinterstore",
    "sismember",         "slaveof",           "slowlog",]]
    "smembers",          "smove",             "sort",
    "spop",              "srandmember",       "srem",
    "strlen",            --[["subscribe",]]         "sunion",
    "sunionstore",       --[["sync",]]              "ttl",
    "type",              --[["unsubscribe",]]       --[["unwatch",
    "watch",]]             "zadd",              "zcard",
    "zcount",            "zincrby",           "zinterstore",
    "zrange",            "zrangebyscore",     "zrank",
    "zrem",              "zremrangebyrank",   "zremrangebyscore",
    "zrevrange",         "zrevrangebyscore",  "zrevrank",
    "zscore",            --[["zunionstore",    "evalsha"]]
}

function _M.fetch_slots(self)
    local serv_list = self.config.serv_list
    local conns_cache = {}
    for i=1,#serv_list do
        local ip = serv_list[i].ip
        local port = serv_list[i].port
        local conn, err = hiredis.connect(ip, port)
        if conn then
            if not conns_cache[ip .. port] then
                conns_cache[ip .. port] = conn
            end
            local slot_info, err = conn:command("cluster", "slots")
            if slot_info and slot ~= hiredis.NIL then
                local slots = {}
                for i=1,#slot_info do
                    local item = slot_info[i]
                    for slot = item[1],item[2] do
                        local list = {serv_list={}, cur = 1, }
                        for j = 3,#item do
                            list.serv_list[#list.serv_list + 1] = {ip = item[j][1], port = item[j][2]}
                            slots[slot] = list
                        end
                    end
                end
                self.slot_cache = slots
                self.conns_cache = conns_cache
            end
        end
    end
end

local function redis_slot(key)
    local s, e
    local keylen = len(key)
    for i = 1, keylen do
        if not s and key:byte(i) == 123 then
            s = i
        elseif key:byte(i) == 125 then
            e = i
            break
        end
    end

    if s and e and e > s + 1 then
        return band(crc16(sub(key, s + 1, e - 1)), 0x3fff)
    end

    return band(crc16(key), 0x3fff)
end

local function ip_string(ip)
    if ip:match(":") then
        return "[" .. ip .. "]"
    end

    return ip
end

function _M.init_slots(self)
    self:fetch_slots()
end

function _M.new(self, config)
    local inst = {}
    inst.config = config
    inst.slot_cache = {}
    inst.conns_cache = {}
    inst = setmetatable(inst, mt)
    if type(inst.config.serv_list)~="table" then
        return nil, "serv_list必须是表类型"
    end
    if #inst.config.serv_list<1 then
        return nil, "serv_list不能为空表"
    end
    if inst.config.iscluster and inst.config.iscluster == true then
        if #inst.config.serv_list<3 then
            return nil, "集群模式下serv_list至少为3个,请列出所有节点"
        end
        inst.iscluster = true
    else
        if #inst.config.serv_list>1 then
            return nil, "serv_list大于1必须是集群模式！"
        end
        inst.iscluster = false
    end
    if inst.iscluster == true then
        inst:init_slots()
    end
    return inst
end

local MAGIC_TRY = 3
local DEFUALT_KEEPALIVE_TIMEOUT = 1000
local DEFAULT_KEEPALIVE_CONS = 200

function _M.close(self)
    print('释放资源')
    if self.conns_cache then
        for k,v in pairs(self.conns_cache) do
            v:close()
        end
    end
end

local function next_index(cur, size)
    cur = cur + 1
    if cur > size then
        cur = 1
    end
    return cur
end

local function _cluster_do_cmd(self, cmd, key, ...)
    key = tostring(key)
    local slot = redis_slot(key)
    for k=1, MAGIC_TRY do
        local slots = self.slot_cache
        local serv_list = slots[slot].serv_list
        local index =slots[slot].cur
        local conns = self.conns_cache
        for i=1,#serv_list do
            local ip = serv_list[index].ip
            local port = serv_list[index].port
            local conn = conns[ip .. port]
            if not conn then
                conn = hiredis.connect(ip, port)
            end
            if conn then
                slots[slot].cur = index
                local res, err = conn:command(cmd, key, ...)
                if err and string.sub(err, 1, 5) == "MOVED" then
                    self:fetch_slots()
                    -- conn:close()
                    break
                end
                if res == hiredis.NIL then
                    -- conn:close()
                    return nil, err
                end
                -- conn:close()
                return res, err
            else
                index = next_index(index, #serv_list)
            end
        end
    end
end

local function _signle_do_cmd(self, cmd, key, ...)
    local ip = self.config.serv_list[1].ip
    local port = self.config.serv_list[1].port
    local conns = self.conns_cache
    for k=1, MAGIC_TRY do
        local conn = conns[ip .. port]
        if not conn then
            conn = hiredis.connect(ip, port)
        end
        if conn then
            self.conns_cache[ip .. port] = conn
            local res, err = conn:command(cmd, key, ...)
            if res == hiredis.NIL then
                return nil, err
            end
            return res, err
        end
    end
    return nil, '多次连接redis失败'
end

local function _do_cmd(self, cmd, key, ...)
    if self._reqs then
        local args = {...}
        local t = {cmd = cmd, key=key, args=args}
        table.insert(self._reqs, t)
        return
    end
    local config = self.config

    local res, err

    if self.iscluster == true then
        res, err = _cluster_do_cmd(self, cmd, key, ...)
    else
        res, err = _signle_do_cmd(self, cmd, key, ...)
    end
    
    return res, err
end

for i = 1, #commands do
    local cmd = commands[i]

    _M[cmd] =
        function (self, ...)
            return _do_cmd(self, cmd, ...)
        end
end

return _M
