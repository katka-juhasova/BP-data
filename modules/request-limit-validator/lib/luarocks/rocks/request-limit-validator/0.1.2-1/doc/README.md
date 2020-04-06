# Kong Request Validator Plugin

## Synopsis

This plugin ensures that GET request parameters, and POST `application/x-www-form-urlencoded` parmaters do not exceed a maximum number of parameters (default 100).

## Setup

This plugin is available on [LuaRocks](http://luarocks.org/modules/darkdreamingdan/request-limit-validator).

To install, just set the following environmental variable:

`KONG_CUSTOM_PLUGINS=request-limit-validator`

Alternatively, install from LuaRocks with:

`luarocks install request-limit-validator`


## Config

You can use the Kong Dashboard to configure these parameters.

There are two config options to limit the GET and POST parameters:

- `allowed_number_query_args`: *Default 100*,
- `allowed_number_post_args`: *Default 100*,

Note, you should ensure these values match the values used in Kong `request-transformer` (default 100 in this plugin).  Otherwise, the `request-transformer` plugin will end up silently stripping arguments without failure.

## Expected Result

- `413` error if there are too many POST parameters (or `417` in a expect 100 request)
- `414` error if there are too many GET parameters (or `417` in a expect 100 request)