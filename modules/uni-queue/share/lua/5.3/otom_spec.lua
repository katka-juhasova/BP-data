--Using "busted" framework

expose("require otom", function()
	otom = require("otom")
	it("package.loaded", function()
		assert.truthy(package.loaded.otom)
	end)
	it("package is a table", function()
		assert.are.equals(type(otom), "table")
	end)
	it("otom.new is a function", function()
		assert.are.equals(type(otom.new), "function")
	end)
end)

describe("new with initial values", function()
	describe("one-to-one", function()
		local ik = "initial key"
		local iv = "initial value"
		local ft, rt = otom.new{[ik]=iv}
		it("forward", function()
			assert.are.equals(ft[ik], iv)
		end)
		it("reverse", function()
			assert.are.equals(rt[iv], ik)
		end)
	end)

	describe("custom iterator factory", function()
		local planets = {
			"Mercury",
			"Venus",
			"Earth",
			"Mars"
		}
		local planet_iter_factory = function()
			return next, planets, nil
		end
		local ft, rt = otom.new(nil, nil, planet_iter_factory)
		it("actually used", function()
			for i,v in ipairs(planets) do
				assert.are.equals(ft[i], v)
				assert.are.equals(rt[v], i)
			end
		end)
	end)

	describe("one-to-many", function()
		local iv = "initial value"
		local init_table = { iv, iv }
		it("default", function()
			assert.has_error(function()
				otom.new(init_table)
			end, "Initial table is not one-to-one.")
		end)
		it("otom.ERR", function()
			assert.has_error(function()
				otom.new(init_table, otom.ERR)
			end, "Initial table is not one-to-one.")
		end)
		it("otom.FIRST", function()
			local ft, rt = otom.new(init_table, otom.FIRST, ipairs)
			assert.are.equals(ft[1], iv)
			assert.is_nil(ft[2])
			assert.are.equals(rt[iv], 1)
		end)
		it("otom.LAST", function()
			local ft, rt = otom.new(init_table, otom.LAST, ipairs)
			assert.are.equals(ft[2], iv)
			assert.is_nil(ft[1])
			assert.are.equals(rt[iv], 2)
		end)
	end)
end)

describe("newindex", function()
	local ft, rt = otom.new()
	it("forward", function()
		local fk = "Forward key"
		local fv = "Forward value"
		ft[fk] = fv
		assert.are.equals(ft[fk], fv)
		assert.are.equals(rt[fv], fk)
	end)
	it("reverse", function()
		local rk = "Reverse key"
		local rv = "Reverse value"
		rt[rk] = rv
		assert.are.equals(rt[rk], rv)
		assert.are.equals(ft[rv], rk)
	end)
end)

describe("overwrite key", function()
	local ft, rt = otom.new()
	describe("forward", function()
		local fk = "Forward key"
		local fv_1 = "Forward value"
		local fv_2 = "Another forward value"
		ft[fk] = fv_1
		ft[fk] = fv_2
		it("transferred value", function()
			assert.are.equals(ft[fk], fv_2)
			assert.are.equals(rt[fv_2], fk)
		end)
		it("eliminated old value", function()
			assert.is_nil(rt[fv_1])
		end)
	end)
	describe("reverse", function()
		local rk = "Reverse key"
		local rv_1 = "Reverse value"
		local rv_2 = "Another reverse value"
		rt[rk] = rv_1
		rt[rk] = rv_2
		it("transferred value", function()
			assert.are.equals(rt[rk], rv_2)
			assert.are.equals(ft[rv_2], rk)
		end)
		it("eliminated old value", function()
			assert.is_nil(ft[rv_1])
		end)
	end)
end)

describe("overwrite value", function()
	local ft, rt = otom.new()
	describe("forward", function()
		local fk_1 = "Forward key"
		local fk_2 = "Another forward key"
		local fv = "Forward value"
		ft[fk_1] = fv
		ft[fk_2] = fv
		it("transferred value", function()
			assert.are.equals(ft[fk_2], fv)
			assert.are.equals(rt[fv], fk_2)
		end)
		it("eliminated old value", function()
			assert.is_nil(ft[fk_1])
		end)
	end)
	describe("reverse", function()
		local rk_1 = "Reverse key"
		local rk_2 = "Another reverse key"
		local rv = "Reverse value"
		rt[rk_1] = rv
		rt[rk_2] = rv
		it("transferred value", function()
			assert.are.equals(rt[rk_2], rv)
			assert.are.equals(ft[rv], rk_2)
		end)
		it("eliminated old value", function()
			assert.is_nil(rt[rk_1])
		end)
	end)
end)

describe("pairs", function()
	local planets = {
		"Mercury",
		"Venus",
		"Earth",
		"Mars",
		"Jupiter",
		"Saturn",
		"Uranus",
		"Neptune"
	}
	local ft, rt = otom.new(planets)
	it("forward", function()
		for k,v in pairs(ft) do
			assert.are.equals(ft[k], v)
			assert.are.equals(rt[v], k)
			assert.are.equals(planets[k], v)
		end
	end)
	it("reverse", function()
		for k,v in pairs(rt) do
			assert.are.equals(rt[k], v)
			assert.are.equals(ft[v], k)
			assert.are.equals(planets[v], k)
		end
	end)
end)

describe("ipairs", function()
	local planets = {
		"Mercury",
		"Venus",
		"Earth",
		"Mars",
		"Jupiter",
		"Saturn",
		"Uranus",
		"Neptune"
	}
	local ft, rt = otom.new(planets)
	it("forward", function()
		local old_i = 0
		for i,v in ipairs(ft) do
			assert.are.equals(ft[i], v)
			assert.are.equals(rt[v], i)
			assert.are.equals(planets[i], v)
			assert.are.equals(i, old_i + 1)
			old_i = old_i + 1
		end
	end)
	local frt, rrt = otom.new(rt)
	it("reverse", function()
		local old_i = 0
		for i,v in ipairs(rrt) do
			assert.are.equals(rrt[i], v)
			assert.are.equals(frt[v], i)
			assert.are.equals(planets[i], v)
			assert.are.equals(i, old_i + 1)
			old_i = old_i + 1
		end
	end)
end)

describe("setmetatable", function()
	local meta = {}
	local ft, rt = otom.new()
	it("forward", function()
		assert.has_error(function()
			setmetatable(ft, meta)
		end)
	end)
	it("reverse", function()
		assert.has_error(function()
			setmetatable(rt, meta)
		end)
	end)
end)

describe("array size", function()
	local ft, rt = otom.new()
	local values = {"Mercury", "Venus", "Earth", "Mars"}
	for i,v in ipairs(values) do
		table.insert(ft, v)
	end
	it("forward length", function()
		assert.are.equals(#ft, #values)
	end)
	it("forward ipairs", function()
		for i,v in ipairs(values) do
			assert.are.equals(ft[i], v)
		end
	end)
	it("reverse ipairs", function()
		for i,v in ipairs(values) do
			assert.are.equals(i, rt[v])
		end
	end)
end)

describe("reverse array size", function()
	local ft, rt = otom.new()
	local values = {"Mercury", "Venus", "Earth", "Mars"}
	for i,v in ipairs(values) do
		table.insert(rt, v)
	end
	it("reverse length", function()
		assert.are.equals(#rt, #values)
	end)
	it("reverse ipairs", function()
		for i,v in ipairs(values) do
			assert.are.equals(rt[i], v)
		end
	end)
	it("forward ipairs", function()
		for i,v in ipairs(values) do
			assert.are.equals(i, ft[v])
		end
	end)
end)
