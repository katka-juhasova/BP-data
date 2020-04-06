
local LOG = {}

local _prompt = "[wagon]"
local _color = function (str)
  return str:gsub("%%%{.-%}", "")
end

do
  local ok, color = pcall(require, 'ansicolors')
  if ok then
    _prompt = color "%{yellow bright}[wagon]%{reset}"
    _color = color
  end
end

function LOG.info(line, ...)
  return LOG.raw(_prompt .. " " .. line, ...)
end

function LOG.raw(line, ...)
  return print(_color(line):format(...))
end

return LOG

