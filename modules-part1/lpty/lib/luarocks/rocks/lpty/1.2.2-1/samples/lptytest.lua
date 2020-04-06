#!/usr/bin/env lua

--[[ lptytest.lua
 -
 - test aspects of lpty
 -
 - Gunnar Zötl <gz@tset.de>, 2010-2015
 - Released under MIT/X11 license. See file LICENSE for details.
--]]

lpty = require "lpty"

p = lpty.new()

ntests = 0
nfailed = 0

-- announce which test we are performing and what it tests
function announce(str)
	str = str or ""
	ntests = ntests + 1
	print("Test " .. tostring(ntests) .. ": " .. str)
end

-- print that the test did not work out and optionally why
function fail(str)
	local msg = "  TEST FAILED"
	nfailed = nfailed + 1
	if str ~= nil then msg = msg .. ": " .. str end
	print(msg)
end

-- just prints wether the test went ok or not. An optional reason for failure may be passed,
-- which will then be printed.
function check(ok, msg)
	if ok==false then
		fail(msg)
		return false
	else
		print "  TEST OK"
		return true
	end
end

-- wait for a fraction of a second
function waitabit(n)
	n = n or 1
	t0 = os.clock()
	t1 = t0
	while t1 - t0 < 0.1 * n do
		t1 = os.clock()
	end
end

-- 1
announce("starting test client")
ok, val = pcall(lpty.startproc, p, "lua", "testclient.lua")
if ok then
	check(val)
else
	fail(tostring(val))
end

-- 2
announce("checking whether pty has process, should return true")
ok, val = pcall(lpty.hasproc, p)
if ok then
	check(val)
else
	fail(tostring(val))
end

-- 3
announce("checking whether we can read from the pty, should return false")
ok, val = pcall(lpty.readok, p)
if ok then
	check(val == false)
else
	fail(tostring(val))
end

-- 4
announce("reading from pty with a timeout of 0.1 second, should return nil")
ok, val = pcall(lpty.read, p, 0.1)
if ok then
	check(val == nil)
else
	fail(tostring(val))
end

-- 5
announce("checking whether we can write to the pty, should return true")
ok, val = pcall(lpty.sendok, p)
if ok then
	check(val)
else
	fail(tostring(val))
end

-- 6
announce("writing data 'abcba\\n' to the pty, should return length of data -> 6")
ok, val = pcall(lpty.send, p, "abcba\n")
if ok then
	check(val == 6)
else
	fail(tostring(val))
end

-- allow the client to react
waitabit()

-- 7
announce("checking whether we can read from the pty, should return true")
ok, val = pcall(lpty.readok, p)
if ok then
	check(val)
else
	fail(tostring(val))
end

-- 8
announce("reading from pty, should return 'abcba\\n+abcba+\\n'")
ok, val = pcall(lpty.read, p, 1)
if ok then
	val = string.gsub(val, "[\r\n]+", '.') -- normalize line endings
	check(val == "abcba.+abcba+.")
else
	fail(tostring(val))
end

-- 9
announce("terminating child process")
ok = pcall(lpty.endproc, p)
check(ok)

-- allow client to terminate
waitabit()

-- 10
announce("Checking whether pty has child process, should return false")
ok, val = pcall(lpty.hasproc, p)
if ok then
	check(val == false)
else
	fail(tostring(val))
end

-- 11
announce("checking whether we can read from pty, should return false")
ok, val = pcall(lpty.readok, p)
if ok then
	check(val == false)
else
	fail(tostring(val))
end

-- 12
announce("reading from pty with a timeout of 0.1 second, should return nil")
ok, val = pcall(lpty.read, p, 0.1)
if ok then
	check(val == nil)
else
	fail(tostring(val))
end

-- test timeout length. In order for this to work there may be no pending data in the pty to read.
function testto(to, tm)
	local t0 = os.time()
	local i
	for i=1,10 do
		p:read(to)
	end
	local t = os.time() - t0
	-- allow for some deviation
	return (tm - 1 < t and t < tm + 1)
end

-- 13
announce("testing timeout 0.1 second by running r:read(0.1) 10 times should take about 1 seconds")
check(testto(0.1, 1))

