local extractors = {}
local lustache = require "lustache"
local plpath = require "pl.path"
local jsonpath = require "jsonpath"
local lfs = require "lfs"
local resolveVar = nil
local result, json = pcall(require, 'cjson')
if not result then
  json = require 'json'
end

local DDT_DEBUG = os.getenv("DDT_DEBUG") or '1'
DDT_DEBUG = {DDT_DEBUG:sub(1,1),DDT_DEBUG:sub(2,2),DDT_DEBUG:sub(3,3),DDT_DEBUG:sub(4,4),DDT_DEBUG:sub(5,5)}
local LOG_FLAG_BASE = DDT_DEBUG[1] == '1'
local LOG_FLAG_METHOD = DDT_DEBUG[2] == '1' or DDT_DEBUG[2] == 'm'
local LOG_FLAG_PARAMS = DDT_DEBUG[3] == '1' or DDT_DEBUG[3] == 'p'
local LOG_FLAG_RESPONSE = DDT_DEBUG[4] == '1' or DDT_DEBUG[4] == 's'
local LOG_FLAG_SUMMARY = DDT_DEBUG[5] == '1' or DDT_DEBUG[4] == 's'
local LOG_FLAG_ANYDEBUG = LOG_FLAG_METHOD or LOG_FLAG_PARAMS or LOG_FLAG_RESPONSE or LOG_FLAG_SUMMARY

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

local function unpackFunctionCall(str,dontResoleParams)
  local startParamInd, _ = str:find('(', 2, true) -- TODO bad code, `(` can also be part of path
  if startParamInd ~= nil and ends_with(str, ')') then
    local funcParamDesc = str:sub(startParamInd+1, -2)
    startParamInd = startParamInd - 1
    local funcParams = nil
    if not dontResoleParams then
      funcParams = funcParamDesc:split(',')
      for ind,dt in pairs(funcParams) do
        funcParams[ind] = resolveVar(dt)
      end
    end
    return str:sub(1, startParamInd), funcParams, startParamInd, funcParamDesc
  end
  return str, {}, nil, ''
end

local function jsonpathquery(data, path, count)
  local result
  local npath, funcParams, startParamInd, _ = unpackFunctionCall(path)
  npath = ternary(starts_with(npath, '$.'), '', '$.')..npath
  if startParamInd == nil then
    result = jsonpath.query(data, npath, count)
  else
    result = jsonpath.query(data, npath, 1)[1](unpack(funcParams))
  end
  return result
end

local function queryJson(data, path)
  local res = data
  if (type(data) == 'table' and data ~= nil) then
    if starts_with(path, 'LEN()<') then
      return #(jsonpathquery(data, path:sub(7)))
    elseif (type(path) == 'string' and starts_with(path, 'TYPEOF<')) then
      return type(jsonpathquery(data, path:sub(8))[1])
    elseif starts_with(path, 'ARRAY<') then
      return jsonpathquery(data, path:sub(7))
    elseif string.find(path, '<', 1, true) == 6 then
      local count = tonumber(path:substr(1, 6), 10)
      if count ~= nil then
        return jsonpathquery(data, path:sub(7), count);
      end
    end
    res = jsonpathquery(data, path, 1);
    if is_array(res) and #res < 2 then
      res = res[1]
    end
  end
  return res
end

local function isFullVariable(str)
  return type(str) == 'string' and starts_with(str, '{{') and ends_with(str, '}}') ~= nil
end

