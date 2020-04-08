return {
  no_consumer = true,
  fields = {
    method = { type = 'string' },
    url = { required = true, type = "string" },
    headers = { type = 'table', default = {} }
  }
}
