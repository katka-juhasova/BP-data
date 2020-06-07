--test lsleep
local U = 10000000
local T_SEC = 1
local U_SEC = T_SEC * U --10m
local lsleep = require 'lsleep'

local fmt = string.format
local printf = function(str, ...) print(fmt(str, ...)) end

local sleep, usleep = lsleep.sleep, lsleep.usleep

printf('test default __call metamethod with %s seconds', T_SEC)
local start = os.time()
lsleep(T_SEC)
local dur = os.time() - start
assert(dur == T_SEC, fmt("Expected %s second(s) to elaps. Instead %s did.", T_SEC, dur))
print("Passed.")

printf("test sleep with %d", T_SEC)
local start = os.time()
lsleep(T_SEC)
local dur = os.time() - start
assert(dur == T_SEC, fmt("Expected %s second(s) to elaps. Instead %s did.", T_SEC, dur))
print("Passed.")

printf("test usleep with %d", U_SEC)
local start = os.time()
lsleep(T_SEC)
local dur = os.time() - start
assert(dur == (U_SEC / U), fmt("Expected %s second(s) to elaps. Instead %s did.", T_SEC, dur))
print("Passed.")