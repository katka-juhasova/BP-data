# debugkit

Print debugging made easier.

## Why?

We all know what happens when we have to debug our code. Most of the times,
we don't use a full-fledged Lua debugger, and don't even think about it if
you are using MoonScript. What happens is that we end up putting `print`
statements in the part of the code that we guess the error is happening.

Now, this usually solves most of our issues if our library is small, but
if our library is gigantic, all you're going to get is a lot of unordered
printed tables and values. One approach I take is prefixing them with a
word or tag, but then I would need a custom function to filter them out
which was janky at best. I didn't want to add and remove messages. I didn't
want to get lost in a sea of all-white values. I needed something practical.

That is all very good, there are many logger libraries out there to help me.
So, why did I decide to make my own? If you told me I had [NHI Syndrome](https://en.wikipedia.org/wiki/Not_invented_here),
I would probably agree with you, but I don't think that is the reason.
I've been looking at other libraries, and some were old, some were oriented
for time logging, some weren't as flexible... If I kept dwelling, eventually
I would have found one, but something powerful didn't seem to pop up that fast.

What I made here is some kind of framework. Even though I would very happily
add features to the repo such as better stack traces, printing locals, etc. if
anyone PR'ed them, there is none of that. This gives you mainly two concepts,
a logger and a sink. All around is just helper tools or functions. You can
extend those two concepts to make amazing stuff. Hell, you could even submit
logging results via HTTP if you wanted. But I just wanna ~~grill~~ print!

Or simply you just need a logger.

## How?

Install the library using LuaRocks, and if I can be arsed in the future, my
own Lua package manager that hopefully does not want to make me go live in a
forest all by myself.

```
$ luarocks install debugkit
```

That will automatically install all dependencies. If that is not the case for
some reason, do:

```
$ luarocks install filekit
$ luarocks install guardia
```

And if you want to use the JSON sink in `debugkit.log.sinks`, install any of
`dkjson`, `lua-cjson2` or `rxi-json-lua`. I've personally tested it under
`cjson`, but all of them should work the same.

If you want to use the colorized `inspect` function in `debugkit.inspect`, you
will need `lrexlib-pcre2`. The strings are not precisely easy to color without them.

You can install optional dependencies using the metapackage `debugkit-extra`.

The documentation is availiable at https://git.daelvn.ga/debugkit.

## When?

Ideally when you need to debug, or log something. Perhaps if you want a pretty
`inspect` function. Otherwise... what?

## Who?

Dael Muñiz [daelvn@gmail.com](mailto:daelvn@gmail.com)

I am so sorry if you can't type the ñ, I agree that I shouldn't have been born
Spanish. Feel free to use "Muniz".

## License

Throwing this to the public domain. Steal it for all I care.

## Goodbye?

Goodbye.