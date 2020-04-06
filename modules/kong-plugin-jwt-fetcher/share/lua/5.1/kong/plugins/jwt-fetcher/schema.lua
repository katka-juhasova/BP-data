local typedefs = require "kong.db.schema.typedefs"


return {
  name = "jwt-fetcher",
  fields = {
    { consumer = typedefs.no_consumer },
    { protocols = typedefs.protocols_http },
    { config = {
        type = "record",
        fields = {
          -- URL of remote server where to fetch the JWT
          -- Can use HTTP/HTTPS
          { url = { type = "string", required = true }, },

          -- the query key/name in which to store the custom id send to the
          -- remote server
          { query_key = { type = "string", default = "username", required = true }, },

          -- the key, in the JSON body response that contains the JWT. Assumes the
          -- body to be a JSON object. If not provided, it will assume the JWT
          -- in a top-level JSON string value
          { response_key = { type = "string", default = "access_token" }, },

          -- timeout when making the http request to fetch the JWT (in ms)
          { timeout = { type = "integer", default = 60000, required = true }, },

          -- connection keepalive (in ms)
          { keepalive = { type = "integer", default = 60000, required = true }, },

          -- the shm to use as node level cache
          { shm = { type = "string", default = "jwtstore", required = true }, },

          -- if a JWT is not on the remote server, how long to cache that fact
          -- (in ms)
          { negative_ttl = { type = "integer", default = 10000, required = true }, },

          -- Max clock skew to compensate ('exp' claim is extended with
          -- this) in seconds
          { skew = { type = "integer", default = 0, required = true }, },
        },
    }, },
  },
}
