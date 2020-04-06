return {
  index = {
    headers = function(request)
      if not request.headers then
        request.headers = ngx.req.get_headers()
      end
      return request.headers
    end,

    body = function(request)
      if not request.body_was_read then
        request.body_was_read = true
        ngx.req.read_body()
        request.body = ngx.req.get_body_data()
      end
      return request.body
    end,

    file = function(request)
      if not request.body_was_read then
        request.body_was_read = true
        ngx.req.read_body()
        local file = ngx.req.get_body_file()
        request.file = file
      end
      return request.file
    end,

    query = function(request)
      return ngx.req.get_uri_args()
    end,

    method = function(request)
      return request.method or ngx.req.get_method()
    end,

    params = function(request)
      if not request.post_was_read then
        request.post_was_read = true
        request.params = ngx.req.get_post_args()
      end
      return request.params
    end,

    uri = function(request)
      return request.url or ngx.var.uri
    end,

    host = function(request)
      return request.host or ngx.var.host
    end,

    port = function(request)
      return request.port or ngx.var.server_port
    end,

    scheme = function(request)
      return request.scheme or ngx.var.scheme
    end,

    url = function(request)
      return request.url or ngx.var.scheme..'://'..ngx.var.host..(ngx.var.server_port == '80' and '' or ':'..ngx.var.server_port)..ngx.var.uri
    end,

    queryString = function(request)
      return request.queryString or ngx.var.query_string
    end,

    sub = function(request)
      return ngx.location.capture
    end,
  },
  newindex = {
    method = function(request, value)
      --ngx.req.set_method(ngx['HTTP_'..value])
      request.method = value
    end,
    url = function(request, value)
      request.url = value
    end
  }
}
