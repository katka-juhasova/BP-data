Loadconf
========

Loadconf helps you read the configurations of LÖVE games, for use in
external tooling. Since each LÖVE config is an executable Lua file, we
can't meaningfully handle every possible config, but our approach is
Good Enough(tm) most of the time.

Loadconf is a [Luarocks library][lr]. This means you can install it using 

```
# luarocks install loadconf
```

or depend on it in your own Luarocks modules. If you'd rather bundle it
directly in your app, you can try

```
$ wget https://raw.githubusercontent.com/Alloyed/loadconf/master/loadconf.lua
```

[lr]: https://luarocks.org/modules/alloyed/loadconf

Docs
====

If you'd like to write loadconf-friendly config files, [there are a few
rules you should follow][rules].

If you'd like to use loadconf yourself, check out the [API docs][docs].

Loadconf uses [LDoc][ldoc] for docs generation and [Busted][busted] for
unit tests. You can get both from luarocks.

[rules]: https://github.com/Alloyed/loadconf/blob/master/SANDBOX.md
[docs]: https://alloyed.github.io/loadconf/
[ldoc]: https://stevedonovan.github.io/ldoc/
[busted]: https://olivinelabs.com/busted/
