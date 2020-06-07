local Logger, sink, levels
do
  local _obj_0 = require("debugkit.log")
  Logger, sink, levels = _obj_0.Logger, _obj_0.sink, _obj_0.levels
end
local style
style = require("ansikit.style").style
local logger = { }
logger.leveled = function()
  return Logger({
    name = "leveled",
    sink = sink.print,
    level = "info",
    levels = levels({
      "none",
      "debug",
      "info",
      "ok",
      "warn",
      "error",
      "fatal",
      "all"
    }),
    time = os.date("%X"),
    footer = function(self)
      return ""
    end,
    headers = {
      base = function(self)
        return self.color and (style("%{white bold}" .. tostring(self:time()) .. " %{green}" .. tostring(self.name) .. " ")) or tostring(self:time()) .. " " .. tostring(self.name)
      end,
      levels = {
        none = function(self)
          return self.color and ((style.white("[NONE]")) .. (style.reset("  "))) or "[NONE] "
        end,
        debug = function(self)
          return self.color and ((style.white.bluebg("[DEBUG]")) .. (style.reset(" "))) or "[DEBUG]"
        end,
        info = function(self)
          return self.color and ((style.cyan("[INFO]")) .. (style.reset("  "))) or "[INFO] "
        end,
        ok = function(self)
          return self.color and ((style.green("[OK]")) .. (style.reset("    "))) or "[OK]   "
        end,
        warn = function(self)
          return self.color and ((style.yellow("[WARN]")) .. (style.reset("  "))) or "[WARN] "
        end,
        error = function(self)
          return self.color and ((style.red("[ERROR]")) .. (style.reset(" "))) or "[ERROR]"
        end,
        fatal = function(self)
          return self.color and ((style.white.redbg("[FATAL]")) .. (style.reset(" "))) or "[FATAL]"
        end,
        all = function(self)
          return self.color and ((style.black.whitebg("[ALL]")) .. (style.reset("   "))) or "[ALL]  "
        end
      }
    },
    header = function(self, tag, level)
      return (self.headers.base(self)) .. (self.headers.levels[level](self))
    end
  })
end
return logger
