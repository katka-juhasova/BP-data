--[[
  Copyright (c) llmII <dev@amlegion.org>

  # Open Works License

  This is version 0.9.4 of the Open Works License

  ## Terms

  Permission is hereby granted by the holder(s) of copyright or other
  legal privileges, author(s) or assembler(s), and contributor(s) of
  this work, to any person who obtains a copy of this work in any
  form, to reproduce, modify, distribute, publish, sell, sublicense,
  use, and/or otherwise deal in the licensed material without
  restriction, provided the following conditions are met:

  Redistributions, modified or unmodified, in whole or in part, must
  retain applicable copyright and other legal privilege notices, the
  above license notice, these conditions, and the following
  disclaimer.

  NO WARRANTY OF ANY KIND IS IMPLIED BY, OR SHOULD BE INFERRED FROM,
  THIS LICENSE OR THE ACT OF DISTRIBUTION UNDER THE TERMS OF THIS
  LICENSE, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
  MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, AND
  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS, ASSEMBLERS, OR
  HOLDERS OF COPYRIGHT OR OTHER LEGAL PRIVILEGE BE LIABLE FOR ANY
  CLAIM, DAMAGES, OR OTHER LIABILITY, WHETHER IN ACTION OF CONTRACT,
  TORT, OR OTHERWISE ARISING FROM, OUT OF, OR IN CONNECTION WITH THE
  WORK OR THE USE OF OR OTHER DEALINGS IN THE WORK.
]]

local logfile
do -- logfile def
  -- forward decls
  local log_levels

  -- private functions
  local function nop() end

  local nops = '' -- hold a ref to an empty string
  local function snop() return nops end

  local fmt_string = '[%s/%-6s%s] %s: %s'
  local function getlogstr(log_name, log_level, srclineinfo, str)
    return fmt_string:format
    (
      log_name, log_level, os.date(), srclineinfo, str
    )
  end

  local function getsrclineinfo()
    local info = debug.getinfo(3, 'Sl')
    return info.short_src .. ':' .. info.currentline
  end

  local function close_file(file)
    if file then
      file:close()
    end
  end

  local function _write(file, str, ...)
    file():write(str:format(...)):write('\n'):flush()
  end

  local function write(files, str, ...)
    for _, v in pairs(files) do
      local ok, err = pcall(_write, v, str, ...)
      if not ok then
        error(('Major logging failure: %s\n%s'):format(err, debug.traceback()))
      end
    end
  end

  local function open_file(self)
    local fname = self.dir .. os.date '%d.%m.%Y' .. '-' .. self.name .. '.log'
    self.file = io.open(fname, 'a')
    self.date = os.date '%d.%m.%Y'
  end

  local function get_file(self)
    if not self.date then
      open_file(self)
    else
      if os.date '%d.%m.%Y' ~= self.date then
        close_file(self.file)
        open_file(self)
      end
    end
    return self.file
  end

  -- each of these returns a function that will return where the output
  -- will be written. This allows to make it a simple function that does the
  -- one thing needed instead of branching and checking conditions/vars every
  -- time a log line is written
  -- write handles making sure there is a file to write to, where the config
  -- specifies, and that the file matches current date
  -- print just makes sure that errors are sent to stderr instead of stdout
  -- by creating a function that returns stderr dependent upon the level
  -- attached
  -- optimization? have memoization that returns the already created function
  -- for space savings rather than a new function per?
  local outputs = {
    write = function(self, level)
      return function()
        return get_file(self)
      end
    end,

    print = function(self, level)
      local retf

      if not self.daemonized then
        local ret = io.stdout
        if log_levels[level] >= log_levels.error then
          ret = io.stderr
        end
        retf = function()
          return ret
        end
      end

      return retf
    end
  }

  -- private defs
  log_levels = {
    trace   = 1,
    debug   = 2,
    info    = 3,
    warn    = 4,
    error   = 5,
    fatal   = 6
  }

  -- methods
  local logfile_base = {
    close = function(self) close_file(self.file) end
  }

  logfile_base.__index = logfile_base
  logfile_base.__gc    = logfile_base.close

  local logfile_class = setmetatable(
    {
      __init = function(self, config, name)
        self.conf = config.logs[name] or config.logs.default
        self.name, self.dir = name, config.dir
        self.daemonized, self.debug_info = config.daemonized, config.debug_info

        for level, _ in pairs(log_levels) do
          local files = {}
          local srclinegen = self.debug_info and getsrclineinfo or snop
          self[level] = nop

          for where, when in pairs(self.conf.levels) do
            if log_levels[level] >= log_levels[when] then
              local file = outputs[where](self, level)
              if file then
                table.insert(files, file)
              end
            end
          end

          if #files >= 1 then
            self[level] = function(self, str, ...)
              write(
                files,
                getlogstr(self.name, level, srclinegen(), str),
                ...
              )
            end
          end
        end

        return self
      end
    },
    {
      __index = logfile_base,
      __call = function(cls, ...)
        return cls.__init(setmetatable({}, logfile_base), ...)
      end
    }
  )

  logfile = logfile_class
end -- end logfile def

local log
do -- log_manager def
  local log_base = {
    open = function(self, name)
      self.logs[name] = self.logs[name] or logfile(self.conf, name)
      return self.logs[name]
    end,

    close = function(self, name)
      if self.logs[name] then
        self.logs[name]:close()
        logs[name] = nil
      end
    end,

    closeall = function(self)
      for _, log in pairs(self.logs) do
        log:close()
      end
      self.logs = {}
    end
  }

  log_base.__index = log_base
  log_base.__gc = log_base.closeall

  local log_class = setmetatable(
    {
      __init = function(self, config)
        self.conf, self.logs = config, {}
        return self
      end
    },
    {
      __index = log_base,
      __call = function(cls, ...)
        return cls.__init(setmetatable({}, log_base), ...)
      end
    }
  )

  log = log_class
end -- end log_manager def

return log
