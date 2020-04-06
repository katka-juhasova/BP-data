#!/bin/sh

exec '/usr/bin/lua5.1' -e 'package.path="/home/michael/.luarocks/share/lua/5.1/?.lua;/home/michael/.luarocks/share/lua/5.1/?/init.lua;/usr/local/share/lua/5.1/?.lua;/usr/local/share/lua/5.1/?/init.lua;"..package.path; package.cpath="/home/michael/.luarocks/lib/lua/5.1/?.so;/usr/local/lib/lua/5.1/?.so;"..package.cpath' -e 'local k,l,_=pcall(require,"luarocks.loader") _=k and l.add_context("many2one","1.17.3.1-1")' '/home/michael/luadb/etc/luarocks_test/modules/many2one/lib/luarocks/rocks/many2one/1.17.3.1-1/bin/many2one.lua' "$@"
