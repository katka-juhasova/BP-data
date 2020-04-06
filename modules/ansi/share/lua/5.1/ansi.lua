
local ansi = {}

local color = require("ansi.color")
local term  = require("ansi.term")

for k,v in pairs(color) do
  ansi[k] = v
end

for k,v in pairs(term) do
  ansi[k] = v
end

return ansi
