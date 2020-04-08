# Kong JWT fetcher plugin


A Kong plugin that will fetch a JWT from a remote server and inject that JWT
into the request.

## Description

The plugin works in conjunction with existing authentication plugins. When a
consumer has been identified by the auth plugins, the JWT fetcher will use the
consumers `custom_id` field to fetch a JWT from a remote server (using an
http GET request).

The retrieved JWT will be cached by Kong based on the `exp` claim in the JWT.
And for the duration of the cached time Kong will no longer contact the remote
server.

The JWT will be injected into the request in the authorization header:

```
Authorization: Bearer <JWT token here>
```

NOTE: Kong will only pass the token on. So except for the `exp` claim Kong
will not introspect the JWT nor validate it.

## Installation

Install the rock when building your Kong image/instance:
```
luarocks install kong-plugin-jwt-fetcher
```

## Configuration

The plugin supports the following configuration options:

| name            | description                                                                                    | default                                                       |
| --------------- | ---------------------------------------------------------------------------------------------- | ---------- |
| `url`           | the url of the remote server to fetch the JWT from | - |
| `query_key`     | the query parameter to use to pass the `custom_id` on | `"username"` |
| `response_key`  | the key in the response body to use as the JWT token | `"access_token"` |
| `timout`        | timeout value (in milliseconds) to use when fetching the JWT from the remote server | `60000` |
| `keepalive`     | keepalive setting (in milliseconds) how long to keep connections unused in the keepalive pool | `60000` |
| `shm`           | the shared memory zone to use for storing the cached JWT, use a custom template to add one to the Kong configuration | `"jwtstore"` |
| `negative_ttl`  | the number of milliseconds to store negative responses from the remote server | `10000` |
| `skew`          | maximum clock skew to accept. The `exp` claim is extended with this value to prevent diverging system clocks from failing requests | `0` |


## Usage

Kong Session plugin can be configured globally or per entity (service, route, etc)
and is always used in conjunction with another Kong authentication [plugin]. This
plugin is NOT intended to work similarly to the [multiple authentication] setup.

For usage with [key-auth] plugin

1. ### Create an example Service and a Route

    Issue the following cURL request to create `example-service` pointing to
    mockbin.org, which will echo the request:

    ```bash
    $ curl -i -X POST \
      --url http://localhost:8001/services/ \
      --data 'name=example-service' \
      --data 'url=http://mockbin.org/request'
    ```

    Add a route to the Service:

    ```bash
    $ curl -i -X POST \
      --url http://localhost:8001/services/example-service/routes \
      --data 'paths[]=/jwt-test'
    ```

    The url `http://localhost:8000/jwt-test` will now echo whatever is being
    requested.

1. ### Configure the key-auth plugin for the Service

    Issue the following cURL request to add the key-auth plugin to the Service:

    ```bash
    $ curl -i -X POST \
      --url http://localhost:8001/services/example-service/plugins/ \
      --data 'name=key-auth'
    ```

1. ### Verify that the key-auth plugin is properly configured

    Issue the following cURL request to verify that the [key-auth][key-auth]
    plugin was properly configured on the Service:

    ```bash
    $ curl -i -X GET \
      --url http://localhost:8000/jwt-test
    ```

    Since the required header or parameter `apikey` was not specified, the
    response should be `401 Unauthorized`:

1. ### Create a Consumer

    Now create a consumer that will be accessing the test service, include the
    `custom_id` that will be passed to the backend JWT creator to generate
    a JWT for that ID.

    ```bash
    $ curl -i -X POST \
      --url http://localhost:8001/consumers/ \
      --data "username=fiona" \
      --data "custom_id=fiona@mydomain.com"
    ```

1. ### Provision key-auth credentials for your Consumer

    ```bash
    $ curl -i -X POST \
      --url http://localhost:8001/consumers/fiona/key-auth/ \
      --data 'key=open_sesame'
    ```

1. ### Add the Kong JWT-fetcher plugin to the service

    In the call below replace the `url` value with the one for your remote
    JWT creator service.

    ```bash
    $ curl -X POST http://localhost:8001/services/example-service/plugins \
        --data "name=jwt-fetcher"  \
        --data "config.url=http:/your-host:8080/and/path?optional=query-params" \
        --data "config.query_key=username" \
        --data "config.response_key=access_token" \
        --data "config.shm=kong_cache"
    ```

    _IMPORTANT_: the `shm` is set to "kong_cache" in the example, for simplicity
    but in production usage you should create your own shm! See
    [custom templates](https://docs.konghq.com/latest/configuration/#custom-nginx-templates)
    on how to create custom templates.

1. ### Verify that the JWT-fetcher plugin is properly configured

    ```bash
    $ curl -i -X GET \
      --url http://localhost:8000/jwt-test?apikey=open_sesame
    ```

    The response (which is an echo from the request that passed through Kong)
    should now have the `"Authorization"` header with a value `"Bearer <jwt>"`.

    If something didn't work as expected you can check the Kong logs for the
    error messages.


## Testing

To test the plugin use the kong-vagrant setup, clone the following repo's:

```
git clone http://github.com/kong/kong-vagrant.git
git clone http://github.com/kong/kong.git
git clone http://github.com/Tieske/kong-plugin-jwt-fetcher.git

cd kong-vagrant

# Kong 0.13.1 is the engine underlying Kong Enterprise 0.34-1
KONG_VERSION=0.13.1 KONG_PLUGIN_PATH=../kong-plugin-jwt-fetcher vagrant up

vagrant ssh
cd /kong

# setup test scaffolding for this version
git checkout 0.13.1
make dev

# linter (inside the Vagrant box the plugin lives in '/kong-plugin')
pushd /kong-plugin; luacheck .; popd

# tests
bin/busted /kong-plugin/spec -v -o gtest
```
