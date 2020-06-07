local _M = {}

function _M.rawDecode(url)
    return string.gsub(url, "%%(%x%x)", function(hex)
        return string.char(tonumber(hex, 16))
    end)
end

function _M.decode(url)
    return _M.rawDecode(string.gsub(url, "+", " "))
end

return _M
