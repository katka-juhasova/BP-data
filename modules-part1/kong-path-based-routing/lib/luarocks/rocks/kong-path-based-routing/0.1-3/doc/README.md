# Kong Path-Based Routing
## Overview
This plugin will enable informing the hostname which Kong will route to based on elements in the request URI path. It allows for the concactination of both Regex' performed on the request URI path, and constants to form the routing hostname. 

Example:

kong-path-based-routing-plugin 'host_fields' args: 
```
[
  "$/api/service/(%S+)/",
  "$api/service/.*/v(%d+).",
  "$api/service/.*/v*..(%d+)",
  "-apitest.com"
]
```
on a request URI of https://kong-gateway/api/service/myapp/v1.0
to route with path: "/api"
would route to host:
myapp10-apitest.com/service/myapp/v1.0

The host given in the Service will not be used if this plugin is applied.

## Supported Kong Releases
Kong >= 0.13.x 

## Installation
Recommended:
```
$ luarocks install kong-path-based-routing
```

Optional
```
$ git clone https://github.com/Optum/kong-path-based-routing
$ cd /path/to/kong/plugins/kong-path-based-routing
$ luarocks make *.rockspec
```

## Configuration
The plugin requires that regex's/constants be concatinated in the parameter "host_fields" to inform the upstream hostname.
Strings given in the array begining with "$" will be treated as REGEX' to be applied to the URI path.

Feel free to open issues, or refer to our Contribution Guidelines if you have any questions.
