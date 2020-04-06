
LUA = ../../lua-5.3.4/src/lua
LUA_COVER = ../../gh-pages/lua-TestMore/lua-5.3.4/src/lua
LUA_COMPAT = true

LUA_VERSION = $(shell $(LUA) -e "print(_VERSION)")
OSNAME = $(shell perl -MConfig -e "print Config->{osname}")

export LUA_PATH=;;../src/?.lua
export LUA_INIT=platform = { osname=[[$(OSNAME)]], compat=$(LUA_COMPAT) }

version:
	@echo $(LUA_VERSION)

harness:
	prove --exec=$(LUA) *.t

sanity:
	prove --exec=$(LUA) 0*.t

coverage:
	prove --exec=$(LUA_COVER) *.t

