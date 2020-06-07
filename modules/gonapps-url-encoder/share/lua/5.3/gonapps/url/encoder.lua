local _M = {}

function _M.rawEncode(url)
    return string.gsub(url, "[^A-z0-9\\-_.~]", function(char) return string.format("%%%X", string.byte(char)) end)
end

function _M.encode(url)
    return string.gsub(_M.rawEncode(url), "%%20", "+")
end

return _M
