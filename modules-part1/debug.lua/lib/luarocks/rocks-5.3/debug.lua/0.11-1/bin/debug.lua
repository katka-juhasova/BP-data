#!/usr/bin/env lua

do

do
local _ENV = _ENV
package.preload[ "ui" ] = function( ... ) local arg = _G.arg;
local tfx = require "termfx"

local config
local function resetconfig()
	config = {
		widget_fg = tfx.color.WHITE,
		widget_bg = tfx.color.BLUE,

		sel_fg = tfx.color.BLACK,
		sel_bg = tfx.color.CYAN,

		elem_fg = tfx.color.BLUE,
		elem_bg = tfx.color.WHITE,
		
		sep = '|'
	}
end

local function getconfig(n)
	return config[n]
end

-- helper
-- augment for type that can recognize userdata with a named metatable
local _type = type
local type = function(v)
	local t = _type(v)
	if t == "userdata" or t == "table" then
		local mt = getmetatable(v)
		if mt then
			if mt.__type then
				if type(mt.__type) == "function" then
					return string.lower(mt.__type(t))
				else
					return string.lower(mt.__type)
				end
			elseif t == "userdata" then
				local reg = debug.getregistry()
				for k, v in pairs(reg) do
					if v == mt then
						return string.lower(k)
					end
				end
			end
		end
	end
	return t
end

-- api
-- draw a frame for an ui element
-- top left is x, y, dimensions are w, h, title is optional
-- may resize frame if it leaves the screen somewhere.
-- returns x, y, w, h of frame contents
local function drawframe(x, y, w, h, title)
	local tw, th = tfx.size()
	local pw = 0

	if title then
		title = tostring(title)
		pw = #title
		if w < #title then w = #title end
	end

	if x < 2 then x = 2 end
	if y < 2 then y = 2 end
	if x + w >= tw then w = tw - x end
	if y + h >= th then h = th - y end

	local ccell = tfx.newcell('+')
	local hcell = tfx.newcell('-')
	local vcell = tfx.newcell('|')
	
	for i = x, x+w do
		tfx.setcell(i, y-1, hcell)
		tfx.setcell(i, y+h, hcell)
	end
	for i = y, y+h do
		tfx.setcell(x-1, i, vcell)
		tfx.setcell(x+w, i, vcell)
	end
	tfx.setcell(x-1, y-1, ccell)
	tfx.setcell(x-1, y+h, ccell)
	tfx.setcell(x+w, y-1, ccell)
	tfx.setcell(x+w, y+h, ccell)
	
	tfx.rect(x, y, w, h, ' ')

	if title then
		if w < pw then pw = w end
		tfx.printat(math.floor(x + (w - pw) / 2), y - 1, title, pw)
	end
	
	return x, y, w, h
end

-- helper
-- draw a frame of width w and height h, centered on the screen
-- title is optional
local function frame(w, h, title)
	local tw, th = tfx.size()
	if w + 2 > tw then w = tw - 2 end
	if h + 2 > th then h = th - 2 end
	local x = math.floor((tw - w) / 2) + 1
	local y = math.floor((th - h) / 2) + 1
	return drawframe(x, y, w, h, title)
end

