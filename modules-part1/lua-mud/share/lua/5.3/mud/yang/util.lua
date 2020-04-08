local json = require("json")

local _M = {}

local function tdump (tbl, indent)
  if not indent then indent = 0 end
  for k, v in pairs(tbl) do
    if k ~= 'parent' then
      formatting = string.rep(" ", indent) .. k .. ": "
      if type(v) == "table" then
        print(formatting)
        tdump(v, indent+1)
      elseif type(v) == 'boolean' then
        print(formatting .. tostring(v))
      elseif type(v) == 'function' then
        print(formatting .. "<function>")
      else
        print(formatting .. v)
      end
    end
  end
end
_M.tdump = tdump

-- extend t1 with all the elements of t2
function _M.table_extend(t1, t2)
  for i,v in pairs(t2) do
    table.insert(t1, v)
  end
end

-- Concat the contents of the parameter list,
-- separated by the string delimiter (just like in perl)
-- example: strjoin(", ", {"Anna", "Bob", "Charlie", "Dolores"})
function _M.str_join(delimiter, list)
  local len = table.getn(list)
  if len == 0 then
    return ""
  end
  local string = list[1]
  for i = 2, len do
    string = string .. delimiter .. list[i]
  end
  return string
end

-- split on *non*-matches of the pattern
-- e.g. str_isplit("a,b,c", ",") -> { ",", "," }
-- e.g. str_isplit("a,b,c", "[^,]") -> { "a", "b", "c" }
function _M.str_isplit(str, pattern)
  local tbl = {}
  str:gsub(pattern, function(x) tbl[#tbl+1]=x end)
  return tbl
end

-- split on literal substring
function _M.str_split(str, substr)
  local result = {}
  local cur = str
  if substr:len() == 0 then error("str_split with empty argument") end
  local i,j = str:find(substr)
  while i ~= nil do
    if j ~= nil then
      local part = str:sub(0, i-1)
      table.insert(result, part)
      str = str:sub(j+1)
      i,j = str:find(substr)
    end
  end
  table.insert(result, str)
  return result
end

-- splits the string on the given sub string, but
-- returns only the first element, and the rest of the original string
-- if the substring was not found at all, returns nil, <original_string>
function _M.str_split_one(str, substr)
  local parts = _M.str_split(str, substr)
  if table.getn(parts) == 1 then
    return nil, str
  else
    return table.remove(parts, 1), _M.str_join(substr, parts)
  end
end

-- Finds the index of the given element in the given list
function _M.get_index_of(list, element, max_list_if_not_found)
  if element == nil then error("get_index_of() called with nil element") end
  for i,v in pairs(list) do
    if v == element then
      return i
    end
  end
  -- return nil if not found
  if max_list_if_not_found then
    return table.getn(list)
  else
    --tdump(element)
    error('element not found in list')
  end
end

-- returns the name and index of a list path (e.g. acls[3])
-- returns nil, nil if the first part does not contain a list index
-- there is one special case: if the index is '*' instead of a number,
-- it returns -1 (where the caller may interpret this as, say
-- 'pick them all'
function get_path_list_index(path)
  if path ~= nil then
    local name, index = string.match(path, "^([%w-_]*)%[(%d+)%]")
    if index ~= nil then
      return name, tonumber(index)
    else
      name, wildcard = string.match(path, "^([%w-_]*)%[(%*)%]")
      if wildcard ~= nil then
        return name, -1
      end
    end
  end
end

-- Based on http://lua-users.org/wiki/InheritanceTutorial
-- Defining a class with inheritsFrom instead of just {} will
-- add all methods, and class, superclass and isa method
function _M.subClass( classNameString, baseClass )

  local new_class = {}
  local class_mt = { __index = new_class }

  -- function new_class:create()
  -- local newinst = {}
  -- setmetatable( newinst, class_mt )
  -- return newinst
  -- end

  if nil ~= baseClass then
    setmetatable( new_class, { __index = baseClass } )
  end

  -- Implementation of additional OO properties starts here --

  -- Return the class object of the instance
  function new_class:class()
    return new_class
  end

  function new_class:class_name()
    return classNameString
  end

  -- Return the super class object of the instance
  function new_class:superClass()
    return baseClass
  end

  -- Return true if the caller is an instance of theClass
  function new_class:isa( theClass )
    local b_isa = false

    local cur_class = new_class

    while ( nil ~= cur_class ) and ( false == b_isa ) do
      if cur_class == theClass then
        b_isa = true
      else
        if cur_class:superClass() ~= nil then
        end
        cur_class = cur_class:superClass()
      end
    end

    return b_isa
  end

  return new_class
end

-- helper function for deep copying data nodes
function _M.deepcopy(orig)
  local orig_type = type(orig)
  local copy
  if orig_type == 'table' then
    copy = {}
    for orig_key, orig_value in next, orig, nil do
      if orig_key == 'parent' then
        -- don't deepcopy upwards references, only copy the reference
        copy[orig_key] = orig_value
      else
        copy[_M.deepcopy(orig_key)] = _M.deepcopy(orig_value)
      end
    end
    setmetatable(copy, _M.deepcopy(getmetatable(orig)))
  else -- number, string, boolean, etc
    copy = orig
  end
  return copy
end

function _M.string_starts_with(full_string, sub_string)
  return full_string:sub(1, #sub_string) == sub_string
end

local OrderedDict = {}
local OrderedDict_mt = {
  __index = function(obj, key)
    return obj.values[key]
  end,
  __newindex = function(obj, key, value)
    if value ~= nil then
      if obj.values[key] == nil then
        table.insert(obj.keys, key)
      end
    else
      -- remove it from the keys list
      -- compact the list as well?
      for i,v in pairs(obj.keys) do
        if v == key then
          table.remove(obj.keys, i)
          break
        end
      end
    end
    obj.values[key] = value
  end,
  --
  -- Ideally, we'd use __pairs here too, but lua 5.1 does not seem to
  -- support that
  --
}

function OrderedDict.create()
  local new_inst = {}
  -- An ordered dict contains a list of keys, and
  -- a standard table for values
  new_inst.keys = {}
  new_inst.values = {}
  new_inst.size = function (self)
    return table.getn(self.keys)
  end
  new_inst.iterate = function(tbl)
    local function stateless_iter(tbl, k)
      local v
      -- Implement your own key,value selection logic in place of next
      k, v = next(tbl.keys, k)
      if v then return k,tbl.values[v] end
    end

    -- Return an iterator function, the table, starting point
    return stateless_iter, tbl, nil
  end
  new_inst = setmetatable(new_inst, OrderedDict_mt)
  return new_inst
end

_M.OrderedDict = OrderedDict

return _M

