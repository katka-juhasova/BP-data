--- A module for loading LOVE conf.lua files.
--
-- @module loadconf

local loadconf = {}

local function xload(str, name, env)
	local chunk, err
	if setfenv then -- lua 5.1
		chunk, err = loadstring(str, name)
		if not chunk then return nil, err end
		setfenv(chunk, env)
	else -- lua 5.2, 5.3
		chunk, err = load(str, name, "bt", env)
		if not chunk then return nil, err end
	end

	return chunk
end

local sandbox = {
	assert=assert,
	error=error,
	getmetatable=getmetatable,
	ipairs=ipairs,
	next=next,
	pairs=pairs,
	pcall=pcall,
	print=print,
	rawequal=rawequal,
	rawget=rawget,
	rawset=rawset,
	select=select,
	setmetatable=setmetatable,
	tonumber=tonumber,
	tostring=tostring,
	type=type,
	unpack=unpack,
	_VERSION=_VERSION,
	xpcall=xpcall,
	coroutine=coroutine,
	string=string,
	table=table,
	math=math,
	os = {
		clock=os.clock,
		date=os.date,
		difftime=os.difftime,
		getenv=os.getenv,
		time=os.time,
		tmpname=os.tmpname
	},
	newproxy=newproxy
}

sandbox._G = sandbox

local function merge(from, into)
	for k, v in pairs(from) do
		if type(v) == 'table' then
			merge(v, into[k])
		elseif not into[k] then
			into[k] = v
		end
	end
end

-- format complex strings.
local function complex_fmt(str, data, shape)
	shape = shape or {}
	-- FIXME: ignore escaped {}
	return str:gsub("%b{}", function(k)
		k = k:sub(2, -2)
		local s = data[k]
		assert(s ~= nil)
		if not shape[k] then
			-- no shape given, just use tostring
			s = tostring(s)
		elseif type(shape[k]) == 'string' then
			-- assume shape is a format string
			s = string.format(shape[k], s)
		else
			-- assume shape is callable and returns a valid string
			s = shape[k](s)
		end
		return s
	end)
end

local function slurp(fname)
	local f, s, err
	f, err = io.open(fname, 'r')
	if not f then return nil, err end

	s, err = f:read('*a')
	if not s then return nil, err end
	f:close()

	return s
end

local function line_of(body, n)
	local err
	if body:sub(1, 1) == '@' then
		body, err = slurp(body:sub(2))
		if not body then
			return nil, err
		end
	end

	if body:sub(-1) ~= '\n' then body = body..'\n' end

	local line_i = 1
	for line in string.gmatch(body, "(.-)\n") do
		if n == line_i then
			return line
		end
		line_i = line_i + 1
	end
	return nil, "line out of range"
end

local friendly_msg = [[
{conf} could not be safely loaded.
If {conf} works inside LOVE but not here, then maybe it
has more complex behavior than {program} can recognize.
In that case you should wrap that behavior in a guard, like so:

    if love.filesystem then
        {broken_line}
    end

Actual error:
{orig}
]]

-- Tells the user that they should guard against complex behavior
local function friendly_error(opts)
	if opts.friendly ~= true then
		return function(...) return ... end
	end

	return function(err)
		local info = debug.getinfo(2, 'lS')
		if info.short_src:match("loadconf.lua") then
		    -- this is actually an internal error
		    return err
		end

		local line = line_of(info.source, info.currentline)
		if not line then
		    -- could not retrieve source data, return internal err
		    -- instead
		    return err
		end
		line = line:gsub("^%s+", "")
		local name = "string conf.lua"
		if info.source:match("^@") then
			name = info.short_src
		end
		return complex_fmt(friendly_msg, {
			conf = name,
			program = opts.program or loadconf.default_opts.program,
			broken_line = line,
			orig = err
		})
	end
end

local friendly_parse_msg = [[
{conf} could not be parsed. This is usually a syntax error. Keep in
mind that {conf} should be valid {lua_version}!

{orig}
]]

