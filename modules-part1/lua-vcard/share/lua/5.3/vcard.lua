local vcard = {}

local lpeg = require("lpeg")

-- Format element data
function formatData(data)
	data = data:gsub("\n","")
	if data:match(";") then
		local rdata = {}
		data = data:gsub("(.-);", function(c) table.insert(rdata, c); return "" end)
		table.insert(rdata, data)
		return rdata
	else
		return data:gsub("\\n", "\n"):gsub("\\,", ",")
	end
end

function vcard.parse(data)
	-- Check for invalid data
	if not type(data) == "string" or not data:match("BEGIN:VCARD") or not data:match("END:VCARD") then
		return nil
	end

	-- Get locale elements
	local l = {}
	lpeg.locale(l)

	-- Syntax elements defined in the RFC6350 (section 3.3)
	local _eol = lpeg.P("\r\n") + lpeg.P("\n\r") + lpeg.P("\r") + lpeg.P("\n") -- RFC says CRLF but, you know...
	local _token = (lpeg.P(l.alnum) + lpeg.P("-"))^1 -- Matches iana-token and x-name
	local _psafe = lpeg.P(1) - (lpeg.P("\"") + lpeg.P(l.cntrl)) -- Is QSAFE-CHAR
	local _pvalue = (_psafe - lpeg.S(":;"))^1 + (lpeg.P("\"") * _psafe^1 * lpeg.P("\"")) -- Is param-value

	-- Begin and end elements
	local _begin = lpeg.P("BEGIN:VCARD") * _eol
	local _end = lpeg.P("END:VCARD") * _eol^0

	-- Group and name
	local group = lpeg.Cg(lpeg.C(_token) * lpeg.P("."), "group")^0
	local name = lpeg.Cg(lpeg.C(_token), "name")

	-- Parameters
	local oldparam = lpeg.P(";") * lpeg.C(_token) -- 2.0/2.1 format, deprecated
	local param = lpeg.P(";") * lpeg.C(_token * lpeg.P("=") * _pvalue)
	local parameters = lpeg.Cg(lpeg.Ct((param+oldparam)^0), "attributes")

	-- Value
	local vdata = (lpeg.P(1) - (_eol-(_eol*lpeg.P(" "))))^1
	local value = lpeg.Cg(lpeg.P(":") * lpeg.C(vdata)/formatData, "data")

	-- Full element
	local line = lpeg.Ct(group * name * parameters * value * _eol) - _end

	-- Full vcards
	local rcard = _begin * (lpeg.Ct(line^1)) * _end
	local cards = lpeg.Ct(rcard^1)

	-- Parse cards and return
	return lpeg.match(cards, data)
end

return vcard
