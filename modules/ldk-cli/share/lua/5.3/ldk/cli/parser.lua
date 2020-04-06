local M = {}

local cmd = require 'ldk.cli.cmd'
local util = require 'ldk.cli.util'

local ipairs = ipairs
local pairs = pairs
local type = type

local table_concat = table.concat
local table_insert = table.insert
local table_remove = table.remove

local _ENV = M

local function find_suggestions(c, arg)
  if c.nosuggestions then
    return
  end

  local suggestions = cmd.find_suggestions(c, arg)
  if #suggestions == 0 then
    return
  end

  local buf = {}
  buf[#buf + 1] = "\n\nDid you mean?\n"
  for _, suggestion in ipairs(suggestions) do
    buf[#buf + 1] = '        '
    buf[#buf + 1] = suggestion
    buf[#buf + 1] = '\n'
  end
  return table_concat(buf)
end

local function is_option(s)
  return #s > 1 and s:find('-', 1, true) == 1
end

local function find_option(arg, options, global_options)

  local function find_by_name(name)
    local option = util.first(options, function(x)
      return x.long == name or x.short == name
    end)
    return option or util.first(global_options, function(x)
      return x.long == name or x.short == name
    end)
  end

  local function check_option(option, name, value)
    if not option then
      return ("unknown option '%s'"):format(name)
    end
    if value and option.reader.arity == 0 then
      return ("invalid argument to option '%s'"):format(name)
    end
  end

  -- -SV, -SK=V
  local pname, name, value = arg:match('^(%-([^-]))(.+)$')
  if name then
    local option = find_by_name(name)
    if not option.reader.requires_arg then
      local look_ahead = find_by_name(value:sub(1, 1))
      if look_ahead then
        arg, value = value, nil
      end
      local err = check_option(option, name, value)
      if err then
        return nil, nil, nil, nil, err
      end
      return option, name, value, arg
    end
  else
    -- -S
    pname, name = arg:match('^(%-([^-]))$')
  end
  if not name then
    -- --long:K=V
    pname, name, value = arg:match('^(%-%-([^:-]+)):(.+)$')
  end
  if not name then
    -- --long=V
    pname, name, value = arg:match('^(%-%-([^=-]+))=(.+)$')
  end
  if not name then
    -- --long
    name = arg
    pname = arg
  end

  local option = find_by_name(name)
  local err = check_option(option, pname, value)
  if err then
    return nil, nil, nil, nil, err
  end
  return option, name, value
end

local function find_command(name, commands)
  return util.first(commands, function(x)
    return x.name == name or util.contains(x.aliases, name)
  end)
end

local function apply(flag, arg, ctx)
  local value, err = flag.reader.read(arg)
  if err then
    return err
  end

  if flag.validate then
    err = flag.validate(ctx, value)
    if err then
      return err
    end
  end

  if flag.action then
    return flag.action(ctx, value)
  else
    local name = flag.name or flag.long
    if flag.reader.type == 'single' or flag.reader.type == 'tuple' then
      if not ctx[name] then
        ctx[name] = value
      elseif type(ctx[name]) == 'table' then
        table_insert(ctx[name], value)
      else
        ctx[name] = { ctx[name], value }
      end
    elseif flag.reader.type == 'list' or flag.reader.type == 'tuple-list' then
      if not ctx[name] then
        ctx[name] = value
      else
        util.append(ctx[name], value)
      end
    elseif flag.reader.type == 'map' then
      if not ctx[name] then
        ctx[name] = value
      else
        for k, v in pairs(value) do
          ctx[name][k] = v
        end
      end
    else
      -- we shouldn't really get here
      error("unknown reader type: " .. flag.reader.type)
    end
  end
end

function parse(c, args)

  local arg_index = 0
  local function next_arg()
    if arg_index < #args then
      arg_index = arg_index + 1
      return args[arg_index]
    end
  end

  local global_options = {}
  local ctx = {}

  local occurrences = {}
  local function handle_occurrence(flag)
    local current = occurrences[flag] or 0
    if flag.maxcount and flag.maxcount <= current then
      return false
    end
    occurrences[flag] = current + 1
    return true
  end

  -- luacheck: push ignore c
  local function visit(c, parent)
    cmd.set_parent(c, parent)

    util.appendif(c, global_options, function(x)
      return x.kind == 'option' and x.global
    end)
    local local_options = util.filter(c, function(x)
      return x.kind == 'option' and not x.global
    end)
    local local_arguments = util.filter(c, function(x)
      return x.kind == 'argument'
    end)
    local local_commands = util.filter(c, function(x)
      return x.kind == 'command'
    end)

    local function handle_option(arg)
      local option, name, value, err
      option, name, value, arg, err = find_option(arg, local_options, global_options)
      if err then
        return nil, ("%s for '%s'"):format(err, c.path)
      end
      if not handle_occurrence(option) then
        return ("option '%s' appeared too many times"):format(name)
      end
      if option.reader.requires_arg then
        value = value or next_arg()
        if not value then
          return ("missing argument for option '%s'"):format(name)
        end
      end
      return arg, apply(option, value, ctx)
    end

    local function handle_argument(arg)
      local argument = local_arguments[1]
      handle_occurrence(argument)
      if argument.maxcount and occurrences[argument] == argument.maxcount then
        table_remove(local_arguments, 1)
      end
      return apply(argument, arg, ctx)
    end

    local arguments = {}

    local function handle_arguments()
      if #arguments == 0 then
        return
      end
      local unparsed
      for _, arg in ipairs(arguments) do
        if #local_arguments == 0 then
          unparsed = unparsed or {}
          unparsed[#unparsed + 1] = arg
        else
          local err = handle_argument(arg)
          if err then
            return nil, err
          end
        end
      end
      return unparsed
    end

    local arg, unparsed, err

    local function eat_all()
      while arg do
        if arg ~= '--' then
          arguments[#arguments + 1] = arg
        end
        arg = next_arg()
      end
    end

    arg = next_arg()
    while arg do
      if arg == '--' then
        arg = next_arg()
        eat_all()
      elseif is_option(arg) then
        arg, err = handle_option(arg)
        if err then
          return c, nil, err
        end
        arg = arg or next_arg()
      else
        local subc = find_command(arg, local_commands)
        if subc then
          return visit(subc, c)
        end
        if #local_arguments == 0 and #local_commands > 0 then
          local suggestions = find_suggestions(c, arg)
          if suggestions then
            return c, nil, ("unknown command '%s' for '%s'%s"):format(arg, c.name, suggestions)
          end
          return c, nil, ("unknown command '%s' for '%s'"):format(arg, c.name)
        end
        eat_all()
      end
    end
    unparsed, err = handle_arguments()
    if err then return
      c, nil, err
    end

    ctx._ = unparsed

    for _, o in ipairs(local_options) do
      local count = occurrences[o] or 0
      if o.mincount and o.mincount > count then
        if count > 1 then
          return c, nil, ("option '%s' must appear at least %d times"):format(o.long, count)
        end
        return c, nil, ("missing required option '%s'"):format(o.long)
      end
    end

    for _, a in ipairs(local_arguments) do
      local count = occurrences[a] or 0
      if a.mincount and a.mincount > count then
        if count > 1 then
          return c, nil, ("argument '%s' must appear at least %d times"):format(a.name, count)
        end
        return c, nil, ("missing required argument '%s'"):format(a.name)
      end
    end

    return c, ctx
  end
  -- luacheck: pop

  return visit(c)
end

return M
