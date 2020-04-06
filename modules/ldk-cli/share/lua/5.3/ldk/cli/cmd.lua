local M = {}

local help = require 'ldk.cli.help'
local flag = require 'ldk.cli.flag'
local util = require 'ldk.cli.util'

local ipairs = ipairs
local require = require

local math_min = math.min

local _ENV = M

local function print_errorln(cmd, ...)
  cmd.error_writer(...)
  cmd.error_writer('\n')
end

local function print_errorf(cmd, fmt, ...)
  cmd.error_writer(fmt:format(...))
end

local function buf_write(buf, write)
  for _, x in ipairs(buf) do
    write(x)
  end
end

local function print_version(cmd)
  local buf = help.format_version(cmd)
  buf_write(buf, cmd.writer)
end

local function print_usage(cmd)
  local buf = help.format_usage(cmd)
  buf_write(buf, cmd.error_write)
end

local function print_help(cmd)
  local buf = help.format_help(cmd)
  buf_write(buf, cmd.writer)
end

local function setup_help_flags(cmd)
  if cmd.hide_help then
    return
  end

  cmd.path = cmd.name
  if cmd.parent then
    cmd.path = ('%s %s'):format(cmd.parent.path, cmd.name)
  end

  local has_help_option, has_command, has_help_command
  for _, x in ipairs(cmd) do
    if x.kind == 'option' then
      if x.long == 'help' or x.short == 'h' then
        has_help_option = true
      end
    elseif x.kind == 'command' then
      has_command = true
      if x.name == 'help' then
        has_help_command = true
      end
    end
  end

  if not has_help_option then
    cmd[#cmd + 1] = flag.option('help', {
      short = 'h',
      description = "help for " .. cmd.path,
      action = function()
        help.print_help(cmd)
        cmd.exit(0)
      end,
    })
  end

  if has_command and not has_help_command then
    cmd[#cmd + 1] = flag.command('help', {
      summary = "Help provides help for any command in the application",
      description = 'Help for any command',
      flag.argument('command'),
      action = function(self, ctx)
        if not ctx.command then
          print_help(cmd)
        else
          local c = ctx.command and util.first(cmd, function(x)
            return x.kind == 'command' and x.name == ctx.command
          end)
          if c then
            print_help(c)
          else
            print_errorf(self, "Unknown help topic '%s'", ctx.command)
            print_usage(self)
            cmd.exit(1)
          end
        end
      end
    })
  end
end

local function setup_version_flags(cmd)
  if not cmd.version or cmd.hide_version then
    return
  end

  local has_version_option, has_version_command
  for _, x in ipairs(cmd) do
    if x.kind == 'option' then
      if x.long == 'version' or x.short == 'V' then
        has_version_option = true
      end
    elseif x.kind == 'command' then
      if x.name == 'version' then
        has_version_command = true
      end
    end
  end

  local desc = cmd.kind == 'command' and "Show the command name and version" or "Show the program name and version"
  if not has_version_option then
    cmd[#cmd + 1] = flag.option('version', {
      short = 'V',
      description = desc,
      action = function()
        print_version(cmd)
        cmd.exit(0)
      end
    })
  end

  if not has_version_command then
    cmd[#cmd + 1] = flag.command('version', {
      description = desc,
      action = function()
        print_version(cmd)
      end
    })
  end
end

function set_parent(cmd, parent)
  cmd.parent = parent
  if parent then
    cmd.error_writer = parent.error_writer
    cmd.exit = parent.exit
    cmd.hide_help = parent.hide_help
    cmd.hide_version = parent.hide_version
    cmd.writer = parent.writer
  end
  setup_version_flags(cmd)
  setup_help_flags(cmd)
end

local function exit(c, err)
  if c.exit then
    c.exit(err and 1 or 0)
  end
  return c, err
end

function run(cmd, args)
  local parser = require('ldk.cli.parser')
  local c, ctx, err = parser.parse(cmd, args or {})
  if err then
    if not cmd.noerrors and not c.noerrors then
      print_errorln(c, "Error: ", err)
      print_errorf(c, "Run '%s --help' for usage\n", cmd.path)
    end
    return exit(c, err)
  end

  if c.validate then
    err = c.validate(c, ctx)
  end
  if not err and c.action then
    err = c.action(c, ctx)
  end
  if err then
    if not cmd.noerrors and not c.noerrors then
      print_errorln(c, "Error: ", err)
    end
    if not cmd.nousage and not c.nousage then
      print_usage(c)
    end
  end
  return exit(c, err)
end

local function chars(s)
  local r = {}
  for c in s:gmatch('.') do
    r[#r + 1] = c
  end
  return r
end

local function distance(s, t)
  if #s == 0 then
    return #t
  end
  if #t == 0 then
    return #s
  end
  s, t = chars(s), chars(t)
  local v0, v1 = {}, {}
  for i = 0, #t do
    v0[i] = i
  end
  for i = 1, #s do
    v1[0] = i
    for j = 1, #t do
      local dc = v0[j] + 1
      local ic = v1[j - 1] + 1
      local sc = v0[j - 1] + (s[i] == t[j] and 0 or 1)
      v1[j] = math_min(dc, math_min(ic, sc))
    end
    v0, v1 = v1, v0
  end
  return v0[#t]
end

function find_suggestions(cmd, arg)
  local distance_threshold = cmd.distance_threshold
  if not distance_threshold or distance_threshold < 1 then
    distance_threshold = 2
  end
  local suggestions = {}
  -- luacheck: push ignore flag
  for _, flag in ipairs(cmd) do
    if flag.kind == 'command' and not flag.hidden then
      local suggested_by_distance = distance(arg, flag.name) < distance_threshold
      local suggested_by_prefix = flag.name:find(arg) == 1
      if suggested_by_distance or suggested_by_prefix then
        suggestions[#suggestions + 1] = flag.name
      end
    end
  end
  -- luacheck: pop
  return suggestions
end

return M
