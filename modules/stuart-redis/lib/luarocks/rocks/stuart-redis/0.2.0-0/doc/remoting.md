## Configuring connection to a remote Redis

Below is an example configuration of a Spark context with Redis configuration:

```lua
local SparkConf = require 'stuart.SparkConf'
local stuart = require 'stuart'

local conf = SparkConf.new()
  :setMaster('local[1]')
  :setAppName('My spark job')
  :set('spark.redis.host'   , 'localhost')
  :set('spark.redis.port'   , '6379')
  :set('spark.redis.auth'   , 'passwd')
  :set('spark.redis.db'     , '0')
  :set('spark.redis.timeout', '2')
local sc = stuart.NewContext(conf)
```

If you have a URL handy, a `RedisEndpoint` class can be used to configure the Spark context:

```lua
local RedisEndpoint = require 'stuart-redis.RedisEndpoint'
local SparkConf = require 'stuart.SparkConf'
local stuart = require 'stuart'

local redisEndpoint = RedisEndpoint.newFromURI(os.getenv('REDIS_URL'))
local conf = SparkConf.new()
  :setMaster('local[1]')
  :setAppName('My spark job')
  :set('spark.redis.host'   , redisEndpoint.host)
  :set('spark.redis.port'   , redisEndpoint.port)
  :set('spark.redis.db'     , redisEndpoint.dbNum)
  :set('spark.redis.timeout', redisEndpoint.timeout)
if redisEndpoint.auth then
  conf:set('spark.redis.auth', redisEndpoint.auth)
end
local sc = stuart.NewContext(conf)
```
