
# lua-Coat

---

*Language shapes the way we think,
<br /> and determines what we can think about.
<br /> &mdash; B.L. Whorf*

---

## Overview

Like any other Internal
[DSL](http://en.wikipedia.org/wiki/Domain-specific_language),
lua-Coat is dual :

- an Oriented Object Language
- a Lua library

lua-Coat shares with Lua : the same syntax and the same _style_.

*Language design is library design
<br /> and library design is language design.
<br /> &mdash; old* Bell Labs *proverb*
    
## Lineage

Perl5, like Lua, has no OO model, just OO mechanism.
This allows a proliferation (or experimentation) of different model.

Now with [Moose](http://www.iinteractive.com/moose/),
Perl5 find its _ultimate_ OO model.
Moose borrows all the best features from Perl6, CLOS (LISP), Smalltalk and many other languages.
Moose is built on top of a metaobject protocol, with full introspection.

[Coat](http://www.sukria.net/perl/coat/)
is light-weight Perl5 module which just mimics Moose.
Now, Coat is **deprecated**, but there are some successors
[Mouse](http://search.cpan.org/~gfuji/Mouse/),
[Moo](http://search.cpan.org/~mstrout/Moo/),
[Mo](http://search.cpan.org/~ingy/Mo/).

Finally, lua-Coat is the Lua port of Coat.

## Status

lua-Coat is in beta stage.

It's developed for Lua 5.1, 5.2 & 5.3.

## Download

lua-Coat source can be downloaded from
[GitHub](http://github.com/fperrad/lua-Coat/releases/).

## Installation

lua-Coat is available via LuaRocks:

```sh
luarocks install lua-coat
```

or manually, with:

```sh
make install
```

## Test

The test suite requires the module
[lua-TestMore](http://fperrad.github.io/lua-TestMore/).

```sh
make test
```

## Copyright and License

Copyright &copy; 2009-2018 Fran&ccedil;ois Perrad
[![OpenHUB](http://www.openhub.net/accounts/4780/widgets/account_rank.gif)](http://www.openhub.net/accounts/4780?ref=Rank)
[![LinkedIn](http://www.linkedin.com/img/webpromo/btn_liprofile_blue_80x15.gif)](http://www.linkedin.com/in/fperrad)

This library is licensed under the terms of the MIT/X11 license,
like Lua itself.
