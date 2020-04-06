# oxd-web-lua
Lua library for oxd-web

# Installation
```$xslt
luarocks install oxd-web-lua
```

# Use

## 1. setup_client
```$xslt
    local oxd = require "oxdweb"
    
    local siteRequest = {
        oxd_host = "localhost:8553",
        scope = { "openid", "uma_protection" },
        op_host = conf.uma_server_host,
        authorization_redirect_uri = "https://client.example.com/cb",
        response_types = { "code" },
        client_name = "kong_uma_rs",
        grant_types = { "authorization_code" }
    }

    local response = oxd.setup_client(siteRequest)
```

