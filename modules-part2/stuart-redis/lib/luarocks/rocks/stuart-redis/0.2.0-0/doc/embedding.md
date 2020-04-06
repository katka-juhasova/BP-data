# Embedding

It is possible to run [Stuart](https://github.com/BixData/stuart)-based Spark jobs within a [Redis EVAL](https://redis.io/commands/eval) command.

Stuart-Redis automatically detects whether it is running inside of Redis, and in that case it requires no special configuration.

## Example Spark job and build pipeline

### Step 1: Write a Spark job

Create the following `main.lua` file:

```lua
local aristotleSaid = [[We are what we repeatedly do. Excellence, then, is not an act, but a habit. It is the mark of an educated
mind to be able to entertain a thought without accepting it.]]

local stuart = require 'stuart'
local stuartRedis = require 'stuart-redis'

local function splitUsingGlob(str, pattern)
  local result = {}
  for s in string.gmatch(str, pattern) do
    table.insert(result, s)
  end
  return result
end

local sc = stuart.NewContext()
sc = stuartRedis.export(sc)
    
local words = sc:parallelize(splitUsingGlob(aristotleSaid, '%w+'))
    
local wordCounts = words
  :map(function(word) return {word, 1} end)
  :reduceByKey(function(r, x) return r+x end)
  :map(function(e) return {e[1], tostring(e[2])} end)
    
sc:toRedisZSET(wordCounts, 'aristotleWordCounts')
```

### Step 2: Install Lua Amalgamator for Redis

```sh
$ luarocks install amalg-redis
```

### Step 3: Generate `amalg.cache` file

Using your local OS and its Lua VM, perform a trial run of your Spark job, while allowing `amalg-redis` to capture the module dependencies that are used during execution.

```sh
$ REDIS_URL=redis://localhost:6379 lua -lamalg-redis main.lua

INFO Running Stuart (Embedded Spark 2.2.0)
```

This produces an `amalg.cache` file in the current directory, which is required by the amalgamation process.

Monitoring Redis during this process shows:

```sh
$ redis-cli
monitor
.... [0 127.0.0.1:50232] "ZADD" "aristotleWordCounts" "1" "are"
.... [0 127.0.0.1:50232] "ZADD" "aristotleWordCounts" "1" "what"
.... [0 127.0.0.1:50232] "ZADD" "aristotleWordCounts" "1" "mind"
.... [0 127.0.0.1:50232] "ZADD" "aristotleWordCounts" "1" "able"
.... [0 127.0.0.1:50232] "ZADD" "aristotleWordCounts" "1" "educated"
.... [0 127.0.0.1:50232] "ZADD" "aristotleWordCounts" "1" "repeatedly"
.... [0 127.0.0.1:50232] "ZADD" "aristotleWordCounts" "1" "it"
.... [0 127.0.0.1:50232] "ZADD" "aristotleWordCounts" "1" "then"
.... [0 127.0.0.1:50232] "ZADD" "aristotleWordCounts" "2" "an"
.... [0 127.0.0.1:50232] "ZADD" "aristotleWordCounts" "1" "accepting"
.... [0 127.0.0.1:50232] "ZADD" "aristotleWordCounts" "1" "entertain"
.... [0 127.0.0.1:50232] "ZADD" "aristotleWordCounts" "1" "do"
.... [0 127.0.0.1:50232] "ZADD" "aristotleWordCounts" "1" "but"
.... [0 127.0.0.1:50232] "ZADD" "aristotleWordCounts" "1" "act"
.... [0 127.0.0.1:50232] "ZADD" "aristotleWordCounts" "1" "thought"
.... [0 127.0.0.1:50232] "ZADD" "aristotleWordCounts" "2" "is"
.... [0 127.0.0.1:50232] "ZADD" "aristotleWordCounts" "1" "It"
.... [0 127.0.0.1:50232] "ZADD" "aristotleWordCounts" "1" "be"
.... [0 127.0.0.1:50232] "ZADD" "aristotleWordCounts" "2" "to"
.... [0 127.0.0.1:50232] "ZADD" "aristotleWordCounts" "1" "of"
.... [0 127.0.0.1:50232] "ZADD" "aristotleWordCounts" "1" "habit"
.... [0 127.0.0.1:50232] "ZADD" "aristotleWordCounts" "1" "not"
.... [0 127.0.0.1:50232] "ZADD" "aristotleWordCounts" "2" "a"
.... [0 127.0.0.1:50232] "ZADD" "aristotleWordCounts" "1" "without"
.... [0 127.0.0.1:50232] "ZADD" "aristotleWordCounts" "1" "the"
.... [0 127.0.0.1:50232] "ZADD" "aristotleWordCounts" "1" "mark"
.... [0 127.0.0.1:50232] "ZADD" "aristotleWordCounts" "1" "Excellence"
.... [0 127.0.0.1:50232] "ZADD" "aristotleWordCounts" "1" "We"
.... [0 127.0.0.1:50232] "ZADD" "aristotleWordCounts" "1" "we"
```

### Step 4: Manual edits to `amalg.cache`

The `amalg.cache` file was generated while tracing your main program while it was using remoting to work with a remote Redis server.

```sh
$ cat amalg.cache
return {
  [ "stuart-redis.RedisConfig" ] = "L",
  [ "stuart.class" ] = "L",
  [ "stuart-redis.RedisEndpoint" ] = "L",
  [ "stuart-redis" ] = "L",
  [ "stuart.Context" ] = "L",
  [ "moses" ] = "L",
  [ "stuart.RDD" ] = "L",
  [ "stuart.SparkConf" ] = "L",
  [ "stuart-redis.RedisRemoteContext" ] = "L",
  [ "stuart.Partition" ] = "L",
  [ "redis" ] = "L",
  [ "socket.core" ] = "C",
  [ "stuart.internal.logging" ] = "L",
  [ "stuart" ] = "L",
  [ "stuart-redis.RedisContext" ] = "L",
  [ "socket" ] = "L",
  [ "stuart.internal.Logger" ] = "L",
}
```

Now edit the file and replace `RedisRemoteContext` with `RedisEmbeddedContext`.

### Step 5: Amalgamate the Spark job with its dependencies

Merge main's LuaRocks dependencies into a single script, while excluding Stuart-Redis modules related to remoting.

```sh
$ amalg-redis.lua -s main.lua -o main-with-dependencies.lua -c -i "^redis$" -i "^socket" -i "RedisConfig$" -i "RedisEndpoint$"
```

### Step 6: Run it

```sh
$ redis-cli --eval main-with-dependencies.lua 0,0
```

If you are monitoring Redis this time, you'll notice that the same 29 ZADD commands were performed -- but this time they were all run within the context of a single Redis EVAL command.

`main.lua` is also available at [examples/embedding](../examples/embedding).

