[![Build Status](https://travis-ci.org/Kong/kong-plugin-uppercase-response.svg?branch=master)](https://travis-ci.com/Kong/kong-plugin-uppercase-response)

# Kong Uppercase Response plugin

This is a custom demo plugin for Kong. It uppercases the response body of any request.


## Status
Experimental

## Supported Kong Releases
Kong >= 1.0.x

## Installation

The preferred method is installing via luarocks:

```
luarocks install kong-plugin-uppercase-response
```

Alternatively, manually download and install:
```
$ git clone https://github.com/kong/kong-plugin-uppercase-response.git /path/to/kong/plugins/kong-plugin-uppercase-response
$ cd /path/to/kong/plugins/kong-plugin-uppercase-response
$ luarocks make *.rockspec
```

In both cases, you need to change your Kong [`plugins` configuration option](https://docs.konghq.com/1.3.x/configuration/#plugins)
to include this plugin:

```
plugins = bundled,uppercase-response
```

Or, if you don't want to activate any of the bundled plugins:

```
plugins = uppercase-response
```

Then reload kong:

```
kong reload
```

## Configuration

### Enabling on a Service

```bash
$ curl -X POST http://kong:8001/services/my-service/plugins \
    --data "name=uppercase-response"
```

### Parameters

| Form Parameter | default | description |
| ---            | ---     | ---         |
| `name`         |         | The name of the plugin to use, in this case `uppercase-response` |


## Quickstart

The following guidelines assume that `Kong` has been installed on your local machine:

1. Install `kong-plugin-uppercase-response` as specified in the "Installation" section above.

2. Add a mockbin service & route (you can demo this plugin with any service that returns a text response):

    ```
    curl -x post http://localhost:8001/services \
        --data "name=mockbin"
        --data "url=http://mockbin.org"
    ```

    ```
    curl -x post http://localhost:8001/services/mockbin/routes \
        --data "hosts[]=example.test"
    ```


3. Add `kong-plugin-uppercase-response` plugin to the Service:

    ```
    curl -X POST http://localhost:8001/services/mockbin/plugins \
        --data "name=uppercase-response" \
    ```

4. Make sample request using the Route associated to the Service:

    ```
    curl -X POST http://localhost:8000/request  \
        --header "Host: example.test" \
        --data "foo: bar"
    ```

5. The obtained response should be uppercased.
