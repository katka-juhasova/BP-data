<img align="right" src="stuart.png" width="70">

## Stuart ML

A native Lua implementation of [Spark MLlib](https://spark.apache.org/docs/2.2.0/ml-guide.html). This is a companion module for [Stuart](https://github.com/BixData/stuart), the Spark runtime for embedding and edge computing.

![Build Status](https://api.travis-ci.org/BixData/stuart-ml.svg?branch=master)
[![License](http://img.shields.io/badge/Licence-Apache%202.0-blue.svg)](LICENSE)
[![Lua](https://img.shields.io/badge/Lua-5.1%20|%205.2%20|%205.3%20|%20JIT%202.0%20|%20JIT%202.1%20|%20eLua%20|%20Fengari%20|%20GopherLua%20|%20Redis-blue.svg)]()

## Getting Started

### Installing

To install on an operating system:

```sh
$ luarocks install stuart-ml
```

To load into a web page:

```html
<html>
  <body>
    <script type="text/javascript" src="https://cdn.jsdelivr.net/npm/fengari-web@0.1.2/dist/fengari-web.js"></script>
    <script type="application/lua" src="https://cdn.jsdelivr.net/npm/lua-stuart@0.1.8-0/stuart.lua"></script>
    <script type="application/lua" src="https://cdn.jsdelivr.net/npm/lua-stuart-ml@0.1.8-0/stuart-ml.lua"></script>
  
    <script type="application/lua">
      local Vectors = require 'stuart-ml.linalg.Vectors'
      local denseVector = Vectors.dense({0.1, 0.0, 0.3})
      ...
    </script>
    
  </body>
</html>
```

## API Guide

* [Data types](./docs/data-types.md)
* [Basic statistics](./docs/statistics.md)
* [Clustering](./docs/clustering.md)

## Testing

### Testing Locally

```sh
$ busted -v
●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●
62 successes / 0 failures / 0 errors / 0 pending : 0.252009 seconds
```

### Testing with a Specific Lua Version

```sh
$ docker build -f Test-Lua5.3.Dockerfile -t test .
$ docker run -it test busted -v
●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●
62 successes / 0 failures / 0 errors / 0 pending : 0.252009 seconds
```
