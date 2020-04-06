local p, y, colorall
do
  local _obj_0 = require("ltypekit-parser.config")
  p, y, colorall = _obj_0.p, _obj_0.y, _obj_0.colorall
end
p("==> Running ltypekit-parser")
local index
index = function(t)
  return function(i)
    local _exp_0 = type(t)
    if "table" == _exp_0 then
      return t[i]
    elseif "string" == _exp_0 then
      return t:sub(i, i)
    end
  end
end
local insert
insert = function(t)
  return function(v)
    return table.insert(t, v)
  end
end
local remove
remove = function(t)
  return function(i)
    return function(e)
      local x = table.remove(t, i)
      return (x == e) and x or false
    end
  end
end
local concat
concat = function(t)
  return function(s)
    local newt
    do
      local _tbl_0 = { }
      for k, v in pairs(t) do
        _tbl_0[k] = tostring(v)
      end
      newt = _tbl_0
    end
    return table.concat(newt, s)
  end
end
local pack
pack = function(...)
  return {
    ...
  }
end
local map
map = function(f)
  return function(t)
    local _accum_0 = { }
    local _len_0 = 1
    for _index_0 = 1, #t do
      local v = t[_index_0]
      _accum_0[_len_0] = f(v)
      _len_0 = _len_0 + 1
    end
    return _accum_0
  end
end
local unpack = unpack or table.unpack
local isUpper
isUpper = function(s)
  return s:match("^%u")
end
local isLower
isLower = function(s)
  return s:match("^%l")
end
local selectFirst
selectFirst = function(...)
  return select(1, ...)
