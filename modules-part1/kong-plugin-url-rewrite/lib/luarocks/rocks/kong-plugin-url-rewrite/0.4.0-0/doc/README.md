[![Build Status](https://travis-ci.org/stone-payments/kong-plugin-url-rewrite.svg?branch=master)](https://travis-ci.org/stone-payments/kong-plugin-url-rewrite)

# Kong-plugin-url-rewrite

Kong API Gateway plugin for url-rewrite purposes.

## The Problem

When using Kong, you can create routes that proxy to an upstream. The problem lies when the upstream has an url that is not very friendly to your clients, or restful, or even pretty. When you [add a Route in Kong](https://docs.konghq.com/0.14.x/admin-api/#add-route), you have a [somewhat limited](https://docs.konghq.com/0.14.x/proxy/#routes-and-matching-capabilities) url rewrite capability. This plugin simply throws away the url set in Kong route and uses the url set in it's configuration to proxy to the upstream. This gives you full freedom as to how to write your url's in Kong and inner services as well.

## Project Structure

The plugin folder should contain at least a `schema.lua` and a `handler.lua`, alongside with a `spec` folder and a `.rockspec` file specifying the current version of the package.

## Rockspec Format

The `.rockspec` file should follow [LuaRocks' conventions](https://github.com/luarocks/luarocks/wiki/Rockspec-format)

## Configuration

### Enabling the plugin on a Route

Configure this plugin on a Route with:

```bash
curl -X POST http://kong:8001/routes/{route_id}/plugins \
    --data "name=kong-plugin-url-rewrite"  \
    --data "config.url=http://new-url.com"
```

- route_id: the id of the Route that this plugin configuration will target.
- config.url: the url where you want kong to execute the request.

## Credits

made with :heart: by Stone Payments
