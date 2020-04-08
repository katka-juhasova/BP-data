# kong-plugin-gwa-ip-anonymity

A Kong plugin (current DataBC API Gateway) used for hide full or partial client IP to upstream services.

Change the X-Forwarded-For header so that the original client's IP address
last part is set to masked using the ipv4_mask or ipv6_mask values. For example 24.5.6.11
would become 24.5.6.0.  

NOTE: This version requires kong >= 0.12.x

## Installing

Follow these instructions to deploy the plugin to each Kong server in the cluster.

### Install the luarocks file

`luarocks install kong-plugin-gwa-ip-anonymity`

### Add the plugin to the kong configuration

Edit the kong.conf file 

```
custom_plugins = otherplugin,gwa-ip-anonymity
```

## Plugin Fields
The plugin accepts the following fields.

|Name     |Type  |Default |Description                                                        |
|---------|------|--------|-------------------------------------------------------------------|
|ipv4_mask|number|0       |The value (0-255) to mask the last part of an IPV4 address         |
|ipvd_mask|number|0       |The value (1-4 hex digits) to mask the last part of an IPV6 address|

# License

Copyright 2018 Province of British Columbia

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
