# Kong Response Size Limiting Plugin
## Overview
This plugin will protect the client from consuming API responses that are deemed too large within the Kong API Gateway.

1. Plugin enables Kong users to specify the size in MB that they will allow for API response sizes.

If transaction response is deemed too large the Gateway will throw an HTTP Status of 413 and a response body of "Response size limit exceeded" 

## Supported Kong Releases
Kong >= 1.0 

## Installation
Recommended:
```
$ luarocks install kong-response-size-limiting
```
Other:
```
$ git clone https://github.com/Optum/kong-response-size-limiting.git /path/to/kong/plugins/kong-response-size-limiting
$ cd /path/to/kong/plugins/kong-response-size-limiting
$ luarocks make *.rockspec
```
## Caveat

This plugin currently accomplishes limiting by validating the Content-Length header on API responses, if backend microservice is lacking such a standard header, then plugin will not response size limit. PRs for additional functionality welcome!

## Maintainers
[jeremyjpj0916](https://github.com/jeremyjpj0916)  
[rsbrisci](https://github.com/rsbrisci)

Special thanks to [thibaultcha](https://github.com/thibaultcha) and [james-callahan](https://github.com/james-callahan) with their
suggestions!

Feel free to open issues, or refer to our [Contribution Guidelines](https://github.com/Optum/kong-response-size-limiting/blob/master/CONTRIBUTING.md) if you have any questions.
