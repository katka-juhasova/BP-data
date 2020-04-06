-- не моя либы, не помню где взял, не помню почему стоили мои инициалы..ложь и пиздежь
local log = {}

function log.toboolean(str)
    if type(str) ~= "string" or (str ~= "true" and str ~= "false") or not str then
        return nil
    end
    return str == "true"
end

log.usecolor = false
log.outfile = nil --'/tmp/xpect.log'
log.level = "trace"
log.pid = nil

local modes = {
    { name = "trace", status = false, color = "\27[34m", },
    { name = "debug", status = false, color = "\27[36m", },
    { name = "info", status = false, color = "\27[32m", },
    { name = "warn", status = false, color = "\27[33m", },
    { name = "error", status = false, color = "\27[31m", },
    { name = "fatal", status = false, color = "\27[35m", },
}


local levels = {}
for i, v in ipairs(modes)
do
    levels[v.name] = i
end


local function round(x, increment)
    increment = increment or 1
    x = x / increment
    return (x > 0 and math.floor(x + .5) or math.ceil(x - .5)) * increment
end


local _tostring = tostring

local function tostring(...)
    local t = {}

    for i = 1, select('#', ...)
    do
        local x = select(i, ...)

        if type(x) == "number" then
            x = round(x, .01)
        end

        t[#t + 1] = _tostring(x)
    end

    return table.concat(t, " ")
end


for i, x in ipairs(modes)
do
    local nameupper = x.name:upper()
    log[x.name] = function(message, status)
        if status ~= nil and type(status) ~= 'boolean' then
            x.status = log.toboolean(status)
        else
            x.status = status
        end
        -- Return early if we're below the log level
        if i < levels[log.level] then
            return
        end

        -- if Yes, then print
        if (type(x.status) == 'boolean' and x.status == false) or x.status == nil then
            return
        end

        local msg = tostring(message)
        --local info = debug.getinfo(2, "Sl")
        --local lineinfo = info.short_src .. ":" .. info.currentline
        if x.name == 'error' then
            error(string.format("%s%-6s%s [%s] %s: %s",
                log.usecolor and x.color or "",
                os.date("%Y/%m/%d %H:%M:%S"),
                log.usecolor and "\27[0m" or "",
                log.pid or 0, --lineinfo,
                nameupper,
                msg))
        end
        -- Output to console - ex.: (2016/06/19 14:02:55 [16775]: Info: test
        print(string.format("%s%-6s%s [%s] %s: %s",
            log.usecolor and x.color or "",
            os.date("%Y/%m/%d %H:%M:%S"),
            log.usecolor and "\27[0m" or "",
            log.pid or 0, --lineinfo,
            nameupper,
            msg))

        -- Output to log file
        if log.outfile then
            local fp = io.open(log.outfile, "a")
            local str = string.format("%-6s [%s] %s: %s\n",
                os.date("%Y/%m/%d %H:%M:%S"),
                log.pid or 0, --lineinfo,
                nameupper,
                msg)
            fp:write(str)
            fp:close()
        end
    end
end


return log
