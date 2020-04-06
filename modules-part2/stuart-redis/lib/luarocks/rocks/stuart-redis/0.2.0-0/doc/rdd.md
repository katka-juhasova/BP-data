# RDD

* [The Redis Context](#the-redis-context)
* [Reading data](#reading-data)
* [Writing data](#writing-data)

## The Redis Context

Stuart-Redis provides a `RedisContext` class that extends Stuart's default Spark context class with functions specific to reading and writing RDDs with Redis.

An export function must be called, which rewrites the inheritance of a given Spark context so that it will now inherit from `RedisContext` and gain the new functions.

```lua
local stuart = require 'stuart'
local stuartRedis = require 'stuart-redis'

local sc = stuart.NewContext('local[1]', 'My Spark job')
sc = stuartRedis.export(sc)

local stringRDD = sc:fromRedisKV('keyPattern*')
...
```

## Reading data

Each Redis data type can be read to an RDD. The following snippet demonstrates reading Redis Strings.

### Strings

```lua
local stringRDD = sc:fromRedisKV('keyPattern*')
local stringRDD = sc:fromRedisKV({'foo', 'bar'})
```

Once run, `stringRDD` will contain the string values of all keys whose names are provided by keyPattern or key table.

### Hashes

```lua
local hashRDD = sc:fromRedisHash('keyPattern*')
local hashRDD = sc:fromRedisHash({'foo', 'bar'})
```

This will populate `hashRDD` with the fields and values of the Redis Hashes, the hashes' names are provided by keyPattern or key table.

### Lists

```lua
local listRDD = sc:fromRedisList('keyPattern*')
local listRDD = sc:fromRedisList({'foo', 'bar'})
```
The Redis List members whose names are provided by keyPattern or key table will be stored in `listRDD`.

### Sets

```lua
local setRDD = sc:fromRedisSet('keyPattern*')
local setRDD = sc:fromRedisSet({'foo', 'bar'})
```

The Redis Set members will be written to `setRDD`.

### Sorted Sets

Using `fromRedisZSet` will store in `zsetRDD` an RDD that consists of members, from the Redis Sorted Sets whose keys are provided by keyPattern or key table:

```lua
local zsetRDD = sc:fromRedisZSet('keyPattern*')
local zsetRDD = sc:fromRedisZSet({'foo', 'bar'})
```

Using `fromRedisZSetWithScore` will store in `zsetRDD` an RDD that consists of members and their scores, from the Redis Sorted Sets whose keys are provided by keyPattern or key table:

```lua
local zsetRDD = sc:fromRedisZSetWithScore('keyPattern*')
local zsetRDD = sc:fromRedisZSetWithScore({'foo', 'bar'})
```

Using `fromRedisZRange` will store in `zsetRDD` an RDD that consists of members and the members' ranges are within [startPos, endPos] of its own Sorted Set, from the Redis Sorted Sets whose keys are provided by keyPattern or key table:

```lua
local startPos, endPos = 3, 5
local zsetRDD = sc:fromRedisZRange('keyPattern*', startPos, endPos)
local zsetRDD = sc:fromRedisZRange({'foo', 'bar'}, startPos, endPos)
```

Using `fromRedisZRangeWithScore` will store in `zsetRDD` an RDD that consists of members and the members' ranges are within [startPos, endPos] of its own Sorted Set, from the Redis Sorted Sets whose keys are provided by keyPattern or key table:

```lua
local startPos, endPos = 3, 5
local zsetRDD = sc:fromRedisZRangeWithScore('keyPattern*', startPos, endPos)
local zsetRDD = sc:fromRedisZRangeWithScore({'foo', 'bar'}, startPos, endPos)
```

Using `fromRedisZRangeByScore` will store in `zsetRDD` an RDD that consists of members and the members' scores are within [min, max], from the Redis Sorted Sets whose keys are provided by keyPattern or key table:

```lua
local min, max = 52, 55
local zsetRDD = sc:fromRedisZRangeByScore('keyPattern*', min, max)
local zsetRDD = sc:fromRedisZRangeByScore({'foo', 'bar'}, min, max)
```

Using `fromRedisZRangeByScoreWithScore` will store in `zsetRDD` an RDD that consists of members and the members' scores are within [min, max], from the Redis Sorted Sets whose keys are provided by keyPattern or key table:

```lua
local min, max = 52, 55
local zsetRDD = sc:fromRedisZRangeByScoreWithScore('keyPattern*', min, max)
local zsetRDD = sc:fromRedisZRangeByScoreWithScore({'foo', 'bar'}, min, max)
```

## Writing data

To write data from Stuart to Redis, you'll need to prepare the appropriate RDD depending on the data type you want to use for storing the data in it.

### Strings

For String values, your RDD should consist of the key-value pairs that are to be written. Assuming that the strings RDD is called `stringRDD`, use the following snippet for writing it to Redis:

```lua
sc:toRedisKV(stringRDD)
```

### Hashes

To store a Redis Hash, the RDD should consist of its field-value pairs. If the RDD is called `hashRDD`, the following should be used for storing it in the key name specified by `hashName`:

```lua
sc:toRedisHASH(hashRDD, hashName)
```

### Lists

Use the following to store an RDD in a Redis List:

```lua
sc:toRedisLIST(listRDD, listName)
```

The `listRDD` is an RDD that contains all of the list's string elements in order, and `listName` is the list's key name.


### Sets

For storing data in a Redis Set, use `toRedisSET` as follows:

```lua
sc:toRedisSET(setRDD, setName)
```

Where `setRDD` is an RDD with the set's string elements and `setName` is the name of the key for that set.

### Sorted Sets

```lua
sc:toRedisZSET(zsetRDD, zsetName)
```

The above example demonstrates storing data in Redis in a Sorted Set. The `zsetRDD` in the example should contain pairs of members and their scores, whereas `zsetName` is the name for that key.
