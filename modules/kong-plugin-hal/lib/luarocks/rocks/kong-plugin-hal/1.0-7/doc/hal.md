---
id: page-plugin
title: Plugins - HAL
header_title: HAL
header_icon: /assets/images/icons/plugins/hal.png
breadcrumbs:
  Plugins: /plugins
nav:
  - label: Getting Started
  - label: Usage
    items:
      - label: Terminology
      - label: Configuration
---

The HAL plugin rewrites currie-values from hal/json bodies.

----

## Terminology

- `API`: your upstream service, for which Kong proxies requests to.
- `Plugin`: a plugin executes actions inside Kong during the request/response lifecycle.

----

## Configuration

Configuring the plugin is straightforward, you can add it on top of an [API][api-object] by executing the following request on your Kong server:

```bash
$ curl -X POST http://kong:8001/apis/{api}/plugins \
--data "name=hal"
```

`api`: The `id` or `name` of the API that this plugin configuration will target

form parameter            | required     | description
---                       | ---          | ---
`name`                    | *required*   | The name of the plugin to use, in this case: `hal`
----


