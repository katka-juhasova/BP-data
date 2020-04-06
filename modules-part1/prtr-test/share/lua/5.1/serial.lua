local _M = {}

local function escape(s)
	return string.format("%q", s):gsub('\\\n', '\\n'):gsub('\t', '\\t'):gsub('\\9', '\\t'):gsub('\\000$', '\\0'):gsub('\\000(%D)', '\\0%1')
end

local function elem(k)
	local t = type(k)
	if t=='nil' or t=='boolean' or t=='number' then
		return '['..tostring(k)..']'
	elseif t=='string' and k:match('^[A-Za-z_][A-Za-z_0-9]*$') then
		return '.'..k
	elseif t=='string' then
		return '['..escape(k)..']'
	else
		error("unsupported key type '"..t.."'")
	end
end

local function pathstr(path)
	for i=1,#path do
		path[i] = elem(path[i])
	end
	return table.concat(path)
end

local function match(a, b, path)
	local t = type(a)
	if t~=type(b) then
		return false,path
	else
		if t=='nil' or t=='boolean' or t=='string' or t=='function' or t=='thread' then
			return a==b,path
		elseif t=='number' then
			if _M.epsilon then
				return math.abs(a-b)<=_M.epsilon,path
			else
				return a==b,path
			end
		elseif t=='table' then
			if a==b then return true end
			-- try to differentiate from content
			local keys = {}
			for k in pairs(a) do keys[k] = true end
			for k in pairs(b) do keys[k] = true end
			for k in pairs(keys) do
				local t = type(k)
				if t=='boolean' or t=='number' or t=='string' then
					local subpath = {}
					if path then for i,k in ipairs(path) do subpath[i] = k end end
					table.insert(subpath, k)
					local success,path = match(a[k], b[k], subpath)
					if not success then
						return false,path
					end
				else
					error("unsupported key type '"..t.."'")
				end
			end
			return true
		elseif t=='userdata' then
			if a==b then return true,path end
			-- if the udata share a metatable with a __tostring, compare their string form
			local mt = debug.getmetatable(a)
			if mt~=debug.getmetatable(b) then
				return false,path
			elseif mt then
				if mt.__tostring then
					return tostring(a)==tostring(b),path
				else
					return false,path
				end
			else
				return false,path
			end
		else
			error("unsupported value type '"..t.."'")
		end
	end
end

local function valuestring(v)
	if type(v)=='string' then
		if v:match('\n') and not v:match('\r[^\n]') and not v:match('\r$') and not v:match('[\000-\009\011\012\014-\031]') then
			local quote,n = ']]',0
			while v:match(quote:gsub('%[', '%%[')) do
				n = n + 1
				quote = ']'..string.rep('=', n)..']'
			end
			return quote:gsub(']', '[')..'\n'..v..quote
		elseif v:match('[\000-\031]') then
			return escape(v)
		else
			return v
		end
	else
		return tostring(v)
	end
end

function expect(expectation, value, ...)
	local success,path = match(expectation, value)
	if not success then
		if path then
			local a,b = expectations,value
			for _,k in ipairs(path) do
				expectation,value = expectation[k],value[k]
			end
			error("expectation failed!"..
				" "..valuestring(expectation).." ("..type(expectation)..") expected"..
				" for field "..pathstr(path)..
				", got "..valuestring(value).." ("..type(value)..")",
				2)
		else
			error("expectation failed!"..
				" "..valuestring(expectation).." ("..type(expectation)..") expected"..
				", got "..valuestring(value).." ("..type(value)..")",
				2)
		end
	end
end

local expect_data = {}

function expect_call(root, fname, args, results)
	local expectation = {args=args or {}, results=results or {}}
	if expect_data[fname] then
		table.insert(expect_data[fname].expectations, expectation)
	else
		local orig,parent,name
		do
			local t = root or _G
			local g = ""
			for word in string.gmatch(fname, "[^.]+") do
				g = g.."."..word
				name = word
				parent = t
				t = assert(t[word], "global "..g:sub(2).." not found")
			end
			orig = t
		end
		parent[name] = function(...)
			local data = expect_data[fname]
			local expectation = assert(data.expectations[data.next], "no expectation found while mock function is in place")
			for i=1,expectation.args.n or 0 do
				local expected = expectation.args[i]
				local got = select(i, ...)
				if expected~=got then
					data.checked = false
					expectation.failed = {iarg=i, expected=expected, got=got}
					break
				end
			end
			data.next = data.next + 1
			if data.next > #data.expectations then
				data.parent[data.name] = data.orig
			end
			return unpack(expectation.results, 1, expectation.results.n or 0)
		end
		expect_data[fname] = {
			expectations = { expectation },
			next = 1,
			parent = parent,
			name = name,
			orig = orig,
			checked = true,
		}
	end
end