-- Tells the user that their conf.lua failed to parse
local function friendly_parse_error(err, name, opts)
	if opts.friendly ~= true then
		return err
	end
	return complex_fmt(friendly_parse_msg, {
		conf = name or "string conf.lua",
		lua_version = _VERSION,
		orig = err
	})
end

--- Given the string contents of a conf.lua, returns a table containing the
--  configuration it represents.
--  @param str The contents of conf.lua
--  @param name The name of conf.lua used in error messages. Uses same format as `load`. Optional.
--  @param[type=options] opts A configuration table. Optional.
--  @return `love_config`
--  @error
function loadconf.parse_string(str, name, opts)
	opts = opts or loadconf.default_opts
	--name = name

	local ok, chunk, err
	local env = setmetatable({love = {}}, {__index = sandbox})

	--assert(type(name) == "string")
	ok, chunk, maybe_err = pcall(xload, str, name, env)
	if not ok then return nil, chunk end
	if not chunk then
		return nil, friendly_parse_error(maybe_err, name, opts)
	end

	ok, err = xpcall(chunk, friendly_error(opts))
	if not ok then return nil, err end

	if not env.love.conf then
		return {} -- No configuration
	end

	local t = { window = {}, audio = {}, screen = {}, modules = {} }
	ok, err = xpcall(function()
		env.love.conf(t)
	end, friendly_error(opts))

	if ok then
		if not t.version then
			t.version = loadconf.latest_stable_version
		end

		if opts.include_defaults == true and loadconf.defaults[t.version] then
			merge(loadconf.defaults[t.version], t)
		end
		return t
	else
		return nil, err
	end
end

--- Given the filename of a valid conf.lua file, returns a table containing the
--  configuration it represents.
--  @param fname The path to the conf.lua file
--  @tparam options opts A configuration table. Optional.
--  @return `love_config`
--  @error
function loadconf.parse_file(fname, opts)
	opts = opts or loadconf.default_opts
	local str, err = slurp(fname)
	if not str then return nil, err end

	return loadconf.parse_string(str, "@"..fname, opts)
end

--- The configuration tables produced by running `love.conf`.
-- @table love_config
-- @see love/Config_Files

--- The optional table all loadconf functions take. customize according to your
--  use case.
--  @table options
--  @field[opt="loadconf"] program What is the program called? Used for friendly errors
--  @field[opt=false] friendly Enable user-friendly errors
--  @field[opt=false] include_defaults Return default values in parsed configs
loadconf.default_opts = {
	program          = "loadconf",
	friendly         = false,
	include_defaults = false
}

--- The current stable love version, which right now is "11.2". Please
--  submit an issue/pull request if this is out of date, sorry~
loadconf.stable_love = "11.2"

--- A table containing the default config tables for each version of love.
--  @usage assert(loadconf.defaults["0.9.2"].window.fullscreentype == "normal")
loadconf.defaults = {}

local function defaults_copy(old_v, version)
	local old = loadconf.defaults[old_v]
	local t = {}
	for k, v in pairs(old) do
		t[k] = v
	end
	t.version = version
	loadconf.defaults[version] = t
end

-- default values for 11.X {{{
loadconf.defaults["11.2"] = {
	identity = nil,
	appendidentity = false,
	version = "11.2",
	console = false,
	accelerometerjoystick = true,
	externalstorage = false,
	gammacorrect = false,
	audio = {
		mixwithsystem  = true
	},
	window = {
		title          = "Untitled",
		icon           = nil,
		width          = 800,
		height         = 600,
		borderless     = false,
		resizable      = false,
		minwidth       = 1,
		minheight      = 1,
		fullscreen     = false,
		fullscreentype = "desktop",
		vsync          = 1,
		msaa           = 0,
		display        = 1,
		highdpi        = false,
		x              = nil,
		y              = nil
	},
	modules = {
		audio         = true,
		data          = true,
		event         = true,
		font          = true,
		graphics      = true,
		image         = true,
		joystick      = true,
		keyboard      = true,
		math          = true,
		mouse         = true,
		physics       = true,
		sound         = true,
		system        = true,
		thread        = true,
		timer         = true,
		touch         = true,
		video         = true,
		window        = true
	}
}
defaults_copy("11.2", "11.1")
defaults_copy("11.2", "11.0")
-- }}}

