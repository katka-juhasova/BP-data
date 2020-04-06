# Kong datadog plugin with extended tags usage

This repository contains a slightly modified version of the datadog plugin from
Kong core. This version sends API name, API URIs and status codes in tags
instead of interpolated in the metric name. Having variable information in the
tags is more convenient in datadog as it allows aggregating metrics from
multiple APIs.

## Development

Follow the guidelines in [kong-vagrant](https://github.com/Kong/kong-vagrant).
Clone this repository into `kong-vagrant` directory with the name `kong-plugin`
and run `vagrant up`.

### Running tests

SSH into vagrant machine `vagrant ssh`.
Then
```bash
cd /kong-plugin
/kong/bin/busted
```

### Releasing

Update version in rockspec and rockspec filename. Execute `luarocks upload _plugin_and_version.rockspec`.

Push new docker image with new plugin version, e.g:

```bash
docker build -t salemove/kong:0.11-alpine-datadog-plugin-0.2.1 -f kong-salemove.Dockerfile .
docker push salemove/kong:0.11-alpine-datadog-plugin-0.2.1
```
