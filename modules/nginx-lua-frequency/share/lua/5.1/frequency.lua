-- 频率限制模块
-- Copyright (C) by Jiang Yang (jiangyang-pd@360.cn)

local _M = { _VERSION = "0.0.1" }

_M.__index = _M
_M.initialized = false

local find = string.find
local sub = string.sub


local function explode(separator, str)
    if (separator == '') then return false end
    local pos, t = 0, {}
    -- for each divider found
    for st,sp in function() return find(str, separator, pos, true) end do
        table.insert(t, sub(str, pos, st-1)) -- Attach chars left of current divider
        pos = sp + 1 -- Jump past current divider
    end
    table.insert(t, sub(str, pos)) -- Attach chars right of last divider
    return t
end


-- Only for array table
local function implode(glue, pieces)
    local glueType = type(glue)
    if (glueType ~= 'string' and glueType ~= 'number') then return false end
    if (type(pieces) ~= 'table') then return false end
    local r, ctr = '', 0
    for _, v in ipairs(pieces) do
        if ctr ~= 0 then
            r = r .. glue .. v
        else
            r = r .. v
        end
        ctr = ctr + 1
    end
    return r
end


local function split(separator, str)
    local st, _ = find(str, separator)
    if not st then
        return false
    end
    local suffix = sub(str, st+1)
    local prefix = sub(str, 1, st-1)
    return prefix, suffix
end


function _M.init(conf)
    conf = conf or {}
    local ins = setmetatable(conf, _M)

    if not ins.adapter or not ins.freq then
        return false, "conf error"
    end
    if not ins.after_hit or type(ins.after_hit) ~= "string"
        or (ins.after_hit ~= "forbid" and ins.after_hit ~= "return" and ins.after_hit ~= "header" and ins.after_hit ~= "log")
    then
        ins.after_hit = "forbid"
    end
    ins.initialized = true
    return ins
end


function _M:check(ip)
    if not self.initialized then
        ngx.log(ngx.ERR, "Frequency module has not been initialized")
        return
    end

    local key = self:genKey(ip)
    local value = self.adapter:get(key)
    local timestampNow = ngx.time()
    local newTimeSeriesArr = {}
    if value then
        local ret = self:parseTimeSeries(value)
        if not ret then
            ngx.log(ngx.ERR, "parseTimeSeries err: ", key, "|", value)
            return
        end
        for _, _t in ipairs({"s", "m", "h"}) do
            if ret.timeSeries[_t] then
                local newTimeSeries = self:increase(_t, ret.timestamp, ret.timeSeries[_t], timestampNow)
                if newTimeSeries then
                    ret.timeSeries[_t] = newTimeSeries
                end
            end
        end
        newTimeSeriesArr = ret.timeSeries
    else
        for _, _t in ipairs({"s", "m", "h"}) do
            if self.freq[_t] then
                newTimeSeriesArr[_t] = {1}
            end
        end
    end

    local value = self:buildTimeSeries(newTimeSeriesArr, timestampNow)
    self.adapter:set(key, value, self.freq["expire"])

    return self:nextStep(self:isHit(newTimeSeriesArr), key, value)
end


function _M:isHit(newTimeSeriesArr)
    -- 检查是否命中规则
    local hit = false
    for _, _t in ipairs({"s", "m", "h"}) do
        if newTimeSeriesArr[_t] and type(newTimeSeriesArr[_t]) == "table" then
            local count = 0
            local timeTotal = 0
            for i = #newTimeSeriesArr[_t], 1, -1 do
                count = count + newTimeSeriesArr[_t][i]
                timeTotal = timeTotal + self.freq[_t]["unit"]
                local key = self.freq.rules_prefix .. tostring(timeTotal)
                if self.freq[_t].rules[key] and type(self.freq[_t].rules[key]) == "number" and count > self.freq[_t].rules[key] then
                    hit = true
                    break
                end
            end
        end
    end
    return hit