-- creating pty with no local echo for following tests
pn = lpty.new { no_local_echo = true }

-- 14
announce("checking for data from no_local_echo pty, should return false")
ok, val = pcall(lpty.readok, pn)
if ok then
	check(val == false)
else
	fail(tostring(val))
end

-- 15
announce("starting test client for no_local_echo pty")
ok, val = pcall(lpty.startproc, pn, "lua", "testclient.lua")
if ok then
	check(val)
else
	fail(tostring(val))
end

-- 16
announce("reading from no_local_echo pty, should now return '+abc+\\n'")
ok, val = pcall(lpty.send, pn, "abc\n")
ok, val = pcall(lpty.read, pn, 0.5)
if ok then
	val = string.gsub(val, "[\r\n]+", '.') -- normalize line endings
	check(val == "+abc+.")
else
	fail(tostring(val))
end

-- 17
announce("sending 'xxx\\n' to pty, reading back, should return '+xxx+\\n'")
ok, val = pcall(lpty.send, pn, "xxx\n")
if not ok then
	fail(tostring(val))
else
	ok, val = pcall(lpty.read, pn, 0.5)
	if ok then
		val = string.gsub(val, "[\r\n]+", '.') -- normalize line endings
		check(val == "+xxx+.")
	else
		fail(tostring(val))
	end
end

-- 18
announce("testing exit status for current child, should return (false, nil)")
ok, val, code = pcall(lpty.exitstatus, pn)
if not ok then
	fail(tostring(val))
else
	check((val == false) and (code == nil))
end

-- 19
announce("quitting child then testing exit status, should return ('exit', 0)")
ok, val = pcall(lpty.send, pn, "quit\n")
if not ok then
	fail(tostring(val))
else
	while pn:hasproc() do end
	ok, val, code = pcall(lpty.exitstatus, pn)
	if not ok then
		fail(tostring(val))
	else
		check((val == 'exit') and (code == 0))
	end
end

-- 20
announce("starting child with invalid executable, then testing exit status, should return ('exit', 1)")
ok, val = pcall(lpty.startproc, pn, "./firsebrumf")
if not ok then
	fail(tostring(val))
else
	while pn:hasproc() do end
	ok, val, code = pcall(lpty.exitstatus, pn)
	if not ok then
		fail(tostring(val))
	else
		check((val == 'exit') and (code == 1))
	end
end

-- 21
announce("starting child process, then killing it, then testing exit status, should return ('sig', *) with *>0")
ok, val = pcall(lpty.startproc, pn, "lua")
term = 0
if not ok then
	fail(tostring(val))
else
	while not pn:hasproc() do end
	ok, val = pcall(lpty.endproc, pn)
	if not ok then
		fail(tostring(val))
	else
		while pn:hasproc() do end
		ok, val, code = pcall(lpty.exitstatus, pn)
		if not ok then
			fail(tostring(val))
		else
			term = code
			check((val == 'sig') and (code > 0))
		end
	end
end

-- 22
announce("starting child process, then killing it with kill=true, then testing exit status, should return ('sig', *) with *>0 and also not equal to * from prev. test")
ok, val = pcall(lpty.startproc, pn, "lua")
if not ok then
	fail(tostring(val))
else
	while not pn:hasproc() do end
	ok, val = pcall(lpty.endproc, pn, true)
	if not ok then
		fail(tostring(val))
	else
		while pn:hasproc() do end
		ok, val, code = pcall(lpty.exitstatus, pn)
		if not ok then
			fail(tostring(val))
		else
			check((val == 'sig') and (code > 0) and (code ~= term))
		end
	end
end

-- cleanup
pn:flush()

-- 23
announce("reading environment from pty, should return a table with stuff in it")
ok, env = pcall(lpty.getenviron, pn)
envsiz = 0
if not ok then
	fail(tostring(env))
else
	ok = true
	for k, v in pairs(env) do
		envsiz = envsiz + 1
		ok = ok and (type(k) == 'string') and (type(v) == 'string')
	end
	check(ok)
end

