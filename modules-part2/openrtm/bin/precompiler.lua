#!/bin/sh

LUAROCKS_SYSCONFDIR='/usr/local/etc/luarocks' exec '/usr/local/bin/lua' -e 'package.path="/home/katka/Desktop/FIIT/BP/luadb/etc/luarocks_test/modules/openrtm/share/lua/5.3/?.lua;/home/katka/Desktop/FIIT/BP/luadb/etc/luarocks_test/modules/openrtm/share/lua/5.3/?/init.lua;"..package.path;package.cpath="/home/katka/Desktop/FIIT/BP/luadb/etc/luarocks_test/modules/openrtm/lib/lua/5.3/?.so;"..package.cpath;local k,l,_=pcall(require,"luarocks.loader") _=k and l.add_context("loop","2.3beta-1")' '/home/katka/Desktop/FIIT/BP/luadb/etc/luarocks_test/modules/openrtm/lib/luarocks/rocks-5.3/loop/2.3beta-1/bin/precompiler.lua' "$@"
