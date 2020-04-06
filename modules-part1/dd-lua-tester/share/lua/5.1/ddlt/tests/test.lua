local extractors = {}
local lustache = require "lustache"
local path = require "pl.path"
local jsonpath = require "jsonpath"
local json = require "json"
local lfs = require "lfs"

local function catch(what)
   return what[1]
end

local function extend(table1, table2)
  for k,v in pairs(table2) do
    if (type(table1[k]) == 'table' and type(v) == 'table') then
      extend(table1[k], v)
    else
      table1[k] = v
    end
	end
end

local function try(what)
   local status, result = pcall(what[1])
   if not status then
      what[2](result)
   end
   return result
end

local function ternary(cond, T, F)
  if cond then return T else return F end
end

local function makeList(values)
  return type(values) == 'table' and values or { values }
end

local function starts_with(str, start)
  return str:sub(1, #start) == start
end

local function is_array(table)
  if type(table) ~= 'table' then
    return false
  end
  -- objects always return empty size
  if #table > 0 then
    return true
  end
  -- only object can have empty length with elements inside
  for k, v in pairs(table) do -- luacheck:ignore
    return false
  end
  -- if no elements it can be array and not at same time
  return true
end

local function ends_with(str, ending)
  if str:sub(-#ending) == ending then
    return str:sub(1, -(#ending+1))
  end
end

local function queryJson(data, path)
  local res = data;
  if (type(data) == 'table' and data ~= nil) then
    if starts_with(path, 'LEN()<') then
      return #(jsonpath.query(data, path:sub(7)))
    elseif (type(path) == 'string' and starts_with(path, 'TYPEOF<')) then
      return type(jsonpath.query(data, path:sub(8))[1])
    elseif starts_with(path, 'ARRAY<') then
      return jsonpath.query(data, path:sub(7))
    elseif string.find(path, '<', 1, true) == 6 then
      local count = tonumber(path:substr(1, 6), 10)
      if count ~= nil then
        return jsonpath.query(data, path:sub(7), count);
      end
    end
    res = jsonpath.query(data, path, 1);
    res = is_array(res) and ternary(#res < 2, res[1], res);
  end
  return res
end

local function isFullVariable(str)
  return type(str) == 'string' and starts_with(str, '{{') and ends_with(str, '}}') ~= nil
end

local function resolveVar(str, from)
  if from == nil then
    from = extractors
  end
  if isFullVariable(str) then
    local result = queryJson(from, (ternary(starts_with(str, '$.'), '', '$.'))..str:sub(3, -3))
    if type(result) ~= "string" or result ~= str then
      return result
    end
  end
  if type(str) == 'string' then
    return lustache:render(str, from)
  end
  return str
end

local function deepResolve(e)
  if type(e) == "table" then
    for k,v in pairs(e) do
      local nk = resolveVar(k)
      e[ternary(type(nk) == 'string', nk, k)] = deepResolve(v)
    end
    return e
  elseif type(e) == 'string' then
    return resolveVar(e)
  else
    return e
  end
end

local function load_json(path)
  local file = io.open( path, "r" )

  if file then
      -- read all contents of file into a string
      local contents = file:read( "*a" )
      local myTable = json.decode(contents);
      io.close( file )
      return myTable
  end
  return nil
end

local function callTests(tsName, tests, notTc)
  for count = 1, #tests do
    local test = tests[count]
    local function tc()
      local currentContext = _G
      if type(test["require"]) == "string" then
        if test["require"] ~= "$global" then
          local resolvedRequire = resolveVar(test['require'])
          if type(resolvedRequire) == "string" then
            currentContext = require(resolvedRequire)
          else
            currentContext = resolvedRequire
          end
        end
      else
        extractors["_context"] = require(tsName)
        currentContext = extractors["_context"]
      end
      local result = {}
      if test["request"] == nil then
        result["output"] = currentContext
        result["error"] = nil
      else
        local func = resolveVar(test["request"]["method"])
        local funcToCall = nil
        local directFuncCall = false
        if (func == nil or func == "") and type(currentContext) == "function" then
          directFuncCall = true
          funcToCall = currentContext
        elseif type(func) == "string" then
          funcToCall = currentContext[func]
        end
        if type(funcToCall) == "function" then
          local params = makeList(deepResolve(test["request"]["params"]))
          local ok,err
          try {
            function()
              if directFuncCall then
                ok,err = funcToCall(unpack(params))
              else
                ok,err = funcToCall(currentContext,unpack(params))
              end
            end,
            catch {
              function(error)
                print(error)
                ok = nil
                err = error
              end
            }
          }
          result['output'] = ok
          result['error'] = err
        end
      end
      if type(test["extractors"]) == "table" then
        for k,v in pairs(test["extractors"]) do
          local nk = resolveVar(k)
          if type(nk) == 'string' and isFullVariable(nk) == false then
            extractors[nk] = queryJson(result,v)
          end
        end
      end
      if type(test["assertions"]) == "table" then
        for k,v in pairs(test["assertions"]) do
          assert.are.same(deepResolve(v), queryJson(result,resolveVar(k)))
        end
      end
    end
    if test['disabled'] ~= true then
      if notTc == nil and type(test['summary']) == 'string' then
        it(test['summary'], tc)
      else
        tc()
      end
    end
  end
end

local function forOneTS(tsName, patt)
  local tsData = load_json(tsName..patt)

  if type(tsData['vars']) == "table" then
    extend(extractors, tsData['vars'])
  end

  if is_array(tsData['setup']) then
    setup(function()
      callTests(tsName, tsData['setup'], true)
    end)
  end
  if is_array(tsData['teardown']) then
    teardown(function()
      callTests(tsName, tsData['teardown'], true)
    end)
  end
  if is_array(tsData['before_each']) then
    before_each(function()
      callTests(tsName, tsData['before_each'], true)
    end)
  end
  if is_array(tsData['after_each']) then
    after_each(function()
      callTests(tsName, tsData['after_each'], true)
    end)
  end
  if is_array(tsData['tests']) then
    describe(tsName, function()
      callTests(tsName, tsData['tests'])
    end)
  end
end

for count = 1, #DDLT_GLOBAL_ARGS["root"] do
  local dir = DDLT_GLOBAL_ARGS["root"][count]
  assert(dir and dir ~= "", "Please pass directory parameter")
  if string.sub(dir, -1) == "/" then
    dir=string.sub(dir, 1, -2)
  end

  local function yieldtree(localdir)
    local dir = path.join(DDLT_GLOBAL_ARGS['d'], localdir)
    for entry in lfs.dir(dir) do
      if entry ~= "." and entry ~= ".." then
        entry = path.join(localdir, entry)
        local attr=lfs.attributes(path.join(DDLT_GLOBAL_ARGS['d'], entry))
        local tsName = false
        local patt = false
        if attr.mode == "directory" then
          yieldtree(entry)
        else
          for c = 1, #DDLT_GLOBAL_ARGS["p"] do -- luacheck:ignore
            tsName = ends_with(entry, DDLT_GLOBAL_ARGS["p"][c])
            if tsName then
              patt = DDLT_GLOBAL_ARGS["p"][c]
              break
            end
          end
          if tsName then
            forOneTS(tsName, patt)
          end
        end
      end
    end
  end

  yieldtree(dir)
end
