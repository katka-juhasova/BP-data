-- Copyright (C) 2020 Jacob Shtabnoy <shtabnoyjacob@scps.net>
-- Licensed under the terms of the ISC License, see LICENSE

local CHECK_FAILURE_MESSAGE = "Bad type for argument %d (Expected %s, got %s)";

function getExpectedString(rules)
	local s = "";
	for i,rule in ipairs(rules) do
		if rule.checkNot then
			s = s..("not %s"):format(rule.type);
		else
			s = s..rule.type;
		end
		if i > 1 then
			s = s .. "/"
		end
	end
	return s;
end

local function runRules(self)
	local rules  = rawget(self, "rules");
	local value = rawget(self, "value");
	local argNumber = rawget(self, "argNumber");
	for _,rule in pairs(rules) do
		if rule.checkNot then
			if value ~= rule.type then
				return;
			end
		else
			if value == rule.type then
				return;
			end
		end
	end
	error(CHECK_FAILURE_MESSAGE:format(argNumber, getExpectedString(rules), value));
end

local function constraintIndex(self, key)
	if key == "null" then
		key = "nil";
	end
	local rules = rawget(self, "rules");
	local rule = {};
	if key:sub(1,4) == "not_" then
		rule.checkNot = true;
	else
		rule.checkNot = false;
	end
	rule.type = key;
	table.insert(rules, rule);
	return self;
end

local function Type(value, argNumber)
	local self = setmetatable({}, {
		["__index"] = constraintIndex;
		["__call"] = runRules; 
	});
	rawset(self, "rules", {});
	rawset(self, "value", type(value));
	rawset(self, "argNumber", argNumber);
	return self;
end

return Type;
