# lua localexec

## 1. Synopsis

`localexec` is a lua module that executes a command by accepting (stdin,env,args) as input and returning (resultcode,stdout,stderr) as output.

## 2. Installation

```
$ luarock install localexec
```

## 3. Usage

### Typical use case

```(lua)
local localexec=require("localexec")

local processInput={cmd="/usr/bin/myprogram", 
                    args={arg1,arg2,arg3}, 
                    env={env1=val1,env2=val2,env3=val3}, 
                    stdin="hello this is my stdin input"
                    }

local processOutput=localexec.spawn(processInput)

-- Dump output for test purposes:

print("lua result:" .. tostring(processOutput.luaresult))
print("retcode:" .. tostring(processOutput.retcode))
print("stdout:".. processOutput.stdout)
print("stderr:".. processOutput.stderr)

-- Typical processing:

if processOutput.retcode ~= 0 then
    print("error:" .. processOutput.stderr)
    handleError()
else
    print("success")
    handleSuccess()
end

```

### processInput

* `cmd`: required
* `args`: optional list of arguments
* `env`: optional list of environment variables
* `stdin`: will be fed to stdin

### processOutput

`luaresult`: result returned by `os.execute` (nil=ok and false=error)
`retcode`: integer result returned by shell (0=ok and not 0=error)
`stdout`: output on stdout
`stderr`: output on stderr

## 4. Similar modules and functions

### (lua built-in) os.execute

Out of the box, `os.execute` does not accept `stdin` input nor `env` variables and only returns `retcode`.
It does not return `stdout` not `stderr` output.

### (lua built-in) io.popen

`io.popen` does not accept `stdin` nor `env` and only returns `stdout`.
It does not return `stderr` nor `retcode`.

### popen3

The [popen3](https://gist.github.com/mike-bourgeous/2be6c8900bf624887fe5fee4f28552ef#file-popen3_2011-c) module, and its
[alternative](https://github.com/kylemanna/lua-popen3/blob/master/pipe.lua) or [other alternative](https://github.com/LuaDist/lpc) provide the user with streams, and leaves him the task to simultaneously feed `stdin` and read from `stdout` and `stderr`. This can be achieved with co-routines, threads, or with the libc `select()` function. For the purpose of supplying `stdin` as a lua string and reading out `stdout` and `stderr` as lua strings, using these modules requires extra work.

## 5. admin scripts

The `admin.sh` facilitates developing, building, and publishing the program.
You can use `./admin.sh help` to view the commands available.

It pushes the source code changes to the github publication platform.
It pushes the lua module to the luarocks distribution platform.

## 6. Issues and feedback

Feel free to post a message on the [issue list](https://github.com/eriksank/localexec/issues).

## 7. License

```
Written by Erik Poupaert
Cambodia,(c) 2019
Licensed under the LGPL
```

