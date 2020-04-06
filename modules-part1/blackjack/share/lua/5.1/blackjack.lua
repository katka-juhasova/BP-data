-- blackjack.lua
-- Copyright (c) 2020 swissChili <swisschili.sh> all rights reserved.

local colors = {
  -- Stolen from ansicolors.lua
  -- reset
  reset =      0,

  -- misc
  bright     = 1,
  dim        = 2,
  underline  = 4,
  blink      = 5,
  reverse    = 7,
  hidden     = 8,

  -- foreground colors
  black     = 30,
  red       = 31,
  green     = 32,
  yellow    = 33,
  blue      = 34,
  magenta   = 35,
  cyan      = 36,
  white     = 37,

  -- background colors
  blackbg   = 40,
  redbg     = 41,
  greenbg   = 42,
  yellowbg  = 43,
  bluebg    = 44,
  magentabg = 45,
  cyanbg    = 46,
  whitebg   = 47,

  c = function (c)
    return (string.char(27) .. '[%dm'):format(c)
  end
}

local function err(message)
  print(colors.c(colors.red) .. message .. colors.c(colors.reset))
end

local function warn(message)
  print(colors.c(colors.yellow) .. message .. colors.c(colors.reset))
end

function htmlProcessor(site, template, parameters)
  local parent = ""
  -- #{ key = value }
  template = template:gsub("#{%s*([%w._]+)%s*=%s*(.-)}",
    function(k, v)
      if (k == "parent")
      then
        parent = v
      else
        parameters[k] = v
      end
      return ""
    end
  )

  -- ${ variable }
  template = template:gsub("%${%s*([%w_%.]+)%s*}", function (word)
    return parameters[word]
  end)

  if parent ~= "" then
    parameters["body"] = template
    return site:renderTemplate(parent, parameters)
  end

  return template
end

function mdProcessor(site, temp, parameters)
  local toReplace = {
    { "`", "code" },
    { "%*%*", "b" },
    { "%*", "i" },
    { "~~", "s" }
  }

  local parent = ""
  -- @ must be at start of a line, so adding \n makes it work at
  -- the start of a file.
  local template = '\n' .. temp
  -- @key = value
  template = template:gsub("\n%s*@([%w%._]+)%s*=%s*([%w%._]+)",
    function (k, v)
      if k == "parent" then
        parent = v
      else
        parameters[k] = v
        print(k .. ' = ' .. v)
      end

      return ''
    end
  )

  template = template:gsub("%${%s*([%w_%.]+)%s*}", function (word)
    return parameters[word]
  end)

  template = template:gsub("(#+)([^=.^\n]+)\n", function (depth, header)
    return "<h" .. #depth .. ">" .. header .. "</h" .. #depth .. ">"
  end)

  template = template:gsub("```\n+(.-)\n+```", function (code)
    return "<pre><code class>" .. code .. '</code></pre>'
  end)

  for i = 1, #toReplace do
    local k = toReplace[i][1]
    local v = toReplace[i][2]
    template = template:gsub(k .. "(.-)" .. k, function (body)
      return "<" .. v .. ">" .. body .. "</" .. v .. ">"
    end)
  end

  template = template:match( "^%s*(.-)%s*$"):gsub("\n\n+", "\n<br>\n")

  if parent ~= "" then
    parameters["body"] = template
    return site:renderTemplate(parent, parameters)
  end

  return template
end

CommandProcessor = {
  command = "",
  parent = nil,
}

function CommandProcessor:new(command)
  cmdp = {}
  setmetatable(cmdp, self)
  self.__index = self
  cmdp.command = command
  return cmdp
end

function cmdProcessor(command)
  return function (site, template, parameters)
    local p = io.popen(command .. ' > /tmp/blackjack-stdout.html', 'w')
    p:write(template)
    p:close()
    local output = io.open("/tmp/blackjack-stdout.html", "r")
    if output ~= nil then
      local out = output:read("all")
      output:close()
      return out
    else
      err("    Error: Could not read from temporary file.")
      os.exit(1)
    end
  end
end

Site = {
  -- Template source directory
  templates = "templates",
  -- Content source directory
  content = "content",
  -- Output directory
  output = "site",
  -- Static file directory
  static = nil,
  -- File processor objects
  processors = {
    html = {
      process = htmlProcessor,
      extension = 'html'
    },
    md = {
      process = mdProcessor,
      extension = 'html'
    }
  },
  -- Global config data
  global = {}
}

local function getExtension(file)
  return file:match(".(%w+)$")
end

function Site:renderTemplate(templateFile, body)
  local fp = self.templates .. '/' .. templateFile
  return self:render(fp, body)
end

function Site:render(fp, body)
  local f = io.open(fp, "r")
  if f ~= nil then
    local text = f:read("all")
    f:close()
    local extension = getExtension(fp)
    if self.processors[extension] ~= nil then
      return self.processors[extension].process(self, text, body)
    else
      -- print("    Error: There is no processor for ." .. extension .. " files")
      -- os.exit(1)
      return text
    end
  else
    err("    Error: Tried to open template that does not exist")
    print(fp)
    os.exit(1)
  end
end

local function replaceExtension(file, ext)
  return file:gsub(".%w+$", '.' .. ext)
end

local function getFileName(site, file)
  return file:sub(#site.content + 1)
end

function Site:build()
  local p = io.popen('find "'.. self.content ..'" -type f')
  for file in p:lines() do
    print(" Building: ".. file)
    local html = self:render(file, self.global)
    local ext = getExtension(file)
    local newext
    if self.processors[ext] then
      newext = replaceExtension(file, self.processors[ext].extension)
    else
      warn("  Warning: no processor defined for " .. ext)
      newext = file
    end
    local outFile = self.output .. getFileName(
      self,
      newext
    )
    print("  Writing: " .. outFile)
    local file = io.open(outFile, "w")
    if file ~= nil then
      file:write(html)
    else
      err("    Error: Could not write file. Does "
        .. self.output .. " directory exist?")
      os.exit(1)
    end
  end

  if self.static ~= nil then
    print("  Copying: " .. self.static)
    io.popen('cp -r "' .. self.static .. '" "' .. self.output .. '/static/"')
  end
end
