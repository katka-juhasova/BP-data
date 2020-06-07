
local param = config.param

local function url_decode(str)
  str = string.gsub (str, "+", " ")
  str = string.gsub (str, "%%(%x%x)",
      function(h) return string.char(tonumber(h,16)) end)
  str = string.gsub (str, "\r\n", "\n")
  return str
end

return {
  handler = function(context)
    context.request.body = url_decode(context.request.query[param])
    context.request.body_was_read = true
    return nil, true
  end,

  options = {
    predicate = function(context)
      if context.request.query[param] then
        return true
      end
      return false
    end
  }
}
