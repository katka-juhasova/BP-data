# kong-jwt-claims-to-headers

![](https://travis-ci.org/cdimascio/kong-plugin-jwt-claims-to-headers.svg?branch=master)

A Kong plugin that extracts JWT claims and apply them to HTTP request headers.

<p align="center">
<img src="https://raw.githubusercontent.com/cdimascio/kong-plugin-jwt-claims-to-headers/master/assets/jwt-claims-to-headers-logo.png" width="400"/>
</p>

## Setup

### Install the plugin

```shell
luarocks install kong-plugin-jwt-claims-to-headers
```

Next, add the plugin to the `plugins` list in in `kong.conf` (for each Kong node):

```shell
plugins = bundled,jwt-claims-to-headers
```

- [Manual Install](#manual-install)
- [Uninstall](#uninstall)

## Usage

_coming soon..._

## Installation

The [setup](#setup) section describes the recommended installation method. The sub-sections below describe 1. manually installing the plugin, 2. validating the that the plugin was installed properly, and 3. uninstalling the plugin

### Manual install

```shell
# use lua package path or KONG LONG PACKAGE PATH
# e.g. lua_package_path = /</kong/plugins/jwt-claims-to-headers/?.lua;;
export KONG_LUA_PACKAGE_PATH=/kong/plugins/jwt-claims-to-headers/handler.lua?.lua;;

# edit the Kong configuration and modify the plugins directive to
plugins = bundled,jwt-claims-to-headers
```

### Validate the install

To verify the plugin loaded on Kong start, edit `kong.conf` and set `log_level` to `debug`.

```shell
# edit kong.conf and set
log_level = debug
```

Look for the following output:

```shell
[debug] Loading plugin jwt-clatims-to-headers
```

### Uninstall

```shell
luarocks remove  kong-plugin-jwt-claims-to-headers
```

## [Contributing](CONTRIBUTING.md)

If you would like to contribute to `kong-plugin-jwt-claims-to-headers`, go [here](CONTRIBUTING.md). We walk you through how to set up your developent environment.

### Contributors

- Tova [riley2012](https://github.com/riley2012)
- Carmine [cdimascio](https://github.com/cdimascio)

## License

[Apache 2.0](LICENSE)
