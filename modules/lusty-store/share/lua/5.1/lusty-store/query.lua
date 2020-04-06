--the purpose of this file is to implement a generic monad capable of creating
--data store independent queries that can then be injested, compiled, and cached
--by a particular data event handler

--create a configured operation
local function clause(context, ...)
  return {
    field     = context.last,
    operation = context.key,
    arguments = {...}
  }
end

--all available query operations
local ops = {
  eq      = clause,
  neq     = clause,
  reg     = clause,
  gt      = clause,
  lt      = clause,
  lte     = clause,
  gte     = clause,
  is      = clause,
  has     = clause,
  isnot   = clause,
  sort    = clause,

  ["and"] = clause,
  ["or"]  = clause,
  limit   = clause,
  fields  = clause,
  inc     = clause
}

--meta table functions, used by wrap
local function call(self, context, ...)

  if not ops[context.key] then
    error("Invalid operation '"..context.key.."'")
  end

  if ops[context.last] then
    context.last = nil
  end

  --add clause to document
  local value = ops[context.key](context, ...)

  if value then self[#self+1] = value end

  return self
end

local function index(self, context, key)

  context.last  = context.key
  context.key   = key
  return self
end
--end meta table functions

--create meta table with context in closure and wrap query.
local function wrap(query)

  local context = {}

  return setmetatable(query, {

    __index = function(self, key)
      return index(self, context, key)
    end,

    __call = function(self, ...)
      return call(self, context, ...)
    end,

    __div = function(self, ...) -- eg. q1 / q2
      return call(index(self, context, "or"), context, ...)
    end,

    __add = function(self, ...) -- eg. q1 + q2
      return call(index(self, context, "and"), context, ...)
    end
  })
end

--return closure that creates a new query on call and index.
--call can copy an existing query
--index can modify context with intention of adding clauses
return setmetatable({}, {

  --copy query eg. Query(query)
  __call = function(self, query)
    return wrap(query and {unpack(query)} or {})
  end,

  --create new query eg. Query.field1.eq(false)
  __index = function(self, key)
    return wrap({})[key]
  end
})
