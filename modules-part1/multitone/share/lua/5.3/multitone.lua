local moonxml = require('moonxml')
local max, min
do
  local _obj_0 = math
  max, min = _obj_0.max, _obj_0.min
end
local format
format = string.format
local normalize
normalize = function(color)
  return format('%1.4f', min(255, max(0, color)) / 255)
end
local generator
generator = function(...)
  local args = {
    ...
  }
  local colors
  do
    local _accum_0 = { }
    local _len_0 = 1
    for _index_0 = 1, #args do
      local tab = args[_index_0]
      if #tab >= 3 then
        _accum_0[_len_0] = tab
        _len_0 = _len_0 + 1
      end
    end
    colors = _accum_0
  end
  local options
  do
    local _accum_0 = { }
    local _len_0 = 1
    for _index_0 = 1, #args do
      local tab = args[_index_0]
      if #tab == 0 then
        _accum_0[_len_0] = tab
        _len_0 = _len_0 + 1
      end
    end
    options = _accum_0
  end
  options = options[#options] or { }
  local concat
  concat = function(t)
    return table.concat(t, ' ')
  end
  return svg({
    xmlns = 'http://www.w3.org/2000/svg',
    width = 0,
    height = 0,
    class = options.class or 'multitone'
  }, function()
    return filter({
      id = options.id or 'multitone'
    }, function()
      feColorMatrix({
        type = 'matrix',
        values = concat({
          '.375 .500 .125 0 0',
          '.375 .500 .125 0 0',
          '.375 .500 .125 0 0',
          options.alpha and '.375 .500 .125 0 0' or '0 0 0 1 0'
        })
      })
      return feComponentTransfer({
        ['color-interpolation-filter'] = 'sRGB'
      }, function()
        for idx, func in ipairs({
          feFuncR,
          feFuncG,
          feFuncB,
          (options.alpha and feFuncA or nil)
        }) do
          func({
            type = 'table',
            tableValues = concat((function()
              local _accum_0 = { }
              local _len_0 = 1
              for _index_0 = 1, #colors do
                local color = colors[_index_0]
                _accum_0[_len_0] = normalize(color[idx] or 255)
                _len_0 = _len_0 + 1
              end
              return _accum_0
            end)())
          })
        end
      end)
    end)
  end)
end
local buffer
buffer = function()
  local b = { }
  return (function(str)
    return table.insert(b, str)
  end), (function()
    return table.concat(b, '\n')
  end)
end
local lang = moonxml.xml:derive()
return {
  generate = function(...)
    local insert, result = buffer()
    lang.environment.print = insert
    lang:hack(generator, ...)
    return result()
  end
}
