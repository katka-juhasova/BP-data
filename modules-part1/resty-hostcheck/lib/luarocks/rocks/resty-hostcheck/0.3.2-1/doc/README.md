[![Build Status](https://travis-ci.org/niiknow/resty-hostcheck.svg?branch=master)](https://travis-ci.org/niiknow/resty-hostcheck)
# resty-hostcheck
> Host validation for openresty

# usage
Use in nginx host validation, such as/can be use-with [lua-resty-auto-ssl](https://github.com/GUI/lua-resty-auto-ssl)
```nginx
  # Initial setup tasks.
  init_by_lua_block {
    serverip = "1.2.3.4"
    auto_ssl = (require "resty.auto-ssl").new()
    hc = (require "resty.hostcheck")({ip = serverip, nameservers = {"8.8.8.8", {"8.8.4.4", 53} }})

    -- Define a function to determine which SNI domains to automatically handle
    -- and register new certificates for. Defaults to not allowing any domains,
    -- so this must be configured.
    auto_ssl:set("allow_domain", function(domain)
        -- use host checker here to determine if ip is correctly mapped
      	return hc(domain)
    end)

    auto_ssl:init()
  }
```

# build and test
osx, install lua, luarocks, and openresty:
```sh
make init
make test
```

# MIT
