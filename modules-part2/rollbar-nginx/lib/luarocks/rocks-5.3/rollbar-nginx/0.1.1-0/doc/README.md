# Rollbar Nginx Integration

This is a Rollbar integration written in Lua for the nginx web server.

This integration allows you to log issues that occur directly from your gateway.

# Why use an nginx plugin?

Instead of using a logging aggregator to find anomalies in your gateway, you
use this integration to send custom logs to Rollbar to more easily track and
organize issues within your backend.

```nginx
location /secret/api/ {
    content_by_lua_block {
        local rollbar = require("rollbar-nginx")
        rollbar.createMessageItem('Someone found the secret API')
    }
}
```

When a user makes a request to `/secret/api`, you can log it to Rollbar.

# Installation

Rollbar's nginx integration requires the use of [OpenResty](https://openresty.org/).
To use the nginx integration, make sure you have the following installed and
configured:

* [OpenResty](https://openresty.org/) - a distribution of the nginx web server that includes the lua plugin
* [Lua](https://www.lua.org/download.html) - the Lua programming language
* [Luarocks](https://github.com/keplerproject/luarocks/wiki/Download) - a Lua package manager

If you're new to OpenResty, the following tips will help you make sure you
configure Lua properly:

* When installing Lua, don't forget to `sudo make install` after building Lua
with `make linux test`
* You should add Luarocks modules to your lua path by running this command and
adding it to your `.bash_profile` file: `eval $(luarocks path --bin)`.
Otherwise, nginx will not detect your Luarocks modules.

With Luarocks, you can install the Rollbar nginx plugin with:

```shell
luarocks install rollbar-nginx --local
```

# Usage

If it's your first time using OpenResty, check out the
[Getting Started with OpenResty](https://openresty.org/en/getting-started.html)
guide on how to configure and run nginx.

The Rollbar plugin allows you to log pretty much anything by adding code in
the `content_by_lua_block` hooks exposed by OpenResty.

## Configuring the Rollbar API Key

As with any other nginx integration, the Rollbar nginx plugin reads environment
variables to find the Rollbar API key. Sign into your Rollbar account and find
the project key that has the `post_server_item` scope by running this and
adding to your `.bash_profile`:

```shell
export ROLLBAR_API_TOKEN=<Rollbar API token>
```

With nginx, you need to explicitly expose an environment variable to modules
in the configuration, so you need to add into the top level configuration:

```nginx
env ROLLBAR_API_TOKEN;
```

## Using the Rollbar message endpoint

You can send `message`-based items using the following:

```nginx
location = /admin/api/ {
    content_by_lua_block {
        local rollbar = require('rollbar-nginx')
        local fromIp = ngx.var.http_x_forwarded_for
        rollbar.createMessageItem(fromIp .. ' has accessed the admin API')
    }
}
```

Creating Rollbar message items will not break or exit execute unless you set
it to do so.
