return {
  fields = {
    allowed_payload_size_javascript = { default = 16, type = "number" },
    allowed_payload_size_json = { default = 16, type = "number" },
    allowed_payload_size_octet = { default = 128, type = "number" },
    allowed_payload_size_text = { default = 16, type = "number" },
    default_content_type = { default = "application/json", type = "string" }
  }
}
