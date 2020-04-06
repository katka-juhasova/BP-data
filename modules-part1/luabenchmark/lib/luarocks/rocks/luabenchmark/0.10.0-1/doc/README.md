# luabenchmark

[![Build Status](https://api.travis-ci.org/spacewander/luabenchmark.svg?branch=master)](http://travis-ci.org/spacewander/luabenchmark)
A tiny library for benchmark.

## doc

See <http://spacewander.github.io/luabenchmark/index.html>

## lua performance tips

From <http://www.lua.org/gems/sample.pdf>

```
local bm = require './benchmark'
local reporter = bm.bm(6)
```

### use locals

```
reporter:report(function()
    for i = 1, 1e6 do
        local x = math.sin(i)
    end
end, 'slow')

reporter:report(function()
    local sin = math.sin
    for i = 1, 1e6 do
        local x = sin(i)
    end
end, 'fast')

--slow   system: 0.140    user: 0.000 total: 0.140    real: 0.146
--fast   system: 0.110    user: 0.000 total: 0.110    real: 0.109
```

### pre-create table space

```
reporter:report(function()
    for i = 1, 1e6 do
        local a = {}
        a[1] = 1; a[2] = 2; a[3] = 3
    end
end, 'slow')

reporter:report(function()
    for i = 1, 1e6 do
        local a = {nil, nil, nil}
        a[1] = 1; a[2] = 2; a[3] = 3
    end
end, 'fast')

slow   system: 0.810    user: 0.000 total: 0.810    real: 0.813
fast   system: 0.350    user: 0.000 total: 0.350    real: 0.354
```

### use table.concat to concat strings in a loop

```
reporter:report(function()
    local s = ''
    for i = 1, 1e5 do
        s = s .. 'aaa'
    end
end, 'slow')

reporter:report(function()
    local t = {}
    for i = 1, 1e5 do
        t[#t + 1] = 'aaa'
    end
    s = table.concat(t, '')
end, 'fast')

slow   system: 5.120    user: 2.860 total: 7.980    real: 7.998
fast   system: 0.030    user: 0.000 total: 0.030    real: 0.030
```

### reduce, reuse, recycle

```
reporter:report(function()
    local t = {}
    local time = os.time
    for i = 1, 1e5 do
        t[i] = time({year = i, month = 6, day = 14})
    end
end, 'slow')

reporter:report(function()
    local t = {}
    local time = os.time
    local aux = {year = nil, month = 6, day = 14}
    for i = 1, 1e5 do
        aux.year = i
        t[i] = time(aux)
    end
end, 'fast')

slow   system: 0.270    user: 0.100 total: 0.370    real: 0.369
fast   system: 0.200    user: 0.110 total: 0.310    real: 0.315
```
