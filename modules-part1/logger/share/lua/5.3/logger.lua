local DEFAULT_LEVELS = {
	-- Most detailed information. Expect these to be written to logs only
	"TRACE",
	-- Detailed information on the flow through the system. Expect these to be written to logs only. Generally speaking,
	-- most lines logged by your application should be written as DEBUG.
	"DEBUG",
	-- Interesting runtime events (startup/shutdown). Expect these to be immediately visible on a console, so be
	-- conservative and keep to a minimum.
	"INFO",
	-- Use of deprecated APIs, poor use of API, 'almost' errors, other runtime situations that are undesirable or
	-- unexpected, but not necessarily "wrong". Expect these to be immediately visible on a status console.
	"WARN",
	-- Other runtime errors or unexpected conditions. Expect these to be immediately visible on a status console.
	"ERROR",
	-- Severe errors that cause premature termination. Expect these to be immediately visible on a status console.
	"FATAL",
	-- The highest possible rank and is intended to turn off logging.
	"OFF",
}

local function indexof(val, t)
	local index = {}
	for k,v in pairs(t) do
		index[v] = k
	end
	return index[val]
end

-------------------------------------------------------------------------------
-- Creates a new logger object
-- @param append Function used by the logger to append a message with a
--	log-level to the log stream.
-- @return Table representing the new logger object.
-------------------------------------------------------------------------------
return function(append, settings)
	if type(append) ~= "function" then
		append = function(self, level, message)
			io.stderr:write(level .. '\t' .. message .. '\n')
		end
	end

	local logger = {}
	logger.append = append

	-- initialize all default values
	if type(settings) ~= "table" then
		settings = {}
	end
	setmetatable(settings, {
		__index = {
			levels = DEFAULT_LEVELS,
			init_level = DEFAULT_LEVELS[1]
		}
	})
	logger.levels = settings.levels
	logger.levelIndexByName = {}
	for k,v in ipairs(settings.levels) do
		logger.levelIndexByName[v] = k
	end

	-- Per level function.
	for _,l in pairs(logger.levels) do
		if type(l) == 'string' then
			logger[l:lower()] = function(self, msg)
				return self:log(l, msg)
			end
		end
	end

	function logger:setLevel(level)
		local order
		if type(level) == "number" then
			order = level
			level = self.levels[order]
		elseif type(level) == "string" then
			order = indexof(level, self.levels)
		end
		if not level then
			return
		end
		if not order then
			return
		end
		self.level = level
		self.level_order = order
	end
	-- initialize log level.
	logger:setLevel(settings.init_level)

	-- generic log function.
	function logger:log(level, msg)
		local order
		if type(level) == "number" then
			order = level
			level = self.levels[order]
		elseif type(level) == "string" then
			order = indexof(level, self.levels)
		end
		if order >= self.level_order then
			return self:append(level, msg)
		else
			return
		end
	end

	return logger
end
