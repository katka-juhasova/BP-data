-- External dependencies
local Set = require("pl.Set")

-- Internal modules
local CLDR = {}

setmetatable(CLDR, {
    __index = function (self, key)
      local data = require("cldr.data." .. key)
      if key == "locales" then
        data = Set(data)
      end
      self[key] = data
      return self[key]
    end
  })

return CLDR
