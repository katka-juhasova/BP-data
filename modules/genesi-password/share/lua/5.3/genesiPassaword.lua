-- Module options:
local error_msg_genesiPassword = true
local dir_system_genesiPassword = false
local register_global_module_genesiPassword = false
local global_module_name_genesiPassword = 'genesiPassword'

--[==[
By 2016 Tiago Danin
GNU GENERAL PUBLIC LICENSE
Version 3, June 1991
see https://github.com/TiagoDanin/GenesiPassword/blob/master/LICENSE
]==]--

local genesiPassword = {
	version = '1.1.1',
	name = 'GenesiPassword',
	author = 'Tiago Danin - 2016',
	license = 'GPL v3',
	page = 'github.com/LuaAdvanced/GenesiPassword'
}

if register_global_module_genesiPassword then
	_G[global_module_name_genesiPassword] = genesiPassword
end

function genesiPassword.gen (input, tam, advan)
	if not input then
		if error_msg_genesiPassword then error('genesiPassword[gen] >> ERRO: input is value nil') end
		return false
	end
	if not tam then
		if error_msg_genesiPassword then error('genesiPassword[gen] >> ERRO: tam is value nil') end
		return false
	end

	local punctuation = false
	local characters = false
	local number = false
	local text = false

	if type(input) == 'string' and input == 'all' then
		pontuation = true
		characters = true
		number = true
		text = true
	elseif type(input) == 'table' then
		for i,v in ipairs(input) do
			if v == '1' or v == 1 then
				punctuation = true
			elseif v == '2' or v == 2 then
				characters = true
			elseif v == '3' or v == 3 then
				number = true
			elseif v == '4' or v == 4 then
				text = true
			elseif v == 'all' or v == 0 then
				punctuation = true
				characters = true
				number = true
				text = true
			else
				if error_msg_genesiPassword then error('genesiPassword[gen] >> ERRO: input > '.. v ..' is invalid!') end
			end
		end
	else
		if error_msg_genesiPassword then error('genesiPassword[gen] >> ERRO: input is invalid!') end
		return false
	end

	local pass = ''
	local i = 0
	if type(tam) ~= 'number' then
		if tam:match('^[1234567890]*$') then
			tam = math.abs(tam)
		else
			if error_msg_genesiPassword then error('genesiPassword[gen] >> ERRO: tam not is number') end
			return false
		end
	else
		tam = math.abs(tam)
	end
	local fix = os.date('%S')
	fix = ((fix + os.date('%M')) + math.random(1, 5))
	local gen = true
	while gen do
		local n = math.random(33, (190 + fix))

		if punctuation and n >= 33 and n <= 47 then
			pass = pass .. utf8.char(n)
			i = i + 1
		elseif punctuation and n >= 58 and n <= 64 then
			pass = pass .. utf8.char(n)
			i = i + 1
		elseif characters and n >= 161 and n <= 172 then
			pass = pass .. utf8.char(n)
			i = i + 1
		elseif characters and n >= 174 and n <= 190 then
			pass = pass .. utf8.char(n)
			i = i + 1
		elseif number and n >= 49 and n <= 57 then
			pass = pass .. utf8.char(n)
			i = i + 1
		elseif text and n >= 65 and n <= 90 then
			pass = pass .. utf8.char(n)
			i = i + 1
		elseif text and n >= 97 and n <= 122 then
			pass = pass .. utf8.char(n)
			i = i + 1
		end

		if advan then
			for k,v in pairs(advan) do
				if type(k) ~= 'number' and v and type(v) == 'string' then
					pass = pass:gsub(k:match('^(.*)$'), v)
				end
			end
		end

		if i >= tam then
			gen = false
		end
	end

	return pass
end

function genesiPassword.genesi (input, tam)

	if not input then
		if error_msg_genesiPassword then error('genesiPassword[genesi] >> ERRO: input is value nil') end
		return false
	end
	if not tam then
		if error_msg_genesiPassword then error('genesiPassword[genesi] >> ERRO: tam is value nil') end
		return false
	end
	if type(tam) ~= 'number' then
		if tam:match('^[1234567890]*$') then
			tam = math.abs(tam)
		else
			if error_msg_genesiPassword then error('genesiPassword[gen] >> ERRO: tam not is number') end
			return false
		end
	else
		tam = math.abs(tam)
	end

	local genesi = genesiPassword.gen(input, tam)

	return genesi
end

function genesiPassword.save (input, tam, dir, name, number)

	if not input then
		if error_msg_genesiPassword then error('genesiPassword[save] >> ERRO: input is value nil') end
		return false
	end
	if not tam then
		if error_msg_genesiPassword then error('genesiPassword[save] >> ERRO: tam is value nil') end
		return false
	end
	if type(tam) ~= 'number' then
		if tam:match('^[1234567890]*$') then
			tam = math.abs(tam)
		else
			if error_msg_genesiPassword then error('genesiPassword[gen] >> ERRO: tam not is number') end
			return false
		end
	else
		tam = math.abs(tam)
	end

	if not name then
		name = 'Pass_' .. math.random(100, 900) .. '_' .. os.date()
	end
	if number and type(number) ~= 'number' then
		if number:match('^[1234567890]*$') then
			number = math.abs(number)
		else
			if error_msg_genesiPassword then error('genesiPassword[save] >> ERRO: number not is number') end
			return false
		end
	elseif not number then
		number = 1
	end


	if dir_system_genesiPassword then
		dir = dir_system_genesiPassword .. '/' .. dir
	end
	if dir then
		name = dir .. name
	end

	local file_save = name .. '.txt'
	local file = io.open(name .. '.txt', 'w+')
	local pass = ''
	for i=1, number do
		pass = pass .. genesiPassword.genesi(input, tam) .. '\n'
	end
	file:write(pass)
	file:close()

	return file_save
end

return genesiPassword
