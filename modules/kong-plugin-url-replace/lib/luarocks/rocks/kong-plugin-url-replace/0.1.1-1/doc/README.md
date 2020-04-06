[![Build Status](https://travis-ci.org/torresmat/kong-plugin-url-replace.svg?branch=master)](https://travis-ci.org/torresmat/kong-plugin-url-replace)

# kong-plugin-url-replace

KongAPI Gateway middleware plugin for replacing patterns with strings in REQUEST PATH (string.gsub).

## Project Structure

The plugin folder should contain at least a `schema.lua` and a `handler.lua`, alongside with a `spec` folder and a `.rockspec` file specifying the current version of the package.

## Rockspec Format

The `.rockspec` file should follow [LuaRocks' conventions](https://github.com/luarocks/luarocks/wiki/Rockspec-format)

## Configuration

### Enabling the plugin on a Route

Configure this plugin on a Route with:

```bash
curl -X POST http://kong:8001/routes/{route_id}/plugins \
    --data "name=url-replace"  \
    --data "config.search_string=public/v1/method" \
    --data "config.replace_string=public/method"
```

- route_id: the id of the Route that this plugin configuration will target.
- config.search_string: string to be replaced
- config.replace_string: replacement string

## Credits

made by Matías Torres using Stone Payments url-rewrite plugin as template.