-- default values for 0.10.X {{{
loadconf.defaults["0.10.2"] = {
	identity = nil,
	version = "0.10.2",
	console = false,
	gammacorrect = false,
	externalstorage = false,
	accelerometerjoystick = true,
	window = {
		title          = "Untitled",
		icon           = nil,
		width          = 800,
		height         = 600,
		borderless     = false,
		resizable      = false,
		minwidth       = 1,
		minheight      = 1,
		fullscreen     = false,
		fullscreentype = "desktop",
		vsync          = true,
		msaa           = 0,
		display        = 1,
		highdpi        = false,
		x              = nil,
		y              = nil
	},
	modules = {
		audio         = true,
		event         = true,
		graphics      = true,
		image         = true,
		joystick      = true,
		keyboard      = true,
		math          = true,
		mouse         = true,
		physics       = true,
		sound         = true,
		system        = true,
		timer         = true,
		touch         = true,
		video         = true,
		window        = true,
		thread        = true,
	}
}

defaults_copy("0.10.2", "0.10.1")
defaults_copy("0.10.2", "0.10.0")
loadconf.defaults["0.10.0"].externalstorage = nil
-- }}}

-- default values for 0.9.X {{{
loadconf.defaults["0.9.2"] = {
	identity = nil,
	version = "0.9.2",
	console = false,
	window = {
		title          = "Untitled",
		icon           = nil,
		width          = 800,
		height         = 600,
		borderless     = false,
		resizable      = false,
		minwidth       = 1,
		minheight      = 1,
		fullscreen     = false,
		fullscreentype = "normal",
		vsync          = true,
		fsaa           = 0,
		display        = 1,
		highdpi        = false,
		srgb           = false,
		x              = nil,
		y              = nil
	},
	modules = {
		audio         = true,
		event         = true,
		graphics      = true,
		image         = true,
		joystick      = true,
		keyboard      = true,
		math          = true,
		mouse         = true,
		physics       = true,
		sound         = true,
		system        = true,
		timer         = true,
		window        = true,
		thread        = true,
	}
}

defaults_copy("0.9.2", "0.9.1")
defaults_copy("0.9.2", "0.9.0")
-- }}}

-- default values for 0.8.X {{{
loadconf.defaults["0.8.0"] = {
	identity = nil,
	version = "0.8.0",
	console = false,
	release = false,
	title = "Untitled",
	author = "Unnamed",
	screen = {
		width = 800,
		height = 600,
		fullscreen = false,
		vsync = true,
		fsaa = 0
	},
	modules = {
		audio     = true,
		event     = true,
		graphics  = true,
		image     = true,
		joystick  = true,
		keyboard  = true,
		mouse     = true,
		physics   = true,
		sound     = true,
		timer     = true,
		thread    = true
	}
}
-- }}}

local Loadconf = {}
local Loadconf_mt = {__index = Loadconf}

---
--  Create an instanced version of loadconf. This carries its configuration
--  state in object-oriented way, if you prefer that.
--  @param[type=options] opts
--  @return a `Loadconf` instance
function loadconf.new(opts)
	local t = {}
	for k, v in pairs(loadconf.default_opts) do
		if opts[k] == nil then
			t[k] = v
		else
			t[k] = opts[k]
		end
	end
	return setmetatable(t, Loadconf_mt)
end

--- An object-oriented instance of the loadconf module. This carries
--  configuration state internally so you can set-and-forget the `options`
--  table.
--
--  @type Loadconf

--- @see loadconf.parse_string
function Loadconf:parse_string(str, name)
	return loadconf.parse_string(str, name, self)
end

--- @see loadconf.parse_file
function Loadconf:parse_file(fname)
	return loadconf.parse_file(fname, self)
end

return loadconf
