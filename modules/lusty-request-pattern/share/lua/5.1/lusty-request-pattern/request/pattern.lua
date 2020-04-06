local util = require 'lusty.util'
local paramMatch = '([^/?]*)'
local channel = {unpack(channel)}
table.remove(channel, 1)
local prelen = table.concat(channel, '/'):len()+2

local listener = function()

  local patterns = {}

  for i=1, #config.patterns do

    for match, file in pairs(config.patterns[i]) do

      local item = {
        file = file,
        param = {}
      }

      item.pattern = "^"..match:gsub("{([^}]*)}", function(c)
        item.param[#item.param+1]=c
        return paramMatch
      end) .. "/?"

      patterns[#patterns+1] = item
    end
  end

  return {
    handler = function(context)

      context.response.status = 404
      local uri = context.request.uri:sub(prelen)

      for i=1, #patterns do
        local item = patterns[i]
        local tokens = {uri:match(item.pattern)}

        if #tokens > 0 then
          local arguments = {}

          if uri ~= tokens[1] then
            for j=1, #tokens do
              if tokens[j] ~= '' and item.param[j] then
                arguments[item.param[j]]=tokens[j]
              end
            end
          end

          arguments.config=config
          arguments.context=context

          util.inline(item.file, arguments)
          break
        end
      end
    end
  }
end
return listener()
