--- Aurora template
-- Project page: https://github.com/kxmn/aurora
-- Extended from a fork of Simple Lua Template 2 (slt2) version 1.0
--
-- @license MIT License
-- @copyright 2019 Kxmn
-- @copyright 2016 henix (https://github.com/henix/slt2
--]]

local _ = {}
local fs = require 'aurora.fs'



local T = {
	conf = {
		cache=false,
		compilePath = '',
		templatePath = '',
		startTag = '{%',
		endTag = '%}',
	},
	env = {
		ipairs = ipairs,
		next = next,
		pairs = pairs,
		select = select,
		tonumber = tonumber,
		tostring = tostring,
		type = type,
		unpack = unpack,
		string = string,
		table = table,
		math = math,
		getDate = os.date,
		getTime = os.time,
		print = coroutine.yield
	}
}

-- a tree fold on inclusion tree
-- @param iniFunc: must return a new value when called
function _.includeFold(template, conf, foldFunc, iniFunc)
  local result = iniFunc()
  local incStartTag = conf.startTag..'include: '

  local start1, end1 = string.find(template, incStartTag, 1, true)
  local start2 = nil
  local end2 = 0

  while start1 ~= nil do
    if start1 > end2 + 1 then -- for beginning part of file
      result = foldFunc(result, string.sub(template, end2 + 1, start1 - 1))
    end
    start2, end2 = string.find(template, conf.endTag, end1 + 1, true)
    assert(start2, 'end tag "'..conf.endTag..'" missing')
    do -- recursively include the file
      local filename = assert(load('return '..string.sub(template, end1 + 1, start2 - 1)))()
      assert(filename)
			filename = conf.templatePath..filename
      local fin = assert(io.open(filename))
      -- TODO: detect cyclic inclusion?
      result = foldFunc(result, _.includeFold(fin:read('*a'), conf, foldFunc, iniFunc), filename)
      fin:close()
    end
    start1, end1 = string.find(template, incStartTag, end2 + 1, true)
  end
  result = foldFunc(result, string.sub(template, end2 + 1))
  return result
end

-- preprocess included files
-- @return string
function T:precompile(template,conf)
  return table.concat(_.includeFold(template, conf, function(acc, v)
    if type(v) == 'string' then
      table.insert(acc, v)
    elseif type(v) == 'table' then
      table.insert(acc, table.concat(v))
    else
      error('Unknown type: '..type(v))
    end
    return acc
  end, function() return {} end))
end

-- unique a list, preserve order
function _.stableUniq(t)
  local existed = {}
  local res = {}
  for _, v in ipairs(t) do
    if not existed[v] then
      table.insert(res, v)
      existed[v] = true
    end
  end
  return res
end


-- @return { name = string, code = string / function}
function T:load(template, tplName, conf)
  -- compile it to lua code
  local luaCode = {}
  local outputFn = "print"
  template = T:precompile(template,conf)

  local start1, end1 = string.find(template, conf.startTag, 1, true)
  local start2 = nil
  local end2 = 0

  local cEqual = string.byte('=', 1)

  while start1 ~= nil do
    if start1 > end2 + 1 then
      table.insert(luaCode, 'print('..string.format("%q", string.sub(template, end2 + 1, start1 - 1))..')')
    end
    start2, end2 = string.find(template, conf.endTag, end1 + 1, true)
    assert(start2, 'endTag "'..conf.endTag..'" missing')
    if string.byte(template, end1 + 1) == cEqual then
      table.insert(luaCode, 'print('..string.sub(template, end1 + 2, start2 - 1)..')')
    else
      table.insert(luaCode, string.sub(template, end1 + 1, start2 - 1))
    end
    start1, end1 = string.find(template, conf.startTag, end2 + 1, true)
  end
  table.insert(luaCode, 'print('..string.format("%q", string.sub(template, end2 + 1))..')')

  local ret = { name = tplName or '=(T:load)' }
  ret.code = table.concat(luaCode, '\n')
  return ret
end

-- @return { name = string, code = string / function }
function T:loadfile(filename)
  return T:load(fs.getFileContents(filename), filename, self.conf)
end

-- @return a coroutine function
function T:coRender(t, data)
	data = setmetatable(data or {}, { __index = self.env })
  return assert(load(t.code, t.name, 't', data))
end

-- @return string
function T:render(tplName, data)
	local tfile = self.conf.templatePath..tplName
	local cfile = self.conf.compilePath..tplName
	local luaData = {
		name=tfile,
		code=self.conf.cache and fs.getFileContents(cfile)
	}
	if not luaData.code then
		luaData = self:loadfile(tfile)
		if self.conf.cache and luaData.code then
			fs.putFileContents(cfile,luaData.code)
		end
	end

  local result = {}
  local co = coroutine.create(self:coRender(luaData, data))
  while coroutine.status(co) ~= 'dead' do
    local ok, chunk = coroutine.resume(co)
    if not ok then
      error(chunk)
    end
    table.insert(result, chunk)
  end
  return table.concat(result)
end

function T:renderString(str,data)
	

end


return {
	new = function(o)
		o = setmetatable(o or {}, {__index = T })
		o.conf = setmetatable(o.conf or {}, {__index = T.conf})
		o.env = setmetatable(o.env or {}, {__index = T.env})
		return o
	end
}