end


function _M:increase(ruleType, timestampLast, timeSeriesArr, timestampNow)
    local rules = self.freq[ruleType]
    if not rules or type(timeSeriesArr) ~= "table" or not rules.unit then
        return false
    end
    local newTimeSeriesArr = {}
    local n = #timeSeriesArr

    local unitMap = {s = 1, m = 60, h = 3600}
    local unit = self.freq[ruleType]["unit"] * unitMap[ruleType]

    local timestampLastUnit = timestampLast - timestampLast % unit
    local timestampNowUnit = timestampNow - timestampNow % unit

    if timestampLastUnit == timestampNowUnit then
        timeSeriesArr[n] = timeSeriesArr[n] + 1
        newTimeSeriesArr = timeSeriesArr
    else
        -- timestampNowUnit > timestampLastUnit
        local forward = (timestampNowUnit - timestampLastUnit) / unit
        if forward < self.freq[ruleType]["max_window"] then
            -- 窗口向前推进
            for i = 1, forward do
                local times = 0
                if i == forward then
                    times = 1
                end
                table.insert(timeSeriesArr, times)
            end
            local n = #timeSeriesArr
            if n > self.freq[ruleType]["max_window"] then
                -- 取最近的时间窗口
                local j = n - self.freq[ruleType]["max_window"] + 1
                for i = j, n do
                    if tonumber(timeSeriesArr[i]) == 0 and i == j then
                        j = j + 1
                    else
                        table.insert(newTimeSeriesArr, timeSeriesArr[i])
                    end
                end
            else
                newTimeSeriesArr = timeSeriesArr
            end
        else
            newTimeSeriesArr = {1}
        end
    end
    return newTimeSeriesArr
end


function _M:buildTimeSeries(timeSeries, timestamp)
    local timeSeriesArr = {}
    if timeSeries["h"] then
        table.insert(timeSeriesArr, "h_" .. implode(",", timeSeries["h"]))
    end
    if timeSeries["m"] then
        table.insert(timeSeriesArr, "m_" .. implode(",", timeSeries["m"]))
    end
    if timeSeries["s"] then
        table.insert(timeSeriesArr, "s_" .. implode(",", timeSeries["s"]))
    end
    return implode("|", timeSeriesArr) .. ":" .. tostring(timestamp)
end


function _M:parseTimeSeries(ts)
    local timeSeries, timestamp = split(":", ts)
    if timeSeries == false or timeSeries == "" or timestamp == "" then
        return false
    end

    local ret = {}
    ret["timestamp"] = timestamp
    ret["timeSeries"] = {}
    local timeSeriesArr = explode("|", timeSeries)
    for _, v in ipairs(timeSeriesArr) do
        local ruleType, timeSeriesDetail = split("_", v)
        ret["timeSeries"][ruleType] = explode(",", timeSeriesDetail)
    end
    return ret
end


function _M:nextStep(hit, key, value)
    if self.after_hit == "forbid" then -- 响应403
        if hit then
            ngx.exit(ngx.HTTP_FORBIDDEN)
        end
    elseif self.after_hit == "return" then -- 返回检查命中结果
        return hit
    elseif self.after_hit == "header" then -- 添加 header 给下游处理
        local header = 0
        if hit then
            header = 1
        end
        ngx.req.set_header("Qihoo-Frequency", header)
    elseif self.after_hit == "log" then
        if hit then
            local headers = ngx.req.get_headers()
            ngx.log(ngx.ERR, "Key: ", key, ", Value: ", value, ", UA: ", tostring(headers["User-Agent"]),
                ", Referer: ", tostring(headers["Referer"]), ", Cookie: ", tostring(headers["Cookie"]))
        end
    end
    return hit
end


function _M:genKey(ip, type)
    type = type or "ip"
    return "freq_" .. tostring(type) .. "_" .. tostring(ip)
end


return _M
