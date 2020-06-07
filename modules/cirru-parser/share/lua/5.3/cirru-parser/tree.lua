local array = require('cirru-parser.array')
local inspect = require('inspect')
local concat = array.concat
local append = array.append
local init = array.init
local size = array.size
local isArray = array.isArray
local tail = array.tail
local appendItem
appendItem = function(xs, level, buffer)
  if level == 0 then
    return append(xs, buffer)
  else
    local res = appendItem(xs[size(xs)], (level - 1), buffer)
    return append((init(xs)), res)
  end
end
local createHelper
createHelper = function(xs, n)
  if n <= 1 then
    return xs
  else
    return {
      createHelper(xs, (n - 1))
    }
  end
end
local createNesting
createNesting = function(n)
  return createHelper({ }, n)
end
local resolveDollar = nil
local resolveComma = nil
local dollarHelper
dollarHelper = function(before, after)
  if (size(after)) == 0 then
    return before
  end
  local cursor = after[1]
  if (isArray(cursor)) then
    return dollarHelper((append(before, (resolveDollar(cursor)))), (tail(after)))
  else
    if cursor.text == '$' then
      return append(before, (resolveDollar((tail(after)))))
    else
      return dollarHelper((append(before, cursor)), (tail(after)))
    end
  end
end
resolveDollar = function(xs)
  if (size(xs)) == 0 then
    return xs
  end
  return dollarHelper({ }, xs)
end
local commaHelper
commaHelper = function(before, after)
  if (size(after)) == 0 then
    return before
  end
  local cursor = after[1]
  if (isArray(cursor)) and ((size(cursor)) > 0) then
    local head = cursor[1]
    if isArray(head) then
      return commaHelper((append(before, (resolveComma(cursor)))), (tail(after)))
    else
      if head.text == ',' then
        return commaHelper(before, (concat((resolveComma((tail(cursor)))), (tail(after)))))
      else
        return commaHelper((append(before, (resolveComma(cursor)))), (tail(after)))
      end
    end
  else
    return commaHelper((append(before, cursor)), (tail(after)))
  end
end
resolveComma = function(xs)
  if (size(xs)) == 0 then
    return xs
  end
  return commaHelper({ }, xs)
end
return {
  appendItem = appendItem,
  createNesting = createNesting,
  resolveDollar = resolveDollar,
  resolveComma = resolveComma
}
