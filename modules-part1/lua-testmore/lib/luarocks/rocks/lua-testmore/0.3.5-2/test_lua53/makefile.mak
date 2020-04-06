# nmake /F makefile.mak

LUA = lua.exe
LUAC = luac.exe

RUN_LUA = $(LUA)
RUN_LUAC = $(LUAC)
OSNAME = MSWin32

harness: env
	@prove --exec=$(LUA) *.t

sanity: env
	@prove --exec=$(LUA) 0*.t

env:
	@set LUA_PATH=;;../src/?.lua
	@set LUA_INIT=platform = { lua=[[$(RUN_LUA)]], luac=[[$(RUN_LUAC)]], osname=[[$(OSNAME)]], compat=true }