function check_expectations()
	local checked,msg = true
	for fname,data in pairs(expect_data) do
		if not data.checked then
			checked = false
			local icall,detail
			for i,expectation in ipairs(data.expectations) do
				if expectation.failed then
					icall = i
					details = expectation.failed
					break
				end
			end
			msg = fname.." call #"..icall.." got wrong argument #"..details.iarg.." ("..tostring(details.expected).." expected, got "..tostring(details.got)..")"
			break
		end
		if data.next <= #data.expectations then
			checked = false
			msg = "expectation failed ("..fname.." not called enough)"
			break
		end
	end
	expect_data = {}
	return checked,msg
end

if ...==nil then
	assert(elem(nil)=='[nil]')
	assert(elem(0)=='[0]')
	assert(elem(" ")=='[" "]')
	assert(elem("foo")=='.foo')
	assert(elem("\t\n\0")=='["\\t\\n\\0"]')
	assert(elem("\t\n\0a")=='["\\t\\n\\0a"]')
	assert(elem("\t\n\00001")=='["\\t\\n\\00001"]')
	
	assert(pathstr({})=='')
	assert(pathstr({1})=='[1]')
	assert(pathstr({'foo', 'bar'})=='.foo.bar')
	
	local success,path
	-- matching nils
	success,path = match(nil, nil)
	assert(success and path==nil)
	-- matching numbers
	success,path = match(0, 0)
	assert(success and path==nil)
	-- non-matching numbers
	success,path = match(0, 1)
	assert(not success and path==nil)
	-- matching numbers with epsilon
	_M.epsilon = 0.001
	success,path = match(0, 0.0009999)
	assert(success and path==nil)
	_M.epsilon = nil
	-- non-matching numbers with epsilon
	_M.epsilon = 0.001
	success,path = match(0, 0.0010001)
	assert(not success and path==nil)
	_M.epsilon = nil
	-- matching strings
	success,path = match("", "")
	assert(success and path==nil)
	-- non-matching strings
	success,path = match("", " ")
	assert(not success and path==nil)
	-- identical tables
	local t = {}
	success,path = match(t, t)
	assert(success and path==nil)
	-- matching tables
	success,path = match({}, {})
	assert(success and path==nil)
	-- matching table field
	success,path = match({0}, {0})
	assert(success and path==nil)
	-- non-matching table fields
	success,path = match({0}, {1})
	assert(not success and pathstr(path)=='[1]')
	-- matching table sub-fields
	success,path = match({{0}}, {{0}})
	assert(success and path==nil)
	-- non-matching table sub-fields
	success,path = match({{0}}, {{1}})
	assert(not success and pathstr(path)=='[1][1]')
	success,path = match({{type='library', filename='foo'}}, {{type='library', filename='fooa'}})
	assert(not success and pathstr(path)=='[1].filename')
	-- identical functions
	success,path = match({print}, {print})
	assert(success and path==nil)
	-- distinct functions
	success,path = match({print}, {assert})
	assert(not success and pathstr(path)=='[1]')
	-- identical coroutines
	local c = coroutine.create(function() end)
	success,path = match({c}, {c})
	assert(success and path==nil)
	-- distinct coroutines
	local c1 = coroutine.create(function() end)
	local c2 = coroutine.create(function() end)
	success,path = match({c1}, {c2})
	assert(not success and pathstr(path)=='[1]')
	-- userdata tests
	if not newproxy then
		pcall(require, 'newproxy')
	end
	if newproxy then
		-- identical udata
		local ud = newproxy()
		success,path = match({ud}, {ud})
		assert(success and path==nil)
		-- distinct udata without metatable (mt)
		local ud1,ud2 = newproxy(),newproxy()
		success,path = match({ud1}, {ud2})
		assert(not success and pathstr(path)=='[1]')
		-- distinct udata with distinct mt
		local ud1,ud2 = newproxy(true),newproxy(true)
		success,path = match({ud1}, {ud2})
		assert(not success and pathstr(path)=='[1]')
		-- distinct udata with identical mt, no __tostring
		local ud1 = newproxy(true)
		local ud2 = newproxy(ud1)
		success,path = match({ud1}, {ud2})
		assert(not success and pathstr(path)=='[1]')
		-- distinct udata with identical mt, matching __tostring
		local ud1 = newproxy(true)
		local ud2 = newproxy(ud1)
		getmetatable(ud1).__tostring = function() return "" end
		success,path = match({ud1}, {ud2})
		assert(success and path==nil)
		-- distinct udata with identical mt, non-matching __tostring
		local ud1 = newproxy(true)
		local ud2 = newproxy(ud1)
		getmetatable(ud1).__tostring = function(self) if self==ud1 then return "" else return " " end end
		success,path = match({ud1}, {ud2})
		assert(not success and pathstr(path)=='[1]')
	end
end

return _M
