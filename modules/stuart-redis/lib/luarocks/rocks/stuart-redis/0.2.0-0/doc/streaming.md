# Streaming

Stuart-Redis supports streaming data from the following Redis data structures:

* Redis Pub/Sub

## Redis Pub/Sub

If you have a Spark Streaming based loop that would like to ingest data from a Redis Pub/Sub channel, use the `PubSubReceiver` class:

```lua
local stuart = require 'stuart'
local PubSubReceiver = require 'stuart-redis.streaming.PubSubReceiver'

local sc = stuart.NewContext()
local ssc = stuart.NewStreamingContext(sc, 1.5)

local receiver = PubSubReceiver.new(ssc, {'mychannel'})
local dstream = ssc:receiverStream(receiver)
dstream:foreachRDD(function(rdd)
  print('Received RDD: ' .. table.concat(rdd:collect(), ','))
end)
ssc:start()
ssc:awaitTermination()
ssc:stop()
```

Run the sample Spark Streaming loop:

```sh
$ cd examples/streaming
$ REDIS_URL=redis://127.0.0.1:6379/mychannel lua PubSubReceiver.lua
```

And then feed the Spark ingest engine by publishing to Redis. The default batch size is 1.5 seconds, which gives you enough time to publish two messages into the same RDD:

```sh
$ redis-cli
127.0.0.1:6379> publish mychannel one
127.0.0.1:6379> publish mychannel two
127.0.0.1:6379> publish mychannel three
```

The Spark Streaming loop will report:

```	
$ lua PubSubReceiver.lua
INFO Running Stuart (Embedded Spark 2.2.0)
INFO Connected to redis://127.0.0.1:6379
INFO Subscribed to channel mychannel
Received RDD: one
Received RDD: two,three
```

The full example is in the [examples/streaming](../examples/streaming/) folder.
