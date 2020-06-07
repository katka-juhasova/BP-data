local otom = {}

local function custom_pairs(mt)
	return function()
		return next, mt.storage, nil
	end
end

local function otom_mt(fmt, rmt)
	fmt.storage = {}
	fmt.__index = fmt.storage
	fmt.__newindex = function(t, k, v)
		local old_v = fmt.storage[k]
		local old_k = rmt.storage[v]
		if old_v ~= nil then
			rmt.storage[old_v] = nil
		end
		if old_k ~= nil then
			fmt.storage[old_k] = nil
		end
		if k ~= nil then
			fmt.storage[k] = v
		end
		if v ~= nil then
			rmt.storage[v] = k
		end
	end
	fmt.__pairs = custom_pairs(fmt) -- https://www.lua.org/manual/5.3/manual.html#pdf-pairs
	fmt.__metatable = false
	fmt.__len = function()
		return #fmt.storage
	end
end

otom.ERR = 0
otom.FIRST = 1
otom.LAST = 2

function otom.new(initial_table, repeat_mode, iter_factory)
	local initial_table = initial_table or {}
	local repeat_mode = repeat_mode or otom.ERR
	local iter_factory = iter_factory or pairs
	local forward, reverse, fmt, rmt = {}, {}, {}, {}
	otom_mt(fmt, rmt)
	otom_mt(rmt, fmt)
	setmetatable(forward, fmt)
	setmetatable(reverse, rmt)

	for k,v in iter_factory(initial_table) do
		local repeated_value = reverse[v] ~= nil
		if repeated_value and repeat_mode == otom.ERR then
			error("Initial table is not one-to-one.")
		elseif repeated_value and repeat_mode == otom.FIRST then
			--Don't change the key-value relationship.
		else --if not repeated_value or repeat_mode == otom.LAST then --conditions implied
			forward[k] = v
		end
	end
	return forward, reverse
end

return otom
