# kong-plugin-moocherio
Kong Plugin to restrict access based in the reputation and abuse lists of Moocher.io

## Dependencies

The plugin uses the module https://github.com/moocherio/lua-resty-shcache. It can be installed from luarocks as follows:

```
sudo luarocks install lua-resty-shcache
```

## Using Kong with your plugin

### 1. Build your plugin

```bash
$ make install-dev
```

This command installs your plugin locally to a `./lua_modules` directory. The PATH to modules installed in this folder will then be something like:

```bash
/some/path/to/kong-plugin-moocherio/lua_modules/share/lua/5.1/?.lua
```

> Under the hood make is just executing `luarocks` to install the rock locally. It needs to be installed in order to expand it to the directory structure that corresponds to the module names (i.e. kong.plugins.moocherio.handler => kong/plugins/moocherio/)
Go [here](https://github.com/keplerproject/luarocks/wiki/Documentation) for more luarocks information.

Armed with this information we can use it to tell Kong that we want to load a custom_plugin and where to look for it.

### 2. Tell Kong to start with your plugin


- <strong>Option 1</strong>

  Start Kong with your plugin(s) defined in the `KONG_CUSTOM_PLUGINS` [environment variable]((https://getkong.org/docs/0.9.x/configuration/#environment-variables).

  ```bash
  $ KONG_CUSTOM_PLUGINS='moocherio' \
    KONG_LUA_PACKAGE_PATH=/path/to/your/plugin/?.lua \
    bin/kong start -vv
  ```

  > NOTE: If you apply your plugin to any apis or consumers then your plugin must be included in any subsequent startup or Kong with fail to start.

- <strong>Option 2</strong>

  Update the `custom_plugins` and `lua_package_path` items in the Kong [configuration file](https://getkong.org/docs/latest/configuration/).

  ```
  custom_plugins = moocherio

  ...

  lua_package_path = /path/to/your/plugin/?.lua
  ```

> You can use any combination of the two methods above. Please refer to the configuration [documentation](kong-docs-config).

## Configure the plugin

The plugin needs three config parameters to work:

* moocherio_endpoint: Endpoint of the moocherio service. By default http://api.moocher.io/badip
* cache_entry_ttl: TTL of the local cache values. By default 60
* moocherio_api_key: API Key of the moocher.io service for registered users. By default empty, meaning that the plugin will use the default public blacklists.

These three config parameters can be managed with the schema management capabilities of the Admin API: https://getkong.org/docs/0.9.x/admin-api/#update-plugin

# User Feedback

## Issues

If you have any problems with or questions about this image, please contact us through a [GitHub issue][github-new-issue].

## Contributing

You are invited to contribute new features, fixes, or updates, large or small; we are always thrilled to receive pull requests, and do our best to process them as fast as we can.

Before you start to code, we recommend discussing your plans through a [GitHub issue][github-new-issue], especially for more ambitious contributions. This gives other contributors a chance to point you in the right direction, give you feedback on your design, and help you find out if someone else is working on the same thing.

[moocherio-site-url]: https://moocher.io
[moocherio-docs-url]: https://moocher.io/docs/index.html
[phusion-site-url]: http://phusion.github.io/baseimage-docker/
[openresty-site-url]: https://openresty.org
[lua-site-url]: https://www.lua.org

[github-new-issue]: https://github.com/moocherio/kong-plugin-moocherio/issues/new/