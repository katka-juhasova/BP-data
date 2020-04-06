--[[
-- Copyright 2017 Gil Barbosa Reis <gilzoide@gmail.com>
-- This file is part of Argmatcher.
--
-- Argmatcher is free software: you can redistribute it and/or modify
-- it under the terms of the GNU Lesser General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- Argmatcher is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU Lesser General Public License for more details.
--
-- You should have received a copy of the GNU Lesser General Public License
-- along with Argmatcher.  If not, see <http://www.gnu.org/licenses/>.
--]]

local argmatcher = {
	VERSION = "0.1.1",
}
argmatcher.__index = argmatcher

function argmatcher.new()
	return setmetatable({
		_known_options = {},
	}, argmatcher)
end

function argmatcher._on(self, t, stop)
	assert(t[1], "[argmatcher] There must be at least one name for option")
	assert(t.callback or t.store, "[argmatcher] You should provide a 'callback' function or a 'store' table")

	local names = {}
	for i, name in ipairs(t) do names[i] = name end
	local match = {
		names = names,
		stop = stop,
		arg = t.arg,
		description = t.description,
		callback = t.callback or function(arg) t.store[t.arg or names[1]] = arg or true end,
	}
	table.insert(self._known_options, match)
	for _, name in ipairs(t) do
		assert(self._known_options[name] == nil,
				string.format("[argmatcher] Option %q was already defined", name))
		self._known_options[name] = match
	end
end

function argmatcher.on(self, t)
	argmatcher._on(self, t, nil)
end

function argmatcher.stop_on(self, t)
	argmatcher._on(self, t, true)
end

function argmatcher.parse(self, args)
	args = args or arg
	local unmatched = {}

	local i = 1  -- iterator
	repeat
		local argi = args[i]
		local match = self._known_options[argi]
		if match then
			local callback_arg
			-- option expects argument
			if match.arg then
				callback_arg = args[i + 1]
				assert(callback_arg and self._known_options[callback_arg] == nil,
						string.format("Argument is required for option %q", argi))
				i = i + 1
			end
			match.callback(callback_arg)
			if match.stop then
				-- insert what's left as unmatched
				for j = i + 1, #args do table.insert(unmatched, args[j]) end
				break
			end
		else
			table.insert(unmatched, argi)
		end
		i = i + 1
	until i > #args

	return unmatched
end

function argmatcher.show_help(self, prologue, epilogue)
	local options = {}
	for i, opt in ipairs(self._known_options) do
		options[i] = string.format("  %-38s %s",
				table.concat(opt.names, "|") .. (opt.arg and " " .. opt.arg or ""),
				opt.description or "")
	end
	local lines = {}
	table.insert(lines, prologue)
	table.insert(lines, #options > 0 and "Options:\n" .. table.concat(options, "\n"))
	table.insert(lines, epilogue)
	io.write(table.concat(lines, "\n\n") .. "\n")
end

function argmatcher.nop() end

return argmatcher
