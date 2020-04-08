local queries = {}

local ops = {
  eq      = function(clause) return queries.simpleOp(" = ", clause) end,
  neq     = function(clause) return queries.simpleOp(" != ", clause) end,
  lt      = function(clause) return queries.simpleOp(" < ", clause) end,
  lte     = function(clause) return queries.simpleOp(" <= ", clause) end,
  gt      = function(clause) return queries.simpleOp(" > ", clause) end,
  gte     = function(clause) return queries.simpleOp(" >= ", clause) end,
  is      = function(clause) return queries.arrayOp(" IN ", clause) end,
  ["and"] = function(clause) return queries.subquery(" AND ", clause) end,
  ["or"]  = function(clause) return queries.subquery(" OR ", clause) end,
  sort    = function(clause, meta)
    meta.sort = clause.arguments[1]
  end,
  limit   = function(clause, meta)
    meta.limit = clause.arguments[1]
  end,
  fields  = function(clause, meta)
    meta.fields = clause.arguments[1]
  end,
}

local function query(query)
  local result, meta = {}, {}
  for _, clause in pairs(query) do
    local op = ops[clause.operation]
    if op then
      local res = op(clause, meta)
      if res then
        result[#result+1] = res
      end
    else
      error("Unsupported query operation '"..clause.operation.."'")
    end
  end
  return table.concat(result, ' AND '), meta
end

function queries.simpleOp(op, clause)
  local argument = clause.arguments[1]
  if type(argument) == "string" then
    argument = ngx.quote_sql_str(argument)
  end
  return clause.field..op..argument
end

function queries.arrayOp(op, clause)
  -- TODO - support SELECT subqueries
  local argument = clause.arguments[1]
  local newArgs = {}
  for _, v in pairs(argument) do
    if type(v) == 'string' then
      newArgs[#newArgs+1] = ngx.quote_sql_str(v)
    else
      newArgs[#newArgs+1] = v
    end
  end
  return clause.field..op..'('..table.concat(newArgs, ' ,')..')'
end

function queries.subquery(op, clause)
  local result = {}
  for i=1, #clause.arguments do
    result[#result+1]=query(clause.arguments[i])
  end
  return " AND ("..table.concat(result, op)..")"
end

return query
