local lpc = require 'lpc'

local unpack = table.unpack or unpack -- luacheck: read globals unpack

local sizes = { i4 = 4, u4 = 4, c = 1 }

local function write_u4(wh, value)
	local bytes = ''
	for _ = 1, sizes.u4 do
		bytes = string.char(value % (2 ^ 8)) .. bytes
		value = math.floor(value / (2 ^ 8))
	end
	wh:write(bytes)
end

local function read_u4(rh)
	local value = 0
	for i = 1, sizes.u4 do
		local byte = rh:read(1):byte()
		value = value + byte * (2 ^ ((sizes.u4 - i) * 8))
	end
	return value
end

local function read_c(rh)
	return rh:read(sizes.c)
end

local function read_channel(rh)
	local channel = read_c(rh)
	local length = read_u4(rh)
	if channel == 'I' or channel == 'L' then
		return channel, length
	else
		return channel, rh:read(length)
	end
end

local function decode_i4(bytestring)
	local value = 0
	for i = 1, sizes.i4 do
		local byte = bytestring:sub(i, i):byte()
		value = value + byte * (2 ^ ((sizes.i4 - i) * 8))
	end
	if value >= 2 ^ (sizes.i4 * 8 - 1) then
		value = value - 2 ^ (sizes.i4 * 8)
	end
	return value
end

local function write_block(wh, ...)
	local block = table.concat({...}, '\0')
	write_u4(wh, #block)
	wh:write(block)
end

local Client = {}
Client.__index = Client

function Client.connect(rh, wh)
	local client = {}
	setmetatable(client, Client)
	client.rh = rh
	client.wh = wh
	client:read_hello()
	return client
end

function Client.open(repo)
	local cmd = { 'hg', 'serve', '--cmdserver', 'pipe', '--config', 'ui.interactive=True' }
	if repo ~= nil then
		table.insert(cmd, '-R')
		table.insert(cmd, repo)
	end
	local pid, wh, rh = lpc.run(unpack(cmd))
	local client = Client.connect(rh, wh)
	client.lpcpid = pid
	return client
end

function Client:close()
	if self.wh ~= nil then self.wh:close() end
	if self.rh ~= nil then self.rh:close() end
	if self.lpcpid ~= nil then lpc.wait(self.lpcpid) end
end

function Client:read_hello()
	local channel, message = read_channel(self.rh)
	assert(channel == 'o', 'channel for the hello message must be "o"')
	local index = 1
	while index <= #message do
		local nexteol = message:find('\n', index + 1, true)
		if nexteol == nil then nexteol = #message + 1 end
		local line = message:sub(index, nexteol - 1)
		local ci = line:find(': ', 1, true)
		if ci ~= nil then
			local key, value = line:sub(1, ci - 1), line:sub(ci + 2)
			if key == 'capabilities' then
				self.capabilities = {}
				for cap in value:gmatch('%S+') do
					self.capabilities[cap] = true
				end
			elseif key == 'encoding' then
				self.encoding = value
			elseif key == 'pid' then
				self.pid = tonumber(value)
			elseif key == 'pgid' then
				self.pgid = tonumber(value)
			end
		end
		index = nexteol + 1
	end
end

function Client:getencoding()
	if not self.capabilities.getencoding then
		return nil, 'getencoding is not supported by this command server'
	end
	self.wh:write('getencoding\n')
	self.wh:flush()
	while true do
		local channel, message = read_channel(self.rh)
		if channel == 'r' then
			return message
		elseif channel == 'e' or channel:lower() ~= channel then
			return nil, message
		end
	end
end

function Client:runcommand_co(command)
	if not self.capabilities.runcommand then
		return nil, 'runcommand is not supported by this command server'
	end
	self.wh:write('runcommand\n')
	write_block(self.wh, unpack(command))
	self.wh:flush()
	return coroutine.create(function()
		while true do
			local channel, message = read_channel(self.rh)
			if channel == 'r' then
				return channel, decode_i4(message)
			elseif channel:lower() ~= channel and channel ~= 'I' and channel ~= 'L' then
				return channel, message
			else
				coroutine.yield(channel, message)
			end
		end
	end)
end

function Client:runcommand(command, input)
	local co, err = self:runcommand_co(command)
	if type(co) ~= 'thread' then
		return nil, '', err, ''
	end
	local o = ''
	local e = ''
	local d = ''
	input = tostring(input or '')
	local function write_input(length)
		write_block(self.wh, input:sub(1, length))
		self.wh:flush()
		input = input:sub(length + 1)
	end
	while coroutine.status(co) ~= 'dead' do
		local status, channel, message = coroutine.resume(co)
		if not status then
			return nil, '', '\nhglib: coroutine failure: ' .. channel, ''
		end
		if channel == 'r' then
			return message, o, e, d
		elseif channel == 'o' then
			o = o .. message
		elseif channel == 'e' then
			e = e .. message
		elseif channel == 'd' then
			d = d .. message
		elseif channel == 'I' then
			write_input(message)
		elseif channel == 'L' then
			write_input(math.min(input:find('\n') or message, message))
		elseif channel:lower() ~= channel then
			e = e .. '\nhglib: unexpected data on required channel "' .. channel .. '"'
			return nil, o, e, d
		end
	end
end

return {
	write_u4 = write_u4,
	read_u4 = read_u4,
	read_c = read_c,
	read_channel = read_channel,
	decode_i4 = decode_i4,
	write_block = write_block,
	Client = Client
}
