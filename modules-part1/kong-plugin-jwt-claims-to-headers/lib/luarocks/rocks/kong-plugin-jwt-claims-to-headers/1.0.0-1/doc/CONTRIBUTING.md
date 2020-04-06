# Contributing: kong-jwt-claims-to-headers

## Prerequisites

1. Install Vagrant (and VirtualBox)

## Development Environment Setup

The instructions below are a trimmed down variant of [kong-vagrant](https://github.com/Kong/kong-vagrant/) that targets kong-plugin-jwt-claims-to-headers. If you run into issue, please visit [kong-vagrant](https://github.com/Kong/kong-vagrant/) first.

Comments annotated with `***` denote a difference from [kong-vagrant](https://github.com/Kong/kong-vagrant/)

### Preparing the development environment

Once you have Vagrant installed, follow these steps to set up a development
environment for both Kong itself as well as for custom plugins. It will
install the development dependencies like the `busted` test framework.

```shell
# clone this repository
$ git clone https://github.com/Kong/kong-vagrant
$ cd kong-vagrant

# clone the Kong repo (inside the vagrant one)
$ git clone https://github.com/Kong/kong

# *** clone kong-plugin-jwt-claims-plugin to kong-plugin
# if you choose to place kong-plugin-jwt-claims into a different directory, set KONG_PLUGIN_PATH to that directory
$ git clone https://github.com/openwares/kong-plugin-jwt-claims-to-headers kong-plugin

# build a box with a folder synced to your local Kong and plugin sources
$ vagrant up

# ssh into the Vagrant machine, and setup the dev environment
$ vagrant ssh

$ cd /kong
$ make dev

# *** enable jwt-claims-to-headers plugin
$ export KONG_PLUGINS=bundled,jwt-claims-to-headers

# startup kong: while inside '/kong' call `kong` from the repo as `bin/kong`!
# we will also need to ensure that migrations are up to date
$ cd /kong
```

This will tell Vagrant to mount your local Kong repository under the guest's
`/kong` folder, and the 'kong-plugin-jwt-claims-to-headers' repository under the
guest's `/kong-plugin` folder.

### Run the tests

```shell
# ssh into the Vagrant machine
$ vagrant ssh

# start the linter from the plugin repository
$ cd /kong-plugin
$ luacheck .

# testing: while inside '/kong' call `busted` from the repo as `bin/busted`,
# but specify the plugin testsuite to be executed
$ cd /kong
$ bin/busted /kong-plugin/spec
```

# Develop

Write code and submit a PR

In the `kong-plugin` folder:

- Source code: `kong/plugins/jwt-claims-to-headers`
- Tests: `spec/jwt-claims-to-headers`

## Build

From the `kong-plugin` (kong-plugin-jwt-claims-to-headers) folder:

```shell
luarocks make
```

### Package

From the `kong-plugin` (kong-plugin-jwt-claims-to-headers) folder:

Create the lua rock and upload

```shell
luarocks pack kong-plugin-jwt-claims-to-headers-${VERSION}.rockspec
luarocks upload kong-plugin-jwt-claims-to-headers-${VERSION}.rockspec --api-key=${LUAROCKS_API_KEY}
```

or binary rock

```shell
luarocks make --pack-binary-rock
``
### Install

From the `kong-plugin` (kong-plugin-jwt-claims-to-headers) folder:

Install your newly generated rock

```shell
luarocks install kong-plugin-jwt-claims-to-headers-1.0.0-1.all.rock
```

Add the plugin’s name to the plugins list in your Kong configuration (on each Kong node):

```shell
plugins = bundled,jwt-claims-to-headers
```