-- helper
-- format a string to fit a certain width. Returns a table with the lines
local function format(msg, w)
	if not w or w >= #msg then return { msg } end
	local pos, last = 1, #msg
	local res = {}
	repeat
		res[#res+1] = string.sub(msg, pos, pos + w - 1)
		pos = pos + w
	until pos > last

	return res
end

-- helper
-- returns true if evt contains a keypress for what is considered an
-- escape key, one that closes the current window. This can be forced to
-- only be escape, or to also include enter.
-- return true if evt contains an escape key press, false if not.
local function is_escape_key(evt, onlyesc)
	if not evt then return false end
	if evt.key == tfx.key.ESC then
		return true
	end
	if not onlyesc and evt.key == tfx.key.ENTER then
		return true
	end
	return false
end

-- helper
-- waits for an event that is a keypress, then returns.
local function waitkeypress()
	local evt
	repeat
		evt = tfx.pollevent()
	until evt and evt.type == 'key'
	return evt.char or evt.key
end

-- helper
-- draw a simple string s at pos x, y, width w, filling the rest between
-- #s and w with f or blanks
-- returns true
local function drawfield(x, y, s, w, f)
	f = f or ' '
	s = tostring(s)
	tfx.printat(x, y, s, w)
	if #s < w then
		tfx.printat(x + #s, y, string.rep(f, w - #s))
	end
	return true
end

-- api
-- draw a list of rows contained in tbl at position x, y, size w, h.
-- first is first line to show, may be modified. renderrow, if present,
-- is a function to render an individual row, which defaults to  a simple
-- function calling drawfield(). The functions signature is
-- renderrow(row, s, x, y, w, extra)
-- where row is the row number, s is the string, x, y is the position,
-- w is the width and extra is what was passed to drawlist as rr_extra

-- default renderrow function:
local function default_renderrow(row, s, x, y, w, extra)
	if s then
		drawfield(x, y, tostring(s), w)
	end
end

local function drawlist(tbl, first, x, y, w, h, renderrow, rr_extra)
	local fg, bg = tfx.attributes()
	local tw, th = tfx.size()
	local sx, sy
	local fo, bo, hl
	local ntbl = #tbl
	
	if ntbl == 0 then return end

	renderrow = renderrow or default_renderrow

	if first < 1 then
		first = 1
	end

	if ntbl >= h then
		w = w - 1
		sx = x + w
		sy = y
		if ntbl - first + 1 <= h then
			first = ntbl - h + 1
			if first < 1 then
				first = 1
				h = ntbl < h and ntbl or h
			end
		end
	end
	
	if w < 1 or h < 1 or x > tw or y > th or x + w < 1 or y + h < 1 then
		return false
	end
	
	-- contents
	first = first - 1
	for i=1, h do
		local s = tbl[first + i] 
		tfx.attributes(fg, bg)
		renderrow(first + i, s, x, y, w, rr_extra)
		y = y + 1
	end
	
	-- scrollbar
	if ntbl > h then
		local sh = math.floor(h * h / ntbl)
		local sf = math.floor(first * (h - sh) / (ntbl - h)) + sy
		if sf + sh > h then sf = h - sh + 1 end
		local sl = sf + sh
		for yy = sy, sy + h - 1 do
			if yy >= sf and yy <= sl then
				tfx.setcell(sx, yy, '#', config.elem_fg, config.elem_bg)
			else
				tfx.setcell(sx, yy, ' ', config.elem_fg, config.elem_bg)
			end
		end
	end
	
	return first + 1
end

----- drawtext -----

-- api
-- draw some text. The argument table contains strings
local function drawtext_renderrow(row, s, x, y, w, extra)
	if s then
		if extra.hr and row == extra.hr then
			tfx.attributes(config.sel_fg, config.sel_bg)
		end
		drawfield(x, y, s, w)
	end
end

local function drawtext(tbl, first, x, y, w, h, hr)
	local extra = { hr = hr }
	return drawlist(tbl, first, x, y, w, h, drawtext_renderrow, extra)
end

----- text -----

-- api widget
-- show lines of text contained in tbl
local function text(tbl, title)
	local first = 1
	local th = #tbl
	local w, h = 0, th
	local x, y
	local quit = false
	local evt
	
	for i = 1, #tbl do
		local lw = #tbl[i]
		if lw > w then w = lw end
	end
	
	tfx.attributes(config.widget_fg, config.widget_bg)
	x, y, w, h = frame(w, th, title)
	if th > h then
		x, y, w, h = frame(w+1, th, title)
	end
	
	repeat
		x, y, w, h = frame(w, h, title)
		tfx.attributes(config.widget_fg, config.widget_bg)
		first = drawtext(tbl, first, x, y, w, h)
		tfx.present()
		
		evt = tfx.pollevent()
		if evt.key == tfx.key.ARROW_UP then
			first = first - 1
		elseif evt.key == tfx.key.ARROW_DOWN then
			first = first + 1
		elseif evt.key == tfx.key.PGUP then
			first = first - h
		elseif evt.key == tfx.key.PGDN then
			first = first + h
		elseif is_escape_key(evt) then
			quit = true
		end
	until quit
end

-- api widget
-- ask the user something, providing a table of buttons for answers.
-- Default is { "Yes", "No" }
-- Returns the number and the text of the selected button, or nil on abort
local function ask(msg, btns, title)
	local sel = 1
	btns = btns or { "Yes", "No" }

	tfx.attributes(config.widget_fg, config.widget_bg)

	local bw = #btns[1]
	for i = 2, #btns do
		bw = bw + 1 + #btns[i]
	end

	local tw = tfx.width()
	local ma = format(msg, tw / 2)
	local mw = bw
	for i = 1, #ma do
		if #ma[i] > mw then mw = #ma[i] end
	end
	local x, y, w, h = frame(mw, #ma+1, title)
	drawlist(ma, 1, x, y, w, h)	

	local evt
	repeat
		local bp = math.floor(w - bw) / 2
		if bp < 1 then bp = 1 end
		local bw = w - bp + 1
		for i = 1, #btns do
			if i == sel then
				tfx.attributes(config.sel_fg, config.sel_bg)
			else
				tfx.attributes(config.elem_fg, config.elem_bg)
			end
			tfx.printat(x - 1 + bp, y + #ma, btns[i], bw - bp + 1)
			bp = bp + 1 + #btns[i]
			if bp > bw then break end
		end
		tfx.present()
	
		evt = tfx.pollevent()
		if evt then
			if evt.key == tfx.key.ENTER then
				return sel
			elseif evt.key == tfx.key.TAB or evt.key == tfx.key.ARROW_RIGHT then
				sel = sel < #btns and sel + 1 or 1
			elseif evt.key == tfx.key.ARROW_LEFT then
				sel = sel > 1 and sel - 1 or #btns
			end
		end
		
	until is_escape_key(evt, true)
	return nil
end

-- api
-- input a single value
local function drawvalue(t, f, x, y, w)
	local m = #t
	if f + w - 1 >= m then m = f + w - 1 end
	for i = f, m do
		if i - f < w then
			local ch = t[i] or '_'
			tfx.setcell(x + i - f, y, ch)
		end
	end
end

local function input(x, y, w, orig)
	local f = 1
	local pos = 1
	local res = {}
	if orig then
		string.gsub(tostring(orig), "(.)", function(c) res[#res+1] = c end)
		pos = #res + 1
	end

	local evt
	repeat
		if pos - f >= w then
			f = pos - w + 1
		elseif pos < f then
			f = pos
		end

		drawvalue(res, f, x, y, w)
		tfx.setcursor(x + pos - f, y)
		tfx.present()

		evt = tfx.pollevent()
		local ch = evt.char
		if evt.key == tfx.key.SPACE then ch = " " end
		if ch >= ' ' then
			table.insert(res, pos, ch)
			pos = pos + 1
		elseif (evt.key == tfx.key.BACKSPACE or evt.key == tfx.key.BACKSPACE2)  and pos > 1 then
			table.remove(res, pos-1)
			pos = pos - 1
		elseif evt.key == tfx.key.DELETE  and pos <= #res then
			table.remove(res, pos)
			if pos > #res and pos > 1 then pos = pos - 1 end
		elseif evt.key == tfx.key.ARROW_LEFT and pos > 1 then
			pos = pos - 1
		elseif evt.key == tfx.key.ARROW_RIGHT and pos <= #res then
			pos = pos + 1
		elseif evt.key == tfx.key.HOME then
			pos = 1
		elseif evt.key == tfx.key.END then
			pos = #res + 1
		elseif evt.key == tfx.key.ESC then
			return nil
		end
	until is_escape_key(evt) or evt.key == tfx.key.TAB or evt.key == tfx.key.ARROW_UP or evt.key == tfx.key.ARROW_DOWN
	tfx.hidecursor()

	return table.concat(res), evt.key
end

-- api
-- draw a status bar. The last element in tbl is always right aligned,
-- the rest is left aligned.
local function drawstatus(tbl, y, w, sep)
	sep = sep or config.sep
	tfx.attributes(config.elem_fg, config.elem_bg)
	local w = tfx.width()
	local tw = 1
	
	for i=2, #tbl - 1 do
		tw = tw + #sep + #tbl[i]
	end
	
	tfx.printat(1, y, string.rep(' ', w))
	tfx.printat(1, y, tbl[1])
	local p = #tbl[1] + 1
	for i = 2, #tbl - 1 do
		tfx.printat(p, y, sep)
		tfx.printat(p + #sep, y, tbl[i])
		p = p + #tbl[i] + #sep
	end
	
	tfx.setcell(w - #tbl[#tbl], y, ' ')
	tfx.printat(w + 1 - #tbl[#tbl], y, tbl[#tbl])
end

-- api
-- change config options for the ui lib. see resetconfig() above for options
local function configure(tbl)
	for k, v in pairs(tbl) do
		if config[k] then
			if type(v) == type(config[k]) then
				config[k] = v
			else
				error("invalid value type for config option '"..k.."': "..type(v), 2)
			end
		else
			error("invalid config option '"..k.."'", 2)
		end
	end
end

-- api
-- overwrite tfx outputmode function: do the same but also reset all
-- colors to default. This is because with the change of the output mode,
-- the colors may also change.
local function outputmode(m)
	local om = tfx.outputmode(m)
	if m then resetconfig() end
	return om
end

----- initialize -----

tfx.init()
tfx.outputmode(tfx.output.NORMAL)
tfx.inputmode(tfx.input.ESC)
resetconfig()

----- return -----

return setmetatable({
	-- utilities
	drawframe = drawframe,
	frame = frame,
	drawlist = drawlist,
	drawtext = drawtext,
	drawstatus = drawstatus,
	drawfield = drawfield,

	input = input,


	-- widgets
	text = text,
	ask = ask,

	-- misc
--	configure = configure,
	getconfig = getconfig,
	outputmode = outputmode,
	formatwidth = format,
	waitkeypress = waitkeypress,
}, { __index = tfx })

end
end

do
local _ENV = _ENV
package.preload[ "loader" ] = function( ... ) local arg = _G.arg;
--[[
	complete lua 5.3 syntax

	chunk ::= block

	block ::= {stat} [retstat]

	stat ::=  ';' | 
		 varlist '=' explist | 
		 functioncall | 
		 label | 
		 'break' | 
		 'goto' Name | 
		 'do' block 'end' | 
		 'while' exp 'do' block 'end' | 
		 'repeat' block 'until' exp | 
		 'if' exp 'then' block {'elseif' exp 'then' block} ['else' block] 'end' | 
		 'for' Name '=' exp ',' exp [',' exp] 'do' block 'end' | 
		 'for' namelist 'in' explist 'do' block 'end' | 
		 'function' funcname funcbody | 
		 'local' 'function' Name funcbody | 
		 'local' namelist ['=' explist] 

	retstat ::= 'return' [explist] [';']

	label ::= '::' Name '::'

	funcname ::= Name {'.' Name} [':' Name]

	varlist ::= var {',' var}

	var ::=  Name | prefixexp '[' exp ']' | prefixexp '.' Name 

	namelist ::= Name {',' Name}

	explist ::= exp {',' exp}

	exp ::=  'nil' | 'false' | 'true' | Numeral | LiteralString | '...' | functiondef | 
		 prefixexp | tableconstructor | exp binop exp | unop exp 

	prefixexp ::= var | functioncall | '(' exp ')'

	functioncall ::=  prefixexp args | prefixexp ':' Name args 

	args ::=  '(' [explist] ')' | tableconstructor | LiteralString 

	functiondef ::= 'function' funcbody

	funcbody ::= '(' [parlist] ')' block 'end'

	parlist ::= namelist [',' '...'] | '...'

	tableconstructor ::= '{' [fieldlist] '}'

	fieldlist ::= field {fieldsep field} [fieldsep]

	field ::= '[' exp ']' '=' exp | Name '=' exp | exp

	fieldsep ::= ',' | ';'

	binop ::=  '+' | '-' | '*' | '/' | '//' | '^' | '%' | 
		 '&' | '~' | '|' | '>>' | '<<' | '..' | 
		 '<' | '<=' | '>' | '>=' | '==' | '~=' | 
		 'and' | 'or'

	unop ::= '-' | 'not' | '#' | '~'
--]]

---------- lua lexer ---------------------------------------------------

local function mkset(t)
	local r = {}
	for _, v in ipairs(t) do r[v] = true end
	return r
end

local keywords = mkset { 'break', 'goto', 'do', 'end', 'while', 'repeat',
	'until', 'if', 'then', 'elseif', 'else', 'for', 'function', 'local',
	'return' }

local binop = mkset { '+', '-', '*', '/', '//', '^', '%', '&', '~', '|',
		'>>', '<<', '..', '<', '<=', '>', '>=', '==', '~=', 'and', 'or' }

local unop = mkset { '-', 'not', '#', '~' }

local val = mkset { 'nil', 'true', 'false' } -- , number, string

local other = mkset { '=', ':', ';', ',', '.', '[', ']', '(', ')', '{', '}',
		'...', '::' }

local find = string.find

local function lex_space(str, pos)
	local s, e = find(str, "^%s+", pos)
	if not s then return nil end
	return "spc", pos, e
end

local function lex_longstr(str, pos)
	local s, e = find(str, "^%[=*%[", pos)
	if not s then return nil end
	local ce = "]" .. string.rep('=', e-s-1) .. "]"
	s, e = find(str, ce, e+1, true)
	if not s then return nil, "unfinished string" end
	return "str", pos, e
end

function lex_shortstr(str, pos)
	local s, e = find(str, '^["\']', pos)
	if not s then return nil end
	local ch = string.sub(str, s, e)
	local srch = '[\\\\'..ch..']'
	repeat
		s, e = find(str, srch, e+1)
		if s then
			ch = string.sub(str, s, e)
			if ch == '\\' then e = e + 1 end
		end
	until not s or ch ~= '\\'
	if not s then return nil, "unfinished string" end
	return "str", pos, e
end


local function lex_name(str, pos)
	local s, e = find(str, "^[%a_][%w_]*", pos)
	if not s then return nil end
	local t = "name"
	local ss = string.sub(str, s, e)
	if keywords[ss] then
		t = "key"
	elseif unop[ss] or binop[ss] then
		t = "op"
	elseif val[ss] then
		t = "val"
	end
	return t, pos, e
end

local function lex_number(str, pos)
	local t = num
	local p = pos
	local s, e = find(str, "^%-?0[xX]", p)
	if s then
		p = e + 1
		s, e = find(str, "^%x+", p)
		if e then p = e + 1 end
		s, e = find(str, "^%.%x" .. (s and '*' or '+'), p)
		if e then p = e + 1 end
		s, e = find(str, "^[pP][+-]?%d+", p)
		if not e then e = p - 1 end
		if e == pos+1 then return nil, "malformed number" end
	else
		s, e = find(str, "^%-?%d+", p)
		if e then p = e + 1 end
		s, e = find(str, "^%.%d" .. (s and '*' or '+'), p)
		if e then p = e + 1 end
		s, e = find(str, "^[eE][+-]?%d+", p)
		if not e then e = p - 1 end
		if e < pos then return nil, "malformed number" end
	end
	return "num", pos, e
end

local function lex_comment(str, pos)
	local s, e = find(str, "^%-%-", pos)
	local t
	if not s then return nil end
	t, s, e = lex_longstr(str, pos+2)
	if not s then
		s, e = find(str, "^--[^\n]*\n", pos)
		e = e - 1
	elseif not t then
		return nil, "unfinished comment"
	end
	return "com", pos, e
end

local function lex_op(str, pos)
	local s, e = find(str, "^[/<>=~.]+", pos)
	if not s then s, e = find(str, "^[+%%-*^%&~|#]", pos) end
	if not s then return nil end
	local op = string.sub(str, s, e)
	if binop[op] or unop[op] then
		return "op", s, e
	end
	return nil
end

local function lex_other(str, pos)
	local s, e = find(str, "^[=:.]+", pos)
	if not s then s, e = find(str, "^[;,%[%](){}]", pos) end
	if not s then return nil end
	local op = string.sub(str, s, e)
	if other[op] then
		return "other", s, e
	end
	return nil
end

local function lualexer(str, skipws)
	local cr = coroutine.create(function()
		local pos = 1
		local line, col = 1, 1
		local ch, t, s, e, l, c

		-- skip initial #! if present
		s, e = string.find(str, "^#![^\n]*\n")
		if s then
			line = 2
			pos = e + 1
		end

		while pos <= #str do
			ch = string.sub(str, pos, pos)
			if ch == '-' then
				t, s, e = lex_comment(str, pos)
				if not t then
					t, s, e = lex_number(str, pos)
				end
				if not t then
					t, s, e = lex_op(str, pos)
				end
			elseif ch == "[" then
				t, s, e = lex_longstr(str, pos)
				if not t then
					t, s, e = lex_other(str, pos)
				end
			elseif ch == "'" or ch == '"' then
				t, s, e = lex_shortstr(str, pos)
			elseif find(ch, "[%a_]") then
				t, s, e = lex_name(str, pos)
			elseif find(ch, "%d") then
				t, s, e = lex_number(str, pos)
			elseif find(ch, "%p") then
				t, s, e = lex_number(str, pos)
				if not t then
					t, s, e = lex_op(str, pos)
				end
				if not t then
					t, s, e = lex_other(str, pos)
				end
			else
				t, s, e = lex_space(str, pos)
			end

			l, c = line, col
			if t then
				local s1 = string.find(str, "\n", s)
				while s1 and s1 <= e do
					col = 1
					line = line + 1
					s = s1 + 1
					s1 = string.find(str, "\n", s)
				end
				col = col + (s > e and 0 or e - s + 1)
			else
				col = col + 1
			end

			if t and (not skipws or t ~= "spc") then
				coroutine.yield(t, pos, e, l, c)
			elseif not t then
				s = s or "invalid token"
				coroutine.yield('err', s .. " in line " .. l .. " char " .. c)
				e = pos
			end
			pos = e + 1
		end
		return nil
	end)
	
	return function()
		local ok, t, s, e, l, c = coroutine.resume(cr)
		if ok then
			return t, s, e, l, c
		end
		return nil, t
	end
end

---------- end of lua lexer --------------------------------------------

local function expand_tabs(txt, tw)
	tw = tw or 4
	local tbl = {}
	local pos = 1
	local w = 0
	local s, e = string.find(txt, "^[^\t]*\t", 1)
	while s do
		tbl[#tbl+1] = string.sub(txt, s, e-1)
		w = w + e - s
		tbl[#tbl+1] = string.rep(' ', tw - w % tw)
		w = w + tw - w % tw
		pos = e + 1
		s, e = string.find(txt, "^[^\t]*\t", e + 1)
	end
	tbl[#tbl+1] = string.sub(txt, pos)
	return table.concat(tbl)
end

-- this should somehow also catch lines with only a [local] function(...)
local function breakable(t, src, s, e)
	if t == "com" or t == "spc" then
		return false
	elseif t == 'key' then
		local what = string.sub(src, s, e)
		if what == 'end' then
			return false
		end
	elseif t == 'other' then
		local what = string.sub(src, s, e)
		if what == ')' or what == '}' or what == ']' then
			return false
		end
	end
	return true
end

-- very simple for the time being: we consider every line that has a
-- token other than com or spc or the keyword 'end' breakable.
local function lualoader(file)
	local srct = {}
	local canbrk = {}
	
	if file then
		local f = io.open(file, "r")
		if not f then 
			return nil, "could not load source file "..file
		end
		local src = f:read("*a")
		f:close()
		
		local tokens = lualexer(src)
		for t, s, e, l, c in tokens do
			if t == "err" then
				return nil, "Error: "..s
			elseif breakable(t, src, s, e) then
				canbrk[l] = true
			end
		end

		if string.sub(src, #src, 1) ~= "\n" then
			src = src .. "\n"
		end
		string.gsub(src, "([^\r\n]*)\r?\n", function(s) table.insert(srct, s) end)
		for i = 1, #srct do
			srct[i] = expand_tabs(srct[i])
		end
	end
	
	return { src = srct, lines = #srct, canbrk = canbrk, breakpts = {}, selected = 0 }
end

--[[ DEBUG
	local file = io.stdin
	if arg[1] then
		file = io.open(arg[1], "r")
		if not file then print("could not open file " .. file) os.exit(1) end
	end

	local line
	repeat
		io.stdout:write("> ")
		line = file:read()
		local tokens = lualexer(line)
		for t, s, e, l, c in tokens do
			print(t, s, e, l, c)
		end
	until not line or line == "" 
-- DEBUG ]]

return {
	lualoader = lualoader,
	lualexer = lualexer
}


end
end

end


--[[
	debug.lua
	
	standalone frontend for mobdebug
	Gunnar Zötl <gz@tset.de>, 2014
	Released under MIT/X11 license. See file LICENSE for details.
--]]

local config_file = "debug.lua.cfg"
local user_config = os.getenv("HOME") .. "/.config/" .. config_file

---------- configure your colors here ----------------------------------

local default_fg = "WHITE"
local default_bg = "BLACK"

local configuration = {
	-- default
	fg = "WHITE",
	bg = "BLACK",

	-- variable display
	var_fg = "WHITE",
	var_bg = "BLUE",

	-- misc foregrounds: breakpoint mark, current line mark, and message
	-- after client terminated
	mark_bpt_fg = "RED",
	mark_cur_fg = "CYAN",
	done_fg = "RED",
	
	-- windows (help, dialogs)
	widget_fg = "WHITE",
	widget_bg = "BLUE",

	-- selection
	sel_fg = "BLACK",
	sel_bg = "CYAN",

	-- ui elements (buttons etc). selected elements will use sel_*
	elem_fg = "BLUE",
	elem_bg = "WHITE",
}

---------- end configure section ---------------------------------------

-- these are necessary because the mobdebug module recklessly calls
-- print and os.exit(!)
local _G_print = _G.print
_G.print = function() end
local _os_exit = os.exit
os.exit = function() coroutine.yield(_os_exit) end
local mdb = require "mobdebug"
local socket = require "socket"

local port = tonumber((os.getenv("MOBDEBUG_PORT"))) or 8172 -- default

local client
local basedir, basefile

local sources = {}
local current_src = {}
local current_file = ""
local current_line = 0
local selected_line
local select_cmd
local last_search
local last_match = 0
local cmd_output = {}
local cmd_outlog
local pinned_evals = {}
local display_pinned = true

-- compat
local log10 = math.log10 or function(n) return math.log(n, 10) end
local unpack = unpack or table.unpack

---------- modules -----------------------------------------------------

local loader = require "loader"
local ui = require "ui"

---------- initialization ----------------------------------------------

local function init()
	sources = {}
	current_src = {}
	current_file = ""
	current_line = 0
	selected_line = nil
	select_cmd = nil
	last_search = nil
	last_match = 0
	cmd_output = {}
	pinned_evals = {}
	display_pinned = true
end

---------- misc helpers ------------------------------------------------

local function file_exists(name)
	local file, err = io.open(name, "r")
	if file then
		file:close()
	end
	return file ~= nil
end

local function output(...)
	local line = table.concat({...}, " ")
	cmd_output[#cmd_output+1] = line
	if cmd_outlog then
		cmd_outlog:write(line, "\n")
	end
end

local function output_error(...)
	output("Error:", ...)
end

local function output_debug(...)
	output("DBG:", ...)
end

-- opts: string of single char options, char followed by ':' means opt
-- needs a value
-- arg: table of arguments
local function get_opts(opts, arg)
	local i = 1
	local opt, val
	local optt = {}
	local res = {}
	
	while i <= #opts do
		local ch = string.sub(opts, i, i)
		if string.sub(opts, i+1, i+1) == ':' then
			optt[ch] = true
			i = i + 2
		else
			optt[ch] = false
			i = i + 1
		end
	end
	
	i = 1
	while arg[i] do
		if string.sub(arg[i], 1, 1) == '-' then
			opt = string.sub(arg[i], 2, 2)
			if optt[opt] then
				if #arg[i] > 2 then
					val = string.sub(arg[i], 3)
					i = i + 1
				else
					val = arg[i+1]
					i = i + 2
				end
				if val == nil then
					return nil, "option -"..opt.." needs an argument"
				end
			elseif optt[opt] == false then
				if #arg[i] == 2 then
					val = true
					i = i + 1
				else
					return nil, "option -"..opt.." is a flag"
				end
			else
				return nil, "unknown option -"..opt
			end
			res[opt] = val
		else
			res[#res+1] = arg[i]
			i = i + 1
		end
	end
	
	return res
end

local function get_file(file)
	if not sources[file] then
		local fn = file
		if string.sub(file, 1, 1) ~= '/' then
			fn = basedir .. '/' .. file
		end
	
		local src, err = loader.lualoader(fn)
		if not src then
			return nil, err
		end
		sources[file] = src
	end
	return sources[file]
end

local function set_current_file(file)
	local src, err = get_file(file)
	if not src then
		output_error(err)
		src = loader.lualoader()
	end
	current_file = file
	current_src = src
end

---------- configuration -----------------------------------------------

local config = setmetatable({}, {
	__index = function(_, col)
		if string.find(col, "fg$") then
			return ui.color[default_fg]
		else
			return ui.color[default_bg]
		end
	end
})

local function decode_color(c)
	local col = ui.color[c or ""]
	if col then
		return col
	end
	local r, g, b = string.match(c, "^#([0-5])([0-5])([0-5])$")
	if r and g and b then
		col = ui.rgb2color(tonumber(r), tonumber(g), tonumber(b))
		return col
	end
	return nil
end

local function loadconfig(name)
	local res = {}
	local fn, err = loadfile(name, "t", res)
	print(fn, err)
	local ok
	if fn then
		ok,  err = pcall(fn)
		if ok then
			for k, v in pairs(res) do
				if not configuration[k] then
					return nil, "Failed to load config file '" .. name .. "': " .. "invalid option '" .. k .. "'"
				elseif not decode_color(v) then
					return nil, "Failed to load config file '" .. name .. "': " .. "invalid value for option '" .. k .. "'"
				end
			end
			return res
		end
	end
	return nil, "Failed to load config file " .. err
end

local function readconfig()
	local ucfg, lcfg, err
	if file_exists(user_config) then
		ucfg, err = loadconfig(user_config)
		if err then return nil, err end
	end
	if file_exists(config_file) then
		lcfg, err = loadconfig(config_file)
		if err then return nil, err end
	end
	for k, v in pairs(configuration) do
		if ucfg and ucfg[k] then
			configuration[k] = ucfg[k]
		end
		if lcfg and lcfg[k] then
			configuration[k] = lcfg[k]
		end
	end
	return true
end

local function configure()
	local ok, err = readconfig()
	if not ok then
		return ok, err
	end
	for k, v in pairs(configuration) do
		config[k], err = decode_color(v)
		pcall(ui.configure, { k = v })
	end
	return true
end

---------- render display ----------------------------------------------

-- source display

local function displaysource_renderrow(r, s, x, y, w, extra)
	if s == nil then return end

	local isbrk = extra.isbrk
	local linew = extra.linew

	local rs = string.format("%"..extra.linew.."d", r)
	ui.drawfield(x, y, rs, linew)

	if isbrk[r] then
		ui.setcell(x + linew, y, '*', config.mark_bpt_fg, config.bg)
	end
	if extra.cur == r then
		ui.setcell(x + linew + 1, y, '-', config.mark_cur_fg, config.bg)
		ui.setcell(x + linew + 2, y, '>', config.mark_cur_fg, config.bg)
	end

	local fg, bg = ui.attributes()
	
	if extra.sel == r then
		ui.attributes(config.sel_fg, config.sel_bg)
	end

	return ui.drawfield(x + linew + 3, y, tostring(s), w - linew - 3)
end

local function displaysource(source, x, y, w, h)
	local extra = {
		isbrk = source.breakpts,
		cur = current_line,
		sel = selected_line,
		linew = math.floor(log10(source.lines)) + 1
	}
	local first = (selected_line and selected_line or current_line) - math.floor(h/2)

	if first < 1 then
		first = 1
	elseif first + h > #source.src then
		first = #source.src - h + 2
	end
	ui.drawlist(source.src, first, x, y, w, h, displaysource_renderrow, extra)
end

-- pinned variables display

local function displaypinned_renderrow(r, s, x, y, w, extra)
	local w1 = extra.w1
	local w2 = w - w1
	if s then
		ui.drawfield(x, y, string.format("%2d:", r), 3)
		ui.drawfield(x + 3, y, s[1], w1)
		ui.setcell(x + 3 + w1, y, '=')
		ui.drawfield(x + 3 + w1 + 1, y, s[2], w2)
		if cmd_outlog then
			cmd_outlog:write(r, ":\t", s[1], " = ", tostring(s[2]), "\n")
		end
	end
end

-- we could just feed the reply from the debuggee into loadstring, but
-- then we would lose the already serialized data, so we parse it into a
-- flat table here.

local function displaypinned_readres_table(res, next_token, start)
	local lv = 1
	local t, s, e
	repeat
		t, s, e = next_token()
		local tv = string.sub(res, s, e)
		if tv == '{' then
			lv = lv + 1
		elseif tv == '}' then
			lv = lv - 1
		end
	until lv == 0
	return start, e
end

local function displaypinned_readres_skips(next_token)
	local t, s, e, tv
	repeat
		t, s, e = next_token()
	until t ~= 'spc' and t ~= 'com'
	return t, s, e
end

local function displaypinned_readres(res)
	local next_token = loader.lualexer(res)
	if not next_token then return nil end

	local rest = {}
	local nidx = 1
	local t, s, e = next_token()
	local tv = string.sub(res, s, e)
	if tv ~= '{' then return nil end
	
	repeat
		t, s, e = displaypinned_readres_skips(next_token)
		tv = string.sub(res, s, e)

		if tv == '{' then
			s, e = displaypinned_readres_table(res, next_token, s)
			rest[nidx] = string.sub(res, s, e)
			t, s, e = displaypinned_readres_skips(next_token)
			tv = string.sub(res, s, e)
			if tv ~= ',' and tv ~= '}' then output_error("unexpected token '"..tv.."'") end
			nidx = nidx + 1
		elseif tv == '[' then
			t, s, e = next_token()
			tv = string.sub(res, s, e)
			if t ~= 'num' then
				output_error("unexpected token '"..tv.."'")
				return {}
			end
			nidx = tonumber(tv)
			t, s, e = displaypinned_readres_skips(next_token)
			tv = string.sub(res, s, e)
			if tv ~= ']' then
				output_error("unexpected token '"..tv.."'")
				return {}
			end
			t, s, e = displaypinned_readres_skips(next_token)
			tv = string.sub(res, s, e)
			if tv ~= '=' then
				output_error("unexpected token '"..tv.."'")
			end
		elseif tv ~= '}' then
			local mys = s
			repeat
				t, s, e = next_token()
				if e then tv = string.sub(res, s, e) end
			until tv == ',' or tv == '}'
			rest[nidx] = string.sub(res, mys, e-1)
			nidx = nidx + 1
		end
	
	until tv == '}'
	return rest
end

local function displaypinned(pinned, x, y, w, h)
	local extra = {}
	local w1, dw1 = 1, math.floor((w - 3) / 2) - 1
	if h > 99 then h = 99 end
	while #pinned > h do
		table.remove(pinned, 1)
	end
	-- this is not strictly hygienic. should find a better solution for it.
	local cmd = "do local __________t, __________k, __________e = {};"
	for i=1, #pinned do
		cmd = cmd .. "__________k, __________e = pcall(function() __________t[" .. i .. "]="..pinned[i][1].." end);"
	end
	cmd = cmd .. "return __________t;end"
	local res, _, err = mdb.handle("exec "..cmd, client)
	local rt = {}
	if res then
		--rt = loadstring("return "..res)()
		rt = displaypinned_readres(res)
	end
	for i=1, #pinned do
		if #pinned[i][1] > w1 then w1 = #pinned[i][1] end
		pinned[i][2] = rt[i]
	end
	extra.w1 = (w1 < dw1) and w1 or dw1
	ui.rect(x, y, w, h)
	ui.drawlist(pinned, 1, x, y, w, h, displaypinned_renderrow, extra)
end

-- commands display

local function displaycommands(cmds, x, y, w, h)
	local nco = #cmds
	local first = h > nco and 1 or nco - h + 1
	local y = y + (nco >= h and 1 or h - nco + 1)
	ui.drawtext(cmds, first, 1, y, w, h)
end

local function display()
	local w, h = ui.size()
	local th = h - 1
	local srch = math.floor(th / 3 * 2)
	local cmdh = th - srch
	local srcw = math.floor(w * 3 / 4)
	local pinw = w - srcw
	srch = srch - 1

	if (#pinned_evals == 0) or not display_pinned then
		srcw = w
		pinw = 0
	end
	
	ui.clear(config.fg, config.bg)
	ui.drawstatus({"Skript: "..(basefile or ""), "Dir: "..(basedir or ""), "press h for help"}, 1, ' | ')

	-- variables view
	if pinw > 0 then
		ui.attributes(config.var_fg, config.var_bg)
		displaypinned(pinned_evals, srcw + 1, 2, pinw, srch-1)
	end

	-- source view
	if select_cmd then
		selected_line = selected_line or current_line
		if select_cmd == ui.key.ARROW_UP then
			selected_line = selected_line - 1
		elseif select_cmd == ui.key.ARROW_DOWN then
			selected_line = selected_line + 1
		elseif select_cmd == ui.key.PGUP then
			selected_line = selected_line - srch
		elseif select_cmd == ui.key.PGDN then
			selected_line = selected_line + srch
		elseif select_cmd == ui.key.HOME then
			selected_line = 1
		elseif select_cmd == ui.key.END then
			selected_line = current_src.lines
		end
		select_cmd = nil
	end

	if selected_line then
		if selected_line < 1 then
			selected_line = 1
		elseif selected_line > current_src.lines then
			selected_line = current_src.lines
		end
	end
		
	ui.attributes(config.fg, config.bg)
	displaysource(current_src, 1, 2, srcw, srch-1)
	ui.drawstatus({"File: "..current_file, "Line: "..current_line.."/"..current_src.lines, #pinned_evals > 0 and "pinned: " .. #pinned_evals or ""}, srch + 1)
	
	-- commands view
	ui.attributes(config.fg, config.bg)
	displaycommands(cmd_output, 1, srch + 1, w, cmdh)
	
	-- input line
	ui.printat(1, h, string.rep(' ', w))
	ui.setcursor(1,h)
	
	-- more

	ui.present()
end

---------- starting up the debugger ------------------------------------

local function unquote(s)
	s = string.gsub(s, "^%s*(%S.+%S)%s*$", "%1")
	local ch = string.sub(s, 1, 1)
	if ch == "'" or ch == '"' then
		s = string.gsub(s, "^" .. ch .. "(.*)" .. ch .. "$", "%1")
	end
	return s
end

local function find_current_basedir()
	local res, line, err = mdb.handle("eval os.getenv('PWD')", client)
	if not res then
		output_error(err)
		return
	end
	local pwd = unquote(res)

	res, line, err = mdb.handle("eval arg[0]", client)
	if not res then
		output_error(err)
		return
	end
	local arg0 = unquote(res)

	if pwd and arg0 then
		basedir = basedir or pwd
		basefile = string.match(arg0, "/([^/]+)$") or arg0
	end
end

local function startup()
	init()

	ui.attributes(config.widget_fg, config.widget_bg)

	local msg = "Waiting for connections on port "..port
	local x, y, w, h = ui.frame(#msg, 5, "debug.lua")
	ui.printat(x, y+1, msg, w)
	ui.present()
	
	local bw, bp, bo = math.floor(#msg/2), 1, 1
	local bx = x + math.floor((w - bw) / 2)
	
	local server = socket.bind('*', port)
	if not server then
		return nil, "could not open server socket."
	end
	server:settimeout(0.3)
	
	local evt
	repeat
		ui.printat(bx, y+3, string.rep(' ', bw), bw)
		ui.setcell(bx + bp - 1, y+3, '=')
		if bp > 1 then ui.setcell(bx + bp - 2, y+3, '-') end
		if bp < bw then ui.setcell(bx + bp, y+3, '-') end
		bp = bp + bo
		if bp >= bw or bp <= 1 then bo = -bo end
		ui.present()
		client = server:accept()
		evt = ui.pollevent(0)
		if evt and (evt.key == ui.key.ESC or evt.char == 'q' or evt.char == 'Q') then
			server:close()
			return false
		end
	until client ~= nil
	server:close()

	find_current_basedir()
	return true
end

---------- debugger commands -------------------------------------------

local dbg_args = {}

local function dbg_help()
	local t = {
		"n             | step over next statement",
		"s             | step into next statement",
		"r             | run program",
		"o             | continue until out of current function",
		"t [num]       | trace execution",
		"b [file] line | set breakpoint",
		"c [f] ln cond | set conditional breakpoint",
		"db [[file] ln]| delete one or all breakpoints",
		"= expr        | evaluate expression",
		"! expr        | pin expression",
		"d! [num]      | delete one or all pinned expressions",
		"B dir         | set basedir",
		"L dir         | set only local basedir",
		"P             | toggle pinned expressions display",
		"G [file] [num]| goto line in file or current file or to file",
		"/ [str]       | search for str in current file, or continue last search",
		"W[b|!] file   | write setup.",
		"h             | help",
		"q             | quit",
		"[page] up/down| navigate source file",
		"left/right    | select current line",
		".             | reset view",
		"D             | stop debugging and continue execution",
	}
	ui.text(t, "Commands")
end

-- we're only interested in the source positions part
local function dbg_stack()
	local res, line, err = mdb.handle("stack", client)
	if res then
		local r = {}
		for k, v in ipairs(res) do
			r[k] = v[1]
		end
		res = r
	end
	return res, err
end

local function update_where()
		local s = dbg_stack()
		current_line = s[1][4]
		set_current_file(s[1][2])
		output(current_file, ":", current_line)
		selected_line = nil
end

local function check_break_cond()
	if current_src.breakpts[current_line] then
		if type((current_src.breakpts[current_line])) == "string" then
			local res, line, err = mdb.handle("eval " .. current_src.breakpts[current_line], client)
			if err ~= nil then
				output_error("in breakpoint condition:", err)
				res = true
			else
				local lres = string.lower(res)
				if lres == "false" or lres == "nil" then
					res = false
				else
					res = true
				end
				if res then
					output("Cond:", current_src.breakpts[current_line], " is true")
				end
			end
			return res
		else
			return true
		end
	end
	return false
end

local function dbg_over()
	local res, line, err = mdb.handle("over", client)
	update_where()
	return nil, err
end

local function dbg_step()
	local res, line, err = mdb.handle("step", client)
	update_where()
	return nil, err
end

local function dbg_run()
	local res, line, err
	repeat
		res, line, err = mdb.handle("run", client)
		update_where()
	until check_break_cond()
	return nil, err
end

local function dbg_out()
	local res, line, err = mdb.handle("out", client)
	update_where()
	return nil, err
end

local function dbg_done()
	local res, line, err = mdb.handle("done", client)
	update_where()
	return nil, err
end

local function dbg_trace(num)
	if num and num < 1 then return nil end
	local res, err
	local steps = 1
	while not num or steps <= num do
		res, err = dbg_step()
		display()
		if check_break_cond() then return end
		steps = steps + 1
	end
	return res, err
end
dbg_args[dbg_trace] = 'N'

local function dbg_eval(...)
	local expr = table.concat({...}, ' ')
	local res, line, err = mdb.handle("eval " .. expr, client)
	if not err then res = tostring(res) end
	return res, err
end
dbg_args[dbg_eval] = '*'

local function dbg_pin_eval(...)
	local expr = table.concat({...}, ' ')
	table.insert(pinned_evals, { expr, nil })
	return "added pinned expression '"..expr.."'"
end
dbg_args[dbg_pin_eval] = '*'

local function dbg_delpin(_, pin)
	if _ then
		return nil, "invalid argument #1: number expected"
	end
	if pin then
		if pin >= 1 and pin <= #pinned_evals then
			table.remove(pinned_evals, pin)
			return "deleted pinned expression #" .. tostring(pin)
		else
			return nil, "invalid pin number"
		end
	else
		pinned_evals = {}
		return "deleted all pinned expressions"
	end
end

local function dbg_setb(file, line)
	local res, _, err
	if file then
		res, err = get_file(file)
		if not res then
			return nil, err
		end
	else
		file = current_file
	end
	if not get_file(file).canbrk[line] then
		return nil, "can't set breakpoint in file '"..file.."' line "..line
	end
	if file and line then
		res, _, err = mdb.handle("setb " .. file .. " " .. line, client)
		if not err then
			res = "added breakpoint at " .. res .. " line " .. line
			get_file(file).breakpts[tonumber(line)] = true
		else
			res = nil
		end
	else
		err = "command requires file (optional) and line number as arguments"
	end
	return res, err
end
dbg_args[dbg_setb] = "Sn"

local function dbg_setbcond(file, line, ...)
	local res, _, err
	local cond = table.concat({...}, ' ')
	if file then
		res, err = get_file(file)
		if not res then
			return nil, err
		end
	else
		file = current_file
	end
	if not get_file(file).canbrk[line] then
		return nil, "can't set conditional breakpoint in file '"..file.."' line "..line
	end
	if file and line then
		res, _, err = mdb.handle("setb " .. file .. " " .. line, client)
		if not err then
			res = "added conditional breakpoint at " .. res .. " line " .. line
			get_file(file).breakpts[tonumber(line)] = cond
		else
			res = nil
		end
	else
		err = "command requires file (optional) and line number as arguments"
	end
	return res, err
end
dbg_args[dbg_setbcond] = "Sn*"

local function dbg_delb(file, line)
	local res, _, err
	if file then
		res, err = get_file(file)
		if not res then
			return nil, err
		end
	else
		file = current_file
	end
	if line then
		res, _, err = mdb.handle("delb " .. file .. " " .. line, client)
		if not err then
			res = "deleted breakpoint at " .. res .. " line " .. line
			get_file(file).breakpts[tonumber(line)] = nil
		else
			res = nil
		end
	else
		res, _, err = mdb.handle("delallb", client)
		if not err then
			for _, s in pairs(sources) do
				s.breakpts = {}
			end
			res = "deleted all breakpoints"
		else
			res = nil
		end
	end
	return res, err
end

local function dbg_del(ch, file, line)
	if ch == "b" then
		return dbg_delb(file, line)
	elseif ch == "!" then
		return dbg_delpin(file, line)
	end
	return nil, "unknown del function: "..ch
end
dbg_args[dbg_del] = "cSN"

local function dbg_local_basedir(dir)
	basedir = dir
	return "local basedir is now "..basedir
end
dbg_args[dbg_local_basedir] = "s"

local function dbg_basedir(dir)
	local res, err, _ = dbg_local_basedir(dir)
	if not err then
		res, _, err = mdb.handle("basedir " .. basedir, client)
		if not err then
			res = "basedir is now " .. basedir
		end
	end
	return res, err
end
dbg_args[dbg_basedir] = "s"

local function dbg_gotoline(file, line)
	if not file and not line then
		return nil, "file or line number or both expected"
	end
	if file then
		local src, err = get_file(file)
		if not src then return nil, err end
		current_file = file
		current_src = src
		if not line then line = 1 end
	end
	if line < 1 or line > #current_src.src then
		return nil, "line number out of range"
	end
	selected_line = line
end
dbg_args[dbg_gotoline] = "SN"

local function dbg_searchstr(str)
	local src = current_src.src
	local first = 1

	if not str and last_search then
		str = last_search
		first = last_match + 1
	elseif not str and not last_search then
		return
	end

	if str then
		last_search = str
		for line=first, #src do
			if string.find(src[line], str, 1, true) then
				selected_line = line
				last_match = line
				return "searching for " .. str
			end
		end
	end
	last_match = 0
	return "no match, next / wraps"
end
dbg_args[dbg_searchstr] = "S"

local function dbg_toggle_pinned()
	display_pinned = not display_pinned
	return (display_pinned and "" or "don't ") .. "display pinned evals"
end

local function dbg_writesetup(what, file)
	local breaks, pins = true, true
	local res = {}
	if what == 'b' then
		pins = false
	elseif what == '!' then
		breaks = false
	end
	if breaks then
		for n, s in pairs(sources) do
			for i, c in pairs(s.breakpts) do
				if c == true then
					res[#res+1] = string.format('b %q %d', n, i)
				else
					res[#res+1] = string.format('c %q %d %s', n, i, c)
				end
			end
		end
	end
	if pins then
		for _, pin in ipairs(pinned_evals) do
			res[#res+1] = string.format("! %s", pin[1])
		end
	end
	
	if file then
		local f = io.open(file, "w")
		if not f then
			return nil, "could not open file '"..file.."' for writing"
		end
		for _, l in ipairs(res) do
			f:write(l, "\n")
		end
		f:close()
		return "wrote setup to file '"..file.."'"
	else
		for _, l in ipairs(res) do
			output(l)
		end
	end
end
dbg_args[dbg_writesetup] = "CS"

local function dbg_return()
	update_where()
end

local dbg_imm = {
	['h'] = dbg_help,
	['s'] = dbg_step,
	['n'] = dbg_over,
	['r'] = dbg_run,
	['o'] = dbg_out,
	['P'] = dbg_toggle_pinned,
	['D'] = dbg_done,
	['.'] = dbg_return,
}

local dbg_cmdl = {
	['t'] = dbg_trace,
	['b'] = dbg_setb,
	['c'] = dbg_setbcond,
	['d'] = dbg_del,
	['='] = dbg_eval,
	['!'] = dbg_pin_eval,
	['B'] = dbg_basedir,
	['L'] = dbg_local_basedir,
	['G'] = dbg_gotoline,
	['/'] = dbg_searchstr,
	['W'] = dbg_writesetup,
}

local use_selection = {
	['b'] = function() return "b " .. tostring(selected_line) end,
	['c'] = function() return "c " .. tostring(selected_line) .. " " end,
	['d'] = function() if current_src.breakpts[selected_line] then return "db " .. tostring(selected_line) else return "d" end end,
}

local use_current = {
	['d'] = function() if current_src.breakpts[current_line] then return "db " .. tostring(current_line) else return "d" end end,
}

-- argspec:
-- nil	any argument list
-- *	any argument list with at least one argument. May also be the
--		last char in a spec when 1 or more args should follow.
-- c,C	char or optional char
-- n,N	number or optional number
-- s,S	string or optional string. A string may either be enclosed by
--		quotes (' or "), or a word with no space characters in it.
local function dbg_verify_args(argspec, args)
	local function invarg(n, t)
		return nil, "invalid argument #"..n..": " ..t.." expected"
	end

	if not argspec or (argspec == '*' and #args > 0) then
		return args
	end
	local varg = {}
	local nargs = 0
	local k = 1
	for i=1, #argspec do
		local v = args[k]
		local t = type(v)
		local spec = string.sub(argspec, i, i)
		local lspec = string.lower(spec)
		if lspec == 'n' then
			if t == "number" then
				varg[i] = v
				k = k + 1
			elseif spec == 'N' then
				varg[i] = nil
			else
				return invarg(k, "number")
			end
			nargs = nargs + 1
		elseif lspec == 'c' then
			if t == "string" and #v == 1 then
				varg[i] = v
				k = k + 1
			elseif spec == 'C' then
				varg[i] = nil
			else
				return invarg(k, "char")
			end
			nargs = nargs + 1
		elseif lspec == 's' then
			if t == "string" then
				varg[i] = v
				k = k + 1
			elseif spec == 'S' then
				varg[i] = nil
			else
				return invarg(k, "string")
			end
			nargs = nargs + 1
		elseif spec == '*' then
			if i ~= #argspec then
				return nil, "(invalid argspec for function: '"..tostring(argspec).."')"
			end
			for l = k, #args do
				varg[i - k + l] = args[l]
				nargs = nargs + 1
			end
		else
			return nil, "(invalid argspec for function: '"..tostring(argspec).."')"
		end
	end
	return varg, nargs
end

local function dbg_exec(cmdl)
	local cmd = string.sub(cmdl, 1, 1)
	if cmd == '' then return nil end
	local args = {}
	local s, e = string.find(cmdl, "^%s*(%S)", 2)
	local quote = false
	while s do
		local ch = string.sub(cmdl, e, e)
		if ch == "`" then
			quote = true
		elseif ch == '"' or ch == "'" then
			local p1 = e + 1
			s, e = string.find(cmdl, "[^\\]"..ch, p1)
			if s then
				args[#args+1] = quote and string.sub(cmdl, p1-1, e) or string.sub(cmdl, p1, e-1)
				quote = false
			else
				return nil, "unfinished string argument"
			end
		else
			s, e = string.find(cmdl, "%S+", s)
			local a = string.sub(cmdl, s, e)
			local n = tonumber(a)
			if n then
				args[#args+1] = n
			else
				args[#args+1] = a
			end
		end
		s, e = string.find(cmdl, "^%s"..(quote and '*' or '+').."(%S)", e+1)
	end
	if dbg_imm[cmd] then
		if #args == 0 then
			return dbg_imm[cmd]()
		else
			return nil, "too many arguments for command "..cmd
		end
	elseif dbg_cmdl[cmd] then
		local fn = dbg_cmdl[cmd]
		local argspec = dbg_args[fn]
		local vargs, n = dbg_verify_args(argspec, args)
		if vargs then
			return fn(unpack(vargs, 1, n))
		else
			return nil, n
		end
	end
	
	return nil, "unknown command "..cmd
end

local function dbg_execfile(file)
	local f = io.open(file, "r")
	if not f then
		return nil, "could not open file '"..file.."' for input."
	end
	for l in f:lines() do
		local res, err = dbg_exec(l)
		if res then
			output(res)
		elseif err then
			f:close()
			return nil, err
		end
	end
	f:close()
	return "execution of commands in file '"..file.."' finished"
end

local function dbg_loop()
	local w, h, evt, cmdl
	local quit = false
	
	update_where()

	local evt
	repeat
		w, h = ui.size()
		display()
		evt = ui.pollevent()
		if evt and evt.char ~= "" then
			local ch = evt.char or ''
			cmdl = nil
			if dbg_imm[ch] then
				cmdl = ch
			elseif dbg_cmdl[ch] then
				local prefill = ch
				if selected_line and use_selection[ch] then
					prefill = use_selection[ch]()
				elseif use_current[ch] then
					prefill = use_current[ch]()
				end
				ui.setcell(1, h, ">")
				cmdl = ui.input(2, h, w, prefill)
				if cmdl == "" then cmdl = nil end
			end
			
			if cmdl then
				output(cmdl)
				result, err = dbg_exec(cmdl)
			elseif ch == "q" then
				selected_line = nil
				quit = ui.ask("Really quit?") == 1
			end
			
			if err then
				output_error(err)
			elseif result then
				local resa = ui.formatwidth(result, w - 4)
				output("->", resa[1])
				if #resa > 1 then
					for i = 2, #resa do
						output(" >", resa[i])
					end
				end
			end
					
			result, err = nil, nil
		else
			local key = evt.key
			if key == ui.key.ARROW_UP or key == ui.key.ARROW_DOWN or
			   key == ui.key.ARROW_LEFT or key == ui.key.ARROW_RIGHT or
			   key == ui.key.PGUP or key == ui.key.PGDN or
			   key == ui.key.HOME or key == ui.key.END then
				select_cmd = key
			end
		end
	until quit
	
	return quit
end

---------- main --------------------------------------------------------

local ok, val

if tonumber(mdb._VERSION) < 0.63 then
	ok = nil
	val = "debug.lua needs at least mobdebug version 0.63"
else
	ok, val = pcall(function()

		ui.outputmode(ui.output.COL256)
		local ok, err = configure()
		if not ok then
			error(err)
		end

		local w, h = ui.size()
		local quit = false

		local opts, err = get_opts("p:d:x:l:h?", arg)
		if not opts or opts.h or opts['?'] then
			local ret = err and err .. "\n" or ""
			return ret .. "usage: "..arg[0] .. " [-p port] [-d dir] [-x file] [-l file]"
		end
		if opts.p then
			port = tonumber(opts.p)
			if not port then error("argument to -p needs to be a port number") end
		end
		if opts.d then
			basedir = opts.d
		end
		if opts.l then
			cmd_outlog = io.open(opts.l, "w")
			if not cmd_outlog then error("can't write output log '"..opts.l.."'") end
		end

		while not quit do
			ui.clear(config.fg, config.bg)
			local ok, err = startup(port)
			if ok == nil then
				error(err)
			elseif ok == false then
				return
			end

			local result, err
			local first = 1
			local cmdl

			if opts.x then
				local res, err = dbg_execfile(opts.x)
				if res then
					output(res)
				else
					output_error(err)
				end
			end

			local loop = coroutine.create(dbg_loop)
			local ok, val = coroutine.resume(loop)

			if client then
				client:close()
				client = nil
			end
			
			if ok and val == _os_exit then
				local w, h = ui.size()
				ui.attributes(config.done_fg + ui.format.BOLD, config.bg)
				ui.drawfield(1, h, "Debugged program terminated, press q to quit or any key to restart.", w)
				ui.hidecursor()
				ui.present()
				quit = ui.waitkeypress() == 'q'
				output("Debugged program terminated" .. (quit and "" or ", restarting"))
			elseif ok and val == true then
				quit = true
			else
				output_error(val)
				output(debug.traceback(loop))
				return nil
			end
		end

		return
	end)
end

ui.shutdown()
if outlog then outlog:close() end
if client then client:close() end

if not ok then
	_G_print("Error: "..tostring(val))
elseif val then
	_G_print(val)
else
	_G_print("Bye.")
end

