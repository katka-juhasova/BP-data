# kong-plugin-universal-jwt
Kong custom plugin for generating a JWT from some other auth method. It currently only applies to key auth plugin, but can be extended for others if required.

## Setting up development environment
Easiest way to setup is to run the kong vagrant VM (https://github.com/Kong/kong-vagrant)

```
git clone https://github.com/Kong/kong-vagrant
cd kong-vagrant
git clone https://github.com/localz/kong-plugin-universal-jwt
export KONG_PLUGIN_PATH=./kong-plugin-universal-jwt
vagrant up
vagrant ssh
cd /kong
export KONG_CUSTOM_PLUGINS=universal-jwt
```

Run the tests in Kong repo first (this does some sort of setup):
`bin/busted`

Then can run tests for the plugin:
`bin/busted /kong-plugin/spec`

## Publishing to luarocks

```
# Make sure your changes are merged into master, and then cut a new release. 
# Make sure the rockspec tag and version match your git tag
git checkout 1.0.0 # 1.0.0 is your version number

luarocks upload kong-plugin-universal-jwt-1.0.0-1.rockspec --api-key=KEY # You'll need to get an API key from luarocks
```
