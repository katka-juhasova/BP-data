
local base = require("ansi.base")


local color = {
  black = 0,
  red = 1,
  green = 2,
  yellow = 3,
  blue = 4,
  magenta = 5,
  cyan = 6,
  white = 7,
  reset = 9
}

color.layers = { 
  fg = 3,
  bg = 4
}


color.cga = {
  reset = 0,
  weight = {
    bold = 1,
    faint = 2,
    normal = 22
  },
  italic = 3,
  underline = 4,
  blink = {
    slow = 5,
    rapid = 6,
    none = 25
  },
  negative = 7,
  conceal = 8,
  strikethrough = 9,
  font = {
    primary = 10,
    alternate = (function() -- generates table of 11-19 on the fly
        local t = {}
        for n = 11,19 do t[n-10] = n end
        return t
    end)()
  },
  no_bold = 21,
  no_faint = 22,
  no_italic = 23,
  no_underline = 24,
  no_negative = 27,
  reveal = 28,
  no_strikethrough = 29,
}


function color.setColor(layer, color, handle)
  return base.buildCode({ layer*10 + color }, "m", handle)
end

function color.setTrueColor(layer, red, green, blue, handle)
  return base.buildCode({ layer*10+8, 2, red, green, blue }, "m", handle)
end

function color.setCGA(control, handle)
  return base.buildCode({ control }, "m", handle)
end

function color.reset(handle)
  return color.setCGA(color.cga.reset, handle)
end


return color

