
LUA = ../../lua-5.2.4/src/lua
LUAJIT = ../../LuaJIT-2.0.5-compat52/src/luajit
LUA_COVER = ../../gh-pages/lua-TestMore/lua-5.2.4/src/lua
LUA_COMPAT = true

LUA_VERSION = $(shell $(LUA) -e "print(_VERSION)")
OSNAME = $(shell perl -MConfig -e "print Config->{osname}")
INTSIZE = $(shell perl -MConfig -e "print Config->{longsize}")

export LUA_PATH=;;../src/?.lua
export LUA_INIT=platform = { osname=[[$(OSNAME)]], intsize=$(INTSIZE), compat=$(LUA_COMPAT) }

version:
	@echo $(LUA_VERSION)

harness:
	prove --exec=$(LUA) *.t

sanity:
	prove --exec=$(LUA) 0*.t

luajit:
	prove --exec=$(LUAJIT) *.t

coverage:
	prove --exec=$(LUA_COVER) *.t

