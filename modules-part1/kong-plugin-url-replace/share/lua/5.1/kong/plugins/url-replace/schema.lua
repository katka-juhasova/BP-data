return {
  no_consumer = true,
  fields = {
    search_string = {required = true, type = "string"},
    replace_string = {required = false, type = "string", default = ""}
  }
}
