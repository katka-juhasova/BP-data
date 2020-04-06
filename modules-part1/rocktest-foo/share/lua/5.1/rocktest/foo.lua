-- stolen from cloudflare's resty.cookie
local ok, new_tab = pcall(require, "table.new")
if not ok then
    new_tab = function() return {} end
end

local ok, clear_tab = pcall(require, "table.clear")
if not ok then
    clear_tab = function(tab) for k, _ in pairs(tab) do tab[k] = nil end end
end

-- end stolen

local _M = new_tab(0, 2)
_M._VERSION = '0.2.0'

function _M.new(self, message)
    return setmetatable({
        _message = message
    }, {__index = self })
end

function _M.get_message(self)
    return "message: '" .. self._message .. "'"
end

return _M
