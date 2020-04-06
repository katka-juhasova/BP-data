return {
  no_consumer = true,
  fields = {
    moocherio_endpoint = {type = "string", default = "http://api.moocher.io/badip/" },
    cache_entry_ttl = {type = "number", default = 60},
    moocherio_api_key =  {type = "string", default = "" }
  }
}