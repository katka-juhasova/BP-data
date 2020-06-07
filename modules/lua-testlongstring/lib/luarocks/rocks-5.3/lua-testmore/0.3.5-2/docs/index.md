
# lua-TestMore

---

## Overview

lua-TestMore is a port of the Perl5 module
[Test::More](http://search.cpan.org/~mschwern/Test-Simple/).

It uses the
[Test Anything Protocol](http://en.wikipedia.org/wiki/Test_Anything_Protocol)
as output, that allows a compatibility with the Perl QA ecosystem.
For example,
[prove](http://search.cpan.org/~andya/Test-Harness/bin/prove)
a basic CLI, or
[Smolder](http://search.cpan.org/~wonko/Smolder/)
a Web-based Continuous Integration Smoke Server.

It's an extensible framework.

It allows a simple and efficient way to write tests (without OO style).

Some tests could be marked as **TODO** or **skipped**.

Errors could be fully checked with `error_like()`.

It supplies a Test Suite for Lua itself.

## References

Ian Langworth, chromatic,
[Perl Testing](http://oreilly.com/catalog/9780596100926)
O'Reilly, 2005

## Status

lua-TestMore is in beta stage.

It's developed for Lua 5.1, 5.2 & 5.3.

## Download

lua-TestMore source can be downloaded from
[GitHub](http://github.com/fperrad/lua-TestMore/releases/).

## Installation

The easiest way to install lua-TestMore is to use LuaRocks:

```sh
luarocks install lua-testmore
```

or manually, with:

```sh
make install
```

## The Lua Test Suite (5.1, 5.2 & 5.3)

This suite is usable with :

- the standard [lua](http://www.lua.org/),
- [LuaJIT](http://luajit.org/),
- ...

It gives this [coverage](https://fperrad.github.io/lua-TestMore/cover_lua515/src/index.html) with Lua 5.1.5,
this [coverage](https://fperrad.github.io/lua-TestMore/cover_lua524/src/index.html) with Lua 5.2.4
and this [coverage](https://fperrad.github.io/lua-TestMore/cover_lua534/src/index.html) with Lua 5.3.4.

## Copyright and License

Copyright &copy 2009-2018 Fran&ccedil;ois Perrad
[![OpenHUB](http://www.openhub.net/accounts/4780/widgets/account_rank.gif)](http://www.openhub.net/accounts/4780?ref=Rank)
[![LinkedIn](http://www.linkedin.com/img/webpromo/btn_liprofile_blue_80x15.gif)](http://www.linkedin.com/in/fperrad)

This library is licensed under the terms of the MIT/X11 license,
like Lua itself.