end
local selectLast
selectLast = function(...)
  local argl = {
    ...
  }
  return argl[#argl]
end
local head
head = function(t)
  return selectFirst(unpack(t))
end
local last
last = function(t)
  return selectLast(unpack(t))
end
local tail
tail = function(t)
  return (function()
    local _accum_0 = { }
    local _len_0 = 1
    for _index_0 = 2, #t do
      local v = t[_index_0]
      _accum_0[_len_0] = v
      _len_0 = _len_0 + 1
    end
    return _accum_0
  end)()
end
local init
init = function(t)
  return (function()
    local _accum_0 = { }
    local _len_0 = 1
    local _max_0 = #t - 1
    for _index_0 = 1, _max_0 < 0 and #t + _max_0 or _max_0 do
      local v = t[_index_0]
      _accum_0[_len_0] = v
      _len_0 = _len_0 + 1
    end
    return _accum_0
  end)()
end
local applSplit
applSplit = function(appl)
  if (type(appl)) ~= "string" then
    return appl
  end
  if (appl:gsub("%b()", "")):match("[-=]>") then
    return appl
  end
  local x
  do
    local _accum_0 = { }
    local _len_0 = 1
    for part in appl:gmatch("%S+") do
      _accum_0[_len_0] = part
      _len_0 = _len_0 + 1
    end
    x = _accum_0
  end
  x.__appl = true
  setmetatable(x, {
    __tostring = function(self)
      return (concat(self))(" ")
    end
  })
  if #x > 1 then
    return x
  else
    return appl
  end
end
local contextSplit
contextSplit = function(context)
  local _accum_0 = { }
  local _len_0 = 1
  for constraint in context:gmatch("[^,()]+") do
    _accum_0[_len_0] = constraint
    _len_0 = _len_0 + 1
  end
  return _accum_0
end
local multiargSplit
multiargSplit = function(arg)
  if (type(arg)) ~= "string" then
    return arg
  end
  local x
  do
    local _accum_0 = { }
    local _len_0 = 1
    for par in arg:gmatch("[^,]+") do
      _accum_0[_len_0] = applSplit(par)
      _len_0 = _len_0 + 1
    end
    x = _accum_0
  end
  x.__multi = true
  if #x > 1 then
    return x
  else
    return arg
  end
end
local removeTopMostParens
removeTopMostParens = function(str)
  if (type(str)) ~= "string" then
    return str
  end
  local _, countOpen = str:gsub("%(", "")
  local countClosed
  _, countClosed = str:gsub("%)", "")
  if (str:match("^%(")) and (str:match("%)$")) and (countOpen == 1) and (countClosed == 1) then
    return str:sub(2, -2)
  end
  return str
end
local applToPattern
applToPattern = function(cons)
  local parts = { }
  for word in cons:gmatch("%S+") do
    if isLower(word) then
      table.insert(parts, "(.-)")
    else
      table.insert(parts, word)
    end
  end
  return table.concat(parts, " ")
end
local applyLists
applyLists = function(a, c)
  if (type(a)) ~= "string" then
    return a
  end
  do
    local list = a:match("^%b[]$")
    if list then
      return {
        list:sub(2, -2),
        __list = true,
        context = c
      }
    else
      return a
    end
  end
end
local applyTables
applyTables = function(a, c)
  if (type(a)) ~= "string" then
    return a
  end
  do
    local tbl = a:match("^%b{}$")
    if tbl then
      return {
        tbl:match("^{(.-):"),
        tbl:match(":(.-)}$"),
        __table = true,
        context = c
      }
    else
      return a
    end
  end
end
local compareCons
compareCons = function(c1)
  return function(c2)
    local pat1 = applToPattern(c1)
    if c2:match(pat1) then
      return true
    else
      p("err trig here")
      return false, "compareAppl $ unmatching type application. Expected " .. tostring(c1) .. ", got " .. tostring(c2)
    end
  end
end
local normalizeContext
normalizeContext = function(c)
  local final = { }
  for _index_0 = 1, #c do
    local constraint = c[_index_0]
    local parts
    do
      local _accum_0 = { }
      local _len_0 = 1
      for p in constraint:gmatch("%S+") do
        _accum_0[_len_0] = p
        _len_0 = _len_0 + 1
      end
      parts = _accum_0
    end
    final[last(parts)] = init(parts)
  end
  return final
end
local mergeContext
mergeContext = function(c1)
  return function(c2)
    local cf
    do
      local _tbl_0 = { }
      for k, v in pairs(c1) do
        do
          local _accum_0 = { }
          local _len_0 = 1
          for _index_0 = 1, #v do
            local ap = v[_index_0]
            _accum_0[_len_0] = ap
            _len_0 = _len_0 + 1
          end
          _tbl_0[k] = _accum_0
        end
      end
      cf = _tbl_0
    end
    for k, v in pairs(c2) do
      if cf[k] then
        for _index_0 = 1, #v do
          local ap = v[_index_0]
          table.insert(cf[k], ap)
        end
      else
        cf[k] = v
      end
    end
    return cf
  end
end
local binarize
binarize = function(signature, context)
  if context == nil then
    context = { }
  end
  local sigName
  do
    signature = signature:gsub("^(.-)%s*%?%s*", function(name)
      sigName = name
      return ""
    end)
    signature = signature:gsub(" *%-> *", "->")
    signature = signature:gsub(" *%=> *", "=>")
    signature = signature:gsub(",%s", ",")
  end
  signature = removeTopMostParens(signature)
  local getNext
  local tree = {
    left = "",
    right = "",
    context = ""
  }
  local right = false
  local aggl
  aggl = function(ch)
    if right then
      tree.right = tree.right .. ch
    else
      tree.left = tree.left .. ch
    end
  end
  local nextIs
  nextIs = function(tag)
    return function()
      return tag
    end
  end
  local _stack = { }
  local push = insert(_stack)
  local pop = (remove(_stack))(1)
  local peek
  peek = function()
    return _stack[1]
  end
  local depth = 0
  local col = 0
  for char in signature:gmatch(".") do
    local _continue_0 = false
    repeat
      col = col + 1
      local column = index(signature)
      local _exp_0 = char
      if "(" == _exp_0 then
        depth = depth + 1
        push("par")
        aggl(char)
      elseif ")" == _exp_0 then
        depth = depth - 1
        if depth < 0 then
          error("binarize $ unmatching parentheses at column " .. tostring(col) .. " in '" .. tostring(signature) .. "'")
        end
        pop("par")
        aggl(char)
      elseif "-" == _exp_0 then
        if right or depth > 0 then
          aggl(char)
          _continue_0 = true
          break
        end
        if (column(col + 1)) ~= ">" then
          error("binarize $ expected '>' at column " .. tostring(col + 1) .. " in '" .. tostring(signature) .. "'")
        end
        getNext = nextIs("set-right")
      elseif "=" == _exp_0 then
        if right or depth > 0 then
          aggl(char)
          _continue_0 = true
          break
        end
        if (column(col + 1)) ~= ">" then
          error("binarize $ expected '>' at column " .. tostring(col + 1) .. " in '" .. tostring(signature) .. "'")
        end
        getNext = nextIs("set-context")
      elseif ">" == _exp_0 then
        if right or depth > 0 then
          aggl(char)
          _continue_0 = true
          break
        end
        if (column(col - 1)):match("[^-=]") then
          error("binarize $ unexpected '>' at column " .. tostring(col) .. " in '" .. tostring(signature) .. "'")
        end
        local _exp_1 = getNext()
        if "set-right" == _exp_1 then
          right = true
        elseif "set-context" == _exp_1 then
          tree.context = tree.left
          tree.left = ""
        else
          error("binarize $ unexpected tag '" .. tostring(tag) .. "'")
        end
      else
        aggl(char)
      end
      _continue_0 = true
    until true
    if not _continue_0 then
      break
    end
  end
  if tree.right == "" then
    tree.right = tree.left
    tree.left = ""
  end
  tree.context = normalizeContext(contextSplit(tree.context))
  for _index_0 = 1, #context do
    local constraint = context[_index_0]
    table.insert(tree.context, constraint)
  end
  do
    local _tbl_0 = { }
    for k, v in pairs(tree) do
      _tbl_0[k] = removeTopMostParens(v)
    end
    tree = _tbl_0
  end
  do
    local _tbl_0 = { }
    for k, v in pairs(tree) do
      _tbl_0[k] = multiargSplit(v)
    end
    tree = _tbl_0
  end
  do
    local _tbl_0 = { }
    for k, v in pairs(tree) do
      _tbl_0[k] = applSplit(v)
    end
    tree = _tbl_0
  end
  do
    local _tbl_0 = { }
    for k, v in pairs(tree) do
      _tbl_0[k] = applyLists(v, tree.context)
    end
    tree = _tbl_0
  end
  do
    local _tbl_0 = { }
    for k, v in pairs(tree) do
      _tbl_0[k] = applyTables(v, tree.context)
    end
    tree = _tbl_0
  end
  tree.name = sigName
  tree.__fn = true
  tree.__sig = signature
  return setmetatable(tree, {
    __tostring = function(self)
      return self.__sig
    end
  })
end
local rbinarize
rbinarize = function(signature, context, topmost)
  if context == nil then
    context = { }
  end
  if topmost == nil then
    topmost = true
  end
  local tree = binarize(signature, context)
  if ((type(tree.left)) == "string") and tree.left:match("[=-]>") then
    tree.left = rbinarize(tree.left, tree.context, false)
  elseif ((type(tree.left)) == "table") and tree.left.__appl then
    if tree.left[2]:match("[=-]>") then
      tree.left[2] = rbinarize(tree.left[2], tree.context, false)
    end
  elseif ((type(tree.left)) == "table") and tree.left.__list then
    if tree.left[1]:match("[=-]>") then
      tree.left[1] = rbinarize(tree.left[1], tree.context, false)
    end
  elseif ((type(tree.left)) == "table") and tree.left.__table then
    if tree.left[1]:match("[=-]>") then
      tree.left[1] = rbinarize(tree.left[1], tree.context, false)
    end
    if tree.left[2]:match("[=-]>") then
      tree.left[2] = rbinarize(tree.left[2], tree.context, false)
    end
  end
  if ((type(tree.right)) == "string") and tree.right:match("[=-]>") then
    tree.right = rbinarize(tree.right, tree.context, false)
  elseif ((type(tree.right)) == "table") and tree.right.__appl then
    if tree.right[2]:match("[=-]>") then
      tree.right[2] = rbinarize(tree.right[2], tree.context, false)
    end
  elseif ((type(tree.right)) == "table") and tree.right.__list then
    if tree.right[1]:match("[=-]>") then
      tree.right[1] = rbinarize(tree.right[1], tree.context, false)
    end
  elseif ((type(tree.right)) == "table") and tree.right.__table then
    if tree.right[1]:match("[=-]>") then
      tree.right[1] = rbinarize(tree.right[1], tree.context, false)
    end
    if tree.right[2]:match("[=-]>") then
      tree.right[2] = rbinarize(tree.right[2], tree.context, false)
    end
  end
  return tree
end
local annotatePar
annotatePar = function(par, conl)
  for _index_0 = 1, #conl do
    local cons = conl[_index_0]
    local p_
    do
      local _accum_0 = { }
      local _len_0 = 1
      for pa in cons:gmatch("%S+") do
        _accum_0[_len_0] = pa
        _len_0 = _len_0 + 1
      end
      p_ = _accum_0
    end
    p("-> annotpar", p_[#p_], cons)
    par = par:gsub(p_[#p_], cons)
  end
  return par
end
local compare
local compareAppl = compareCons
local isTable
isTable = function(t)
  return (type(t)) == "table"
end
local isString
isString = function(s)
  return (type(s)) == "string"
end
local compareApplN
compareApplN = function(base)
  return function(against)
    for _index_0 = 1, #base do
      local part1 = base[_index_0]
      for _index_1 = 1, #against do
        local part2 = against[_index_1]
        if (isString(part1)) and (isString(part2)) then
          if part1:match("^%u") and part2:match("^%u") then
            if not (part1 == part2) then
              return false, "compareApplN $ unmatching type application. got " .. tostring(part2) .. ", expected " .. tostring(part1)
            end
          end
        elseif (isTable(part1)) and (isTable(part2)) then
          return (compare(part1))(part2)
        else
          return false, "compareApplN $ mismatching types in type application. got " .. tostring(type(part2)) .. ", expected " .. tostring(type(part1))
        end
      end
    end
    return true
  end
end
local compareList
compareList = function(base)
  return function(against)
    local t1, t2 = base[1], against[1]
    if (isString(t1)) and (isString(t2)) then
      if t1:match("^%u") and t2:match("^%u") then
        if not (t1 == t2) then
          return false, "compareList $ unmatching list. got " .. tostring(t2) .. ", expected " .. tostring(t1)
        end
      end
    elseif (isTable(t1)) and (isTable(t2)) then
      return (compare(t1))(t2)
    else
      return false, "compareList $ mismatching types in list. got " .. tostring(type(t2)) .. ", expected " .. tostring(type(t1))
    end
    return true
  end
end
local compareTable
compareTable = function(base)
  return function(against)
    local t1a, t1b, t2a, t2b = base[1], base[2], against[1], against[2]
    if (isString(t1a)) and (isString(t2a)) then
      if t1a:match("^%u") and t2a:match("^%u") then
        if not (t1a == t2a) then
          return false, "compareTable $ unmatching table key. got " .. tostring(t2a) .. ", expected " .. tostring(t1a)
        end
      end
    elseif (isTable(t1a)) and (isTable(t2a)) then
      return (compare(t1a))(t2a)
    else
      return false, "compareTable $ mismatching types in table key. got " .. tostring(type(t2a)) .. ", expected " .. tostring(type(t1a))
    end
    if (isString(t1b)) and (isString(t2b)) then
      if t1b:match("^%u") and t2b:match("^%u") then
        if not (t1b == t2b) then
          return false, "compareTable $ unmatching table value. got " .. tostring(t2b) .. ", expected " .. tostring(t1b)
        end
      end
    elseif (isTable(t1b)) and (isTable(t2b)) then
      return (compare(t1b))(t2b)
    else
      return false, "compareTable $ mismatching types in table value. got " .. tostring(type(t2b)) .. ", expected " .. tostring(type(t1b))
    end
    return true
  end
end
isTable = function(t)
  return (type(t)) == "table"
end
isString = function(s)
  return (type(s)) == "string"
end
isLower = function(s)
  return s:match("^%l")
end
isUpper = function(s)
  return s:match("^%u")
end
local hasMulti
hasMulti = function(t)
  return ((type(t)) == "table") and t.__multi
end
local compareMixed
compareMixed = function(base)
  return function(against)
    if (isString(base)) and (isTable(against)) then
      if (isLower(base)) then
        return true
      else
        if against.__appl then
          return (base == against[#against])
        else
          return false
        end
      end
    else
      return false
    end
  end
end
compare = function(base)
  return function(against)
    local shape = { }
    p("-> base", y(base))
    p("-> against", y(against))
    if not ((type(base)) == (type(against))) then
      p("!! rf/1")
      return false, "compare $ base and against are not of the same type. base is " .. tostring(type(base)) .. " and against is " .. tostring(type(against))
    end
    if base.__fn and against.__fn then
      p(":: compare/fn")
      local equalConstraints = 0
      local _list_0 = base.context
      for _index_0 = 1, #_list_0 do
        local cons1 = _list_0[_index_0]
        local _list_1 = against.context
        for _index_1 = 1, #_list_1 do
          local cons2 = _list_1[_index_1]
          p(cons1, cons2)
          if (compareCons(cons1))(cons2) then
            equalConstraints = equalConstraints + 1
          end
        end
      end
      if not (equalConstraints >= #base.context) then
        p("!! rf/2")
        return false, "compare $ not all constraints matched. got " .. tostring(equalConstraints) .. ", expected " .. tostring(#base.context)
      end
      if (isString(base.left)) and (isString(against.left)) then
        base.left = annotatePar(base.left, base.context)
        against.left = annotatePar(against.left, against.context)
        local r, err = (compareAppl(base.left))(against.left)
        if not (r) then
          p("!! rf/3")
          p(r, err)
          return false, err
        end
      elseif (isTable(base.left)) and (isTable(against.left)) then
        local r, err = (compare(base.left))(against.left)
        if not (r) then
          p("!! rf/4")
          return false, err
        end
      else
        local r, err = (compareMixed(base.left))(against.left)
        if not (r) then
          p("!! rf/5")
          return false, "compare $ mismatch in left side. base.left is " .. tostring(type(base.left)) .. ", against.left is " .. tostring(type(against.left))
        end
      end
      if (isString(base.right)) and (isString(against.right)) then
        base.right = annotatePar(base.right, base.context)
        against.right = annotatePar(against.right, against.context)
        local r, err = (compareAppl(base.right))(against.right)
        if not (r) then
          p("!! rf/6")
          return false, err
        end
      elseif (isTable(base.right)) and (isTable(against.right)) then
        local r, err = (compare(base.right))(against.right)
        if not (r) then
          p("!! rf/7")
          p("!! rf/7", (y(base.right)), (y(against.right)))
          return false, err
        end
      else
        local r, err = (compareMixed(base.right))(against.right)
        if not (r) then
          p("!! rf/8")
          p((y(base.right)), (y(against.right)))
          return false, "compare $ cannot compare sides. base.right is " .. tostring(type(base.right)) .. ", against.right is " .. tostring(type(against.right))
        end
      end
      return true
    elseif base.__appl and against.__appl then
      p(":: compare/appl")
      local r, err = (compareApplN(base))(against)
      if not (r) then
        p("!! rf/9")
        return false, err
      end
      return true
    elseif base.__list and against.__list then
      p("!! compare/list")
      local r, err = (compareList(base))(against)
      if not (r) then
        p("!! rf/10")
        return false, err
      end
      return true
    elseif base.__table and against.__table then
      p("compare/table")
      local r, err = (compareTable(base))(against)
      if not (r) then
        p("!! rf/11")
        return false, err
      end
      return true
    else
      p("!! rf/12")
      return false, "compare $ cannot compare base and against"
    end
  end
end
local annotateAppl
annotateAppl = function(ap1)
  return function(ap2)
    return function(cache)
      p("-> appl", ap1, ap2, y(cache))
      if ap1:match("^%l") and ap2:match("^%u") then
        cache[ap1] = ap2
      end
      return cache
    end
  end
end
local isNList
isNList = function(t)
  return t.__list
end
local isNTable
isNTable = function(t)
  return t.__table
end
local annotate
annotate = function(base)
  return function(against)
    return function(cache, i)
      if cache == nil then
        cache = { }
      end
      if i == nil then
        i = 1
      end
      p("========================")
      p("-> annot-base", i, y(base))
      p("-> annot-against", i, y(against))
      if (isString(base.left)) and (isString(against.left)) then
        p("* annot-l", base.left, against.left)
        base.left = annotatePar(base.left, base.context)
        against.left = annotatePar(against.left, against.context)
        p("* annot-l-an", base.left, against.left)
        local err
        cache, err = ((annotateAppl(base.left))(against.left))(cache)
        if not (cache) then
          return false, (err or "l"), 1
        end
      elseif (isTable(base.left)) and (isTable(against.left)) then
        local err, n
        cache, err, n = ((annotate(base.left))(against.left))(cache, i + 1)
        if not (cache) then
          p("!! Propagated!")
        end
        if not (cache) then
          return false, (err or "L"), n
        end
      elseif (isNList(base)) and (isNList(against)) then
        base[1] = annotatePar(base[1], base.context)
        against[1] = annotatePar(against[1], against.context)
        local err, n
        cache, err, n = ((annotateAppl(base[1]))(against[1]))(cache)
        if not (cache) then
          return false, (err or "Rr"), n
        end
      else
        p("!! Raised!")
        return false, "annotate $ mismatch in left side. base.left is " .. tostring(type(base.left)) .. ", against.left is " .. tostring(type(against.left)), 2
      end
      if (isString(base.right)) and (isString(against.right)) then
        p("* annot-r", base.right, against.right)
        base.right = annotatePar(base.right, base.context)
        against.right = annotatePar(against.right, against.context)
        p("* annot-r-an", base.right, against.right)
        local err, n
        cache, err, n = ((annotateAppl(base.right))(against.right))(cache)
        if not (cache) then
          return false, (err or "r"), n
        end
      elseif (isTable(base.right)) and (isTable(against.right)) then
        local err, n
        cache, err, n = ((annotate(base.right))(against.right))(cache, i + 1)
        if not (cache) then
          p("!! Propagated!")
        end
        if not (cache) then
          return false, (err or "R"), n
        end
      elseif (isNList(base)) and (isNList(against)) then
        base[1] = annotatePar(base[1], base.context)
        against[1] = annotatePar(against[1], against.context)
        local err, n
        cache, err, n = ((annotateAppl(base[1]))(against[1]))(cache)
        if not (cache) then
          return false, (err or "Rr"), n
        end
      else
        p("!! Raised!")
        return false, "annotate $ mismatch in right side. base.right is " .. tostring(type(base.right)) .. ", against.right is " .. tostring(type(against.right)), 4
      end
      return cache, "", 5
    end
  end
end
return {
  contextSplit = contextSplit,
  removeTopMostParens = removeTopMostParens,
  applToPattern = applToPattern,
  binarize = binarize,
  rbinarize = rbinarize,
  annotatePar = annotatePar,
  annotate = annotate,
  compareAppl = compareAppl,
  compare = compare,
  normalizeContext = normalizeContext,
  mergeContext = mergeContext
}