-- 24
announce("calling /usr/bin/env with an empty environment, then reading output, should return nothing at all")
ok, err = pcall(lpty.setenviron, pn, {})
if not ok then
	fail(tostring(err))
else
	ok, err = pcall(lpty.startproc, pn, '/usr/bin/env')
	if not ok then
		fail(tostring(err))
	else
		while pn:hasproc() do end
		ok, val = pcall(lpty.read, pn, 1)
		if not ok then
			fail(tostring(val))
		else
			check(val == nil)
		end
	end
end

-- 25
announce("calling /usr/bin/env with {a=1} as its environment, then reading output, should return 'a=1\\n'")
ok, err = pcall(lpty.setenviron, pn, {a=1})
if not ok then
	fail(tostring(err))
else
	ok, err = pcall(lpty.startproc, pn, '/usr/bin/env')
	if not ok then
		fail(tostring(err))
	else
		while pn:hasproc() do end
		ok, val = pcall(lpty.read, pn, 1)
		if not ok then
			fail(tostring(val))
		else
			val = string.gsub(tostring(val), "[\r\n]+", '.') -- normalize line endings
			check(val == "a=1.")
		end
	end
end

-- 26
announce("resetting then reading environment from pty, should return a table with stuff in it, size as before we messed with it")
ok = pcall(lpty.setenviron, pn, nil)
ok, env = pcall(lpty.getenviron, pn)
mysiz = 0
if not ok then
	fail(tostring(env))
else
	ok = true
	for k, v in pairs(env) do
		mysiz = mysiz + 1
		ok = ok and (type(k) == 'string') and (type(v) == 'string')
	end
	check(ok and (mysiz == envsiz))
end

-- 27
announce("calling /usr/bin/env on standard environment, should return as many lines as there are entries in the environment (as counted before)")
ok = pcall(lpty.startproc, pn, '/usr/bin/env')
if not ok then
	fail(tostring(val))
else
	while pn:hasproc() do end
	val = ""
	while pn:readok() do val = val .. pn:read() end
	cnt = 0
	string.gsub(val, ".-\n", function () cnt = cnt + 1 end)
	check(cnt == envsiz)
end

-- cleanup
pn:endproc()
pn:flush()

-- 28
announce("testing readline on a standard pty")
pn=lpty.new()
ok, err = pcall(lpty.startproc, pn, "lua", "testclient.lua")
if not ok then
	fail(tostring(err))
else
	waitabit() -- wait for client to start
	pn:send("abc\n")
	pn:send("def\n")
	waitabit() -- wait for all output to appear
	ok, val = pcall(lpty.readline, pn)
	if val == "abc" then
		ok, val = pcall(lpty.readline, pn)
		if val == "def" then
			ok, val = pcall(lpty.readline, pn)
			if val == "+abc+" then
				ok, val = pcall(lpty.readline, pn)
				check(val == "+def+")
			else
				fail()
			end
		else
			fail()
		end
	else
		fail()
	end
end
pn:endproc()

-- 29
announce("testing readline on a raw mode pty")
pn=lpty.new{raw_mode = true}
ok, err = pcall(lpty.startproc, pn, "lua", "testclient.lua")
if not ok then
	fail(tostring(err))
else
	waitabit() -- wait for client to start
	pn:send("abc\n")
	pn:send("def\n")
	waitabit() -- wait for all output to appear
	ok, val = pcall(lpty.readline, pn)
	if val == "+abc+" then
		ok, val = pcall(lpty.readline, pn)
		check(val == "+def+")
	else
		fail()
	end
end
pn:endproc()

-- expect test
function expecttest(pn)
	ok, err = pcall(lpty.startproc, pn, "lua")
	if not ok then
		fail(tostring(err))
		return
	end
	ok, val = pcall(lpty.expect, pn, "> $", false, 1)
	if not ok then
		fail(tostring(val))
		return
	end
	pn:send("loadfile('testclient.lua')()\n")
	pn:send("abc\n")
	ok, val = pcall(lpty.expect, pn, "%+([a-z]+)%+", false, 1)
	if not ok then
		fail(tostring(val))
	else
		check(val == "abc")
	end
	pn:endproc()
end

-- 30
announce("testing expect on a standard pty")
pn = lpty.new()
waitabit()
expecttest(pn)

