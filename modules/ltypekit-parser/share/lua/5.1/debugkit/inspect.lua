local style
style = require("ansikit.style").style
local pcre = require("rex_pcre2")
local inspect = require("inspect")
local colorize
colorize = function(str)
  do
    str = pcre.gsub(str, [[((?<![\\])['"])((?:.(?!(?<![\\])\1))*.?)\1]], style.green([[%0]]))
    str = str:gsub([[<(.-)>]], style.cyan([[<%1>]]))
    str = str:gsub("%s+([+-]?%d*%.?%d+)[,\n]", style.magenta(" %1" .. tostring(style.white(","))))
    str = str:gsub("inf,", style.magenta("inf" .. tostring(style.white(","))))
    str = str:gsub("=", style.bold.blue("="))
    str = str:gsub("([{}])", style.bold.white("%1"))
    str = str:gsub("true", style.italic.green("true"))
    str = str:gsub("false", style.italic.red("false"))
    str = str:gsub("__[a-zA-Z0-9]+", style.italic("%1"))
    str = str:gsub("  ", style.faint.white("| "))
  end
  return str
end
local i = setmetatable({
  KEY = inspect.KEY,
  METATABLE = inspect.METATABLE
}, {
  __call = function(self, v, s)
    return colorize(inspect(v, s))
  end
})
return {
  inspect = i
}
