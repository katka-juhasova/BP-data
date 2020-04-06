#!/usr/bin/env lua

--[[ expectex.lua
 -
 - a somewhat less simple example for lpty, using lua via quite simplistic
 - expect like functionality
 -
 - Gunnar Zötl <gz@tset.de>, 2010-2015
 - Released under MIT/X11 license. See file LICENSE for details.
--]]

local lpty = require "lpty"

p = lpty.new({raw_mode = true})

p:startproc("lua")

while p:hasproc() and not p:readok() do end
if not p:hasproc() then
	local what, code = p:exitstatus()
	error("start failed: child process terminated because of " .. tostring(what) .. " " ..tostring(code))
end

i = 0
while p:expect("> $") and i < 10 do
	p:send("=111+234+"..i.."\n")
	-- give it time to output the result!
	res = p:expect("^([0-9]+)$", false, 1)
	print("Got '"..tostring(res).."'")
	i = i + 1
end

p:send("os.exit()\n")
while p:hasproc() do end
if p:readok() then
	print(p:read())
end
