#! /usr/bin/lua

require 'Test.More'

local conn = io.stdout
local mt = getmetatable(conn)
mt.send = mt.write -- now, acts like a socket

require 'Test.Builder.SocketOutput'.init(conn)

plan(1)

ok(true, "with dummy socket")

