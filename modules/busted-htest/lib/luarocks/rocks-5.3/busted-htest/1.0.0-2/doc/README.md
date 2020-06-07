# busted-htest

This is an alternative output handler for
[Busted](https://github.com/Olivine-Labs/busted), a unit testing framework for
Lua.

It is based on the `gtest` output handler that is bundled with Busted.

## Features

* More succint output: prints one line per test in the success case
* Always produces color output on Unix
* Test timing is showcased to the left, and long-running tests (over 1 or 10 seconds) are highlighted in different colors

## Installing

```bash
luarocks install busted-htest
```

## Using

```bash
busted -o htest -v
```

or add a file `.busted` to your project root containing

```busted
return {
   default = {
      verbose = true,
      output = "htest"
   },
}
```

(The `verbose`/`-v` flag is optional, but it produces a nice summary at the end.)

## License

This is based off the code of `gtest` from Busted, and like Busted, it is MIT-licensed.
