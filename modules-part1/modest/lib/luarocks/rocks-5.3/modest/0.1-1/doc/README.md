# modest

Script/module mode detection while running/loading Lua files.


### Introduction

This library is a successfully encoding of the Python magic
`__name__` variable. In Python programmers often check that
variable to detect if their files are running under script
mode or either being loaded and imported as modules. It is
useful, for example, to provide an usage example for your
library's clients, or even to embed unit tests in your own
modules. It's also useful to expose your own module to be
called from command-line applications (e.g, shell/pipes).


### Installation

On this project directory.

```
$ luarocks make
```

---

On Luarocks server.

```
$ luarocks install modest
```

---

Alternatively, you could just copy the folder `src/modest` in
your own configured Lua library path directory.


### Usage

After the installation, you simply load it as:

```
local modest = require 'modest'
```

After successfully loading such library, you'll be able
to detect how your clients use your own library. For that,
you could just use any from the meaningful exported functions
below:

* modest.script ( ) → boolean
* modest.module ( ) → boolean

As a clean example, we have the following useless `library.py` file:

```python
#!/usr/bin/env python

def run():
    pass

if __name__ == '__main__':
    run()
```

The function `run` could be called either as:

```
$ python
>>> import library
>>> library.run()
```
or even as:

```
$ python library.py
```

The Lua port will be something like that below:

```lua
#!/usr/bin/env lua

local modest = require 'modest'
local export = { }

function export.run ( )

end

if modest.script ( ) then
    export.run ( )

else
    return export
end
```

If you even try to execute that module itself, it will detect the
script mode and throw you some compelling argument (I'm
assuming here you are in the project root directory).

```
> -- calling from the lua interpreter --
>
> dofile "src/modest/init.lua"
src/modest/init.lua:35: You should not pass here through the script mode!
stack traceback:
        [C]: in function 'error'
        src/modest/init.lua:35: in main chunk
        [C]: in function 'dofile'
        stdin:1: in main chunk
        [C]: in ?
```

```
$ ### calling from the command line ###
$
$ lua src/modest/init.lua
lua: src/modest/init.lua:35: You should not pass here through the script mode!
stack traceback:
        [C]: in function 'error'
        src/modest/init.lua:35: in main chunk
        [C]: in ?

```


### How it works?

Black magic, indeed. The root of all evils and bugs. Honestly, it detects the use
of `require` function on the call stack. 'Cause Lua differs the loading time from
the evaluation time, it likely won't imply in troubles along the way.

Keep in mind that this library relies on dark magics such as `debug` library/API,
and therefore, you must not sandbox that. Trust me, I won't steal your passwords
or clone your credit cards. Well, depending on how much rich you are, it's a strong
temptation to do that.

None the less, pull-requests and issues are welcome. Have fun & good hacking, kiddo!

