
# lua-Silva

---

_your personal string matching expert_

---

## Overview

lua-Silva allows to match a URI against various kind of pattern :
URI Template, shell, Lua regex, PCRE regex, ...

Some of them allow to capture parts of URI.

lua-Silva was inspired by [Mustermann](http://sinatrarb.com/mustermann/)
( a part of Sinatra / Ruby ).

## Status

lua-Silva is in beta stage.

It's developed for Lua 5.1, 5.2 & 5.3.

## Download

lua-Silva source can be downloaded from
[Framagit](https://framagit.org/fperrad/lua-Silva).

## Installation

lua-Silva is available via LuaRocks:

```sh
luarocks install lua-silva
```

lua-Silva is available via opm:

```sh
opm get fperrad/lua-silva
```

or manually, with:

```sh
make install
```

## Test

The test suite requires the module
[lua-TestMore](http://fperrad.frama.io/lua-TestMore/).

    make test

## Copyright and License

Copyright &copy; 2017-2019 Fran&ccedil;ois Perrad

This library is licensed under the terms of the MIT/X11 license, like Lua itself.
