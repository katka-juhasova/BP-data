local M = {}

local checks = require 'ldk.checks'
local reader = require 'ldk.cli.reader'
local schema = require 'ldk.cli.schema'
local util = require 'ldk.cli.util'

local error = error
local type = type
local math_max = math.max

local _ENV = M

local function setup_occurrences(flag)
  if flag.unbound and flag.once then
    error("property 'once' conflicts with 'unbound'")
  end
  if flag.unbound and flag.count then
    error("property 'count' conflicts with 'unbound'")
  end
  if flag.once and flag.count then
    error("property 'once' conflicts with 'count'")
  end

  local mincount = flag.count or 0
  local maxcount = flag.count or 1
  flag.mincount = flag.mincount or mincount
  flag.maxcount = flag.maxcount or maxcount
  if flag.unbound then
    flag.maxcount = nil
  end
  if flag.once then
    flag.maxcount = 1
  end
  if flag.required then
    flag.mincount = math_max(1, flag.mincount)
  end
end

local CommandOpts = {
  'action',
  'aliases',
  'description',
  'examples',
  'group',
  'hidden',
  'summary',
  'validate'
}

local CommandSchema = {
  aliases = 'nil|string+',
  action = 'nil|function',
  description = 'nil|string',
  examples = 'nil|string+',
  group = 'nil|string',
  hidden = 'nil|boolean',
  name = 'string',
  summary = 'nil|string',
  validate = 'nil|function'
}

function command(name, opts)
  checks.checktypes('string', '?table')
  local c = {
    kind = 'command',
    name = name
  }
  util.merge(opts, c, CommandOpts)
  util.append(opts, c)
  schema.validate(c, CommandSchema)
  return c
end

local OptionOpts = {
  'action',
  'short',
  'argname',
  'conflicts',
  'count',
  'default',
  'description',
  'global',
  'group',
  'hidden',
  'maxcount',
  'mincount',
  'once',
  'required',
  'unbound',
  'type',
  'validate'
}

local OptionSchema = {
  long = function(s)
    local err = schema.validate(s, 'string')
    if not err and #s < 2 then
      err = ("string length must greater than 1, got '%s'"):format(s)
    end
    return err
  end,
  short = function(s)
    local err = schema.validate(s, 'nil|string')
    if not err and s and #s ~= 1 then
      err = ("string length must be 1, got '%s'"):format(s)
    end
    return err
  end,
  action = 'nil|function',
  argname = 'nil|string',
  conflicts = 'nil|string*',
  count = 'nil|integer',
  description = 'nil|string',
  global = 'nil|boolean',
  group = 'nil|string',
  hidden = 'nil|boolean',
  maxcount = 'nil|integer',
  mincount = 'nil|integer',
  once = 'nil|boolean',
  required = 'nil|boolean',
  type = 'nil|string',
  unbound = 'nil|boolean',
  validate = 'nil|function'
}

function option(long, short, opts)
  checks.checktypes('string', '?string|table', '?table')
  if type(short) == 'table' then
    opts, short = short, nil
  end
  checks.checkarg(1, #long > 1, "string's must be greater than 1")
  checks.checkarg(2, not short or #short == 1, "string's must be greater than 1")
  local o = {
    kind = 'option',
    long = long,
    short = short,
  }
  util.merge(opts, o, OptionOpts)
  setup_occurrences(o)
  o.type = o.type or 'nil'
  o.reader = reader.create(o.type, true)
  schema.validate(o, OptionSchema)
  return o
end

local ArgumentOpts = {
  'action',
  'count',
  'default',
  'description',
  'maxcount',
  'mincount',
  'once',
  'required',
  'type',
  'unbound',
  'validate'
}

local ArgumentSchema = {
  name = 'string',
  action = 'nil|function',
  count = 'nil|integer',
  description = 'nil|string',
  hidden = 'nil|boolean',
  maxcount = 'nil|integer',
  mincount = 'nil|integer',
  once = 'nil|boolean',
  required = 'nil|boolean',
  type = 'nil|string',
  unbound = 'nil|boolean',
  validate = 'nil|function'
}

function argument(name, opts)
  checks.checktypes('string', '?table')
  local a = {
    kind = 'argument',
    name = name
  }
  util.merge(opts, a, ArgumentOpts)
  setup_occurrences(a)
  a.type = a.type or 'string'
  a.reader = reader.create(a.type)
  if a.reader.type ~= 'single' or not a.reader.requires_arg then
    error('invalid argument type: ' .. a.type)
  end
  schema.validate(a, ArgumentSchema)
  return a
end

return M