resolveVar = function(str, from)
  if from == nil then
    from = extractors
  end
  if isFullVariable(str) then
    local result = queryJson(from, str:sub(3, -3))
    if type(result) ~= "string" or result ~= str then
      return result
    end
  end
  if type(str) == 'string' then
    local npath, _, startParamInd, funcParamDesc = unpackFunctionCall(str, true)
    if startParamInd then
      return lustache:render(npath, from)..'('..funcParamDesc..')'
    else
      return lustache:render(str, from)
    end
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
  if LOG_FLAG_ANYDEBUG then print("\n\nDDT_TESTSUITE-".. (notTc or '') .. " starts | ", tsName) end
  for count = 1, #tests do
    local test = tests[count]
    local function tc()
      if LOG_FLAG_SUMMARY then print("DDT_TESTCASE_START | ", test['summary']) end
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
        if LOG_FLAG_METHOD then print("DDT_REQUEST_METHOD | ", (test['require'] or tsName) .. ':' .. (func or '()')) end
        local funcToCall = nil
        local directFuncCall = false
        if currentContext then
          if (func == nil or func == "") and type(currentContext) == "function" then
            directFuncCall = true
            funcToCall = currentContext
          elseif type(func) == "string" then
            funcToCall = currentContext[func]
          end
        end
        if type(funcToCall) == "function" then
          local params = makeList(deepResolve(test["request"]["params"]))
          if LOG_FLAG_PARAMS then print("DDT_REQUEST_PARAMS | ", json.encode(params)) end
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
                if LOG_FLAG_BASE then print(error) end
                ok = nil
                err = error
              end
            }
          }
          result['output'] = ok
          result['error'] = err
        end
      end
      if LOG_FLAG_RESPONSE then
        try {
          function()
            print("DDT_RESPONSE       | ", json.encode(result))
          end,
          catch {
            function(error)
              print("DDT_RESPONSE       | ", result['output'], result['error'])
            end
          }
        }
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
          assert.are.same(deepResolve(v), queryJson(result, resolveVar(k)))
        end
      end
      if LOG_FLAG_SUMMARY then
        print("DDT_TESTCASE_END   | ", test['summary'])
      end
    end
    if test['disabled'] ~= true then
      if notTc == nil then
        it(test['summary'] or 'No summary', tc)
      else
        tc()
      end
    end
  end
  if LOG_FLAG_ANYDEBUG then print("DDT_TESTSUITE-".. (notTc or '') .. " ends | ", tsName) end
end

local function forOneTS(tsName, patt)
  local tsData = load_json(tsName..patt)

  if type(tsData['vars']) == "table" then
    extend(extractors, tsData['vars'])
  end

  describe(tsName, function()
    if is_array(tsData['setup']) then
      setup(function()
        callTests(tsName, tsData['setup'], 'SETUP')
      end)
    end
    if is_array(tsData['lazy_setup']) then
      lazy_setup(function()
        callTests(tsName, tsData['lazy_setup'], 'LAZY_SETUP')
      end)
    end
    if is_array(tsData['before_each']) then
      before_each(function()
        callTests(tsName, tsData['before_each'], 'BEFORE_EACH')
      end)
    end
    if is_array(tsData['tests']) then
      callTests(tsName, tsData['tests'])
    end
    if is_array(tsData['after_each']) then
      after_each(function()
        callTests(tsName, tsData['after_each'], 'AFTER_EACH')
      end)
    end
    if is_array(tsData['lazy_teardown']) then
      lazy_teardown(function()
        callTests(tsName, tsData['lazy_teardown'], 'LAZY_TEARDOWN')
      end)
    end
    if is_array(tsData['teardown']) then
      teardown(function()
        callTests(tsName, tsData['teardown'], 'TEARDOWN')
      end)
    end
  end)
end

for count = 1, #DDT_GLOBAL_ARGS["root"] do
  local dir = DDT_GLOBAL_ARGS["root"][count]
  assert(dir and dir ~= "", "Please pass directory parameter")
  if string.sub(dir, -1) == "/" then
    dir=string.sub(dir, 1, -2)
  end

  local function yieldtree(localdir)
    local sdir = plpath.join(DDT_GLOBAL_ARGS['d'], localdir)
    for entry in lfs.dir(sdir) do
      if entry ~= "." and entry ~= ".." then
        entry = plpath.join(localdir, entry)
        local attr=lfs.attributes(plpath.join(DDT_GLOBAL_ARGS['d'], entry))
        local tsName = false
        local patt = false
        if attr.mode == "directory" then
          yieldtree(entry)
        else
          for c = 1, #DDT_GLOBAL_ARGS["p"] do -- luacheck:ignore
            tsName = ends_with(entry, DDT_GLOBAL_ARGS["p"][c])
            if tsName then
              patt = DDT_GLOBAL_ARGS["p"][c]
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