-- 31
announce("testing expect on a no local echo pty")
pn = lpty.new{no_local_echo = true}
waitabit()
expecttest(pn)

-- 32
announce("testing expect on a raw mode pty")
pn = lpty.new{raw_mode = true}
waitabit()
expecttest(pn)

-- 33
announce("creating a pty, then setflag()ing it to no_local_echo mode, then back to default")
pn = lpty.new()
ok = pn:startproc("lua", "testclient.lua")
if ok then
	pn:send("x\n")
	waitabit()
	val = pn:read(1)
	val = string.gsub(val, "[\r\n]+", '.') -- normalize line endings
	local ok, val1 = pcall(lpty.setflag, pn, 'no_local_echo', true)
	if ok then
		pn:send("x\n")
		waitabit()
		val1 = pn:read(1)
		val1 = string.gsub(val1, "[\r\n]+", '.') -- normalize line endings
		local ok, val2 = pcall(lpty.setflag, pn, 'no_local_echo', false)
		if ok then
			pn:send("x\n")
			waitabit()
			val2 = pn:read(1)
			val2 = string.gsub(val2, "[\r\n]+", '.') -- normalize line endings
			check(val == 'x.+x+.' and val1 == '+x+.' and val2 == 'x.+x+.', val .. ' vs '..val1..' vs '..val2)
		else
			fail(tostring(val2))
		end
	else
		fail(tostring(val1))
	end
else
	fail(tostring(val))
end
pn:flush()

-- 34
announce("creating a pty, then setflag()ing it to raw mode, then back to default")
pn = lpty.new()
ok = pn:startproc("lua", "testclient.lua")
if ok then
	pn:send("x\n")
	waitabit()
	val = pn:read(1)
	val = string.gsub(val, "[\r\n]+", '.') -- normalize line endings
	local ok, val1 = pcall(lpty.setflag, pn, 'raw_mode', true)
	if ok then
		pn:send("x\n")
		waitabit()
		val1 = pn:read(1)
		val1 = string.gsub(val1, "[\r\n]+", '.') -- normalize line endings
		local ok, val2 = pcall(lpty.setflag, pn, 'raw_mode', false)
		if ok then
			pn:send("x\n")
			waitabit()
			val2 = pn:read(1)
			val2 = string.gsub(val2, "[\r\n]+", '.') -- normalize line endings
			check(val == 'x.+x+.' and val1 == '+x+.' and val2 == 'x.+x+.', val .. ' vs '..val1..' vs '..val2)
		else
			fail(tostring(val2))
		end
	else
		fail(tostring(val1))
	end
else
	fail(tostring(val))
end
pn:flush()

-- 35
announce("creating pty with separated stderr stream")
pn = lpty.new{separate_stderr = true}
check(pn)

-- 36
announce("forcing an error on pty with separated error stream. output should appear on readerr() not read()")
ok, err = pcall(lpty.startproc, pn, "/this must fail")
if not ok then
	fail(tostring(err))
elseif pn:readok(1) == false then
	check(pn:readerr(1) ~= nil, "readerr() returned no data")
else
	fail("data appeared on pty")
end
pn:flush()

-- 37
announce("changing flag on pty to separate_stderr=false then forcing error. output should appear on pty.")
pn:setflag("separate_stderr", false)
ok, err = pcall(lpty.startproc, pn, "/this must fail")
if not ok then
	fail(tostring(err))
elseif pn:readok(1) == true then
	check(pn:readerr(1) == nil, "data appeared on readerr()")
else
	fail("no data appeared on pty")
end
pn:flush()

-- 38
announce("changing flag on pty to separate_stderr=true then forcing error. output should appear on readerr() not read()")
pn:setflag("separate_stderr", true)
ok, err = pcall(lpty.startproc, pn, "/this must fail")
if not ok then
	fail(tostring(err))
elseif pn:readok(1) == false then
	check(pn:readerr(1) ~= nil, "readerr() returned no data")
else
	fail("data appeared on pty")
end
pn:flush()

-- all done
print("Tests " .. tostring(ntests) .. " failed " .. tostring(nfailed))
