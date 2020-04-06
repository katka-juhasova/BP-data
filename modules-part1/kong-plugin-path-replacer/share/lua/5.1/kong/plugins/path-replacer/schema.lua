return {
  no_consumer = true,
  fields = {
    source_header = { type = "string", required = true },
    placeholder = { type = "string", required = true },
    log_only = { type = "boolean", default = false },
    darklaunch_url = { type = "string", default = "" }
  }
}
