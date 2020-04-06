# Kong Plugins "rndplugin"
### kong plugin to check request token authorization and forward request to filter payload(by security-matrix) written in lua

to install this plugin on kong, you can create new images with Dockerfile:
```
FROM kong:1.3.0-centos

RUN yum install -y git unzip && yum clean all

RUN luarocks install rndplugin
```


 to add the plugin:
```
curl -X POST http://kong:8001/services/{service-name}/plugins \
--data "name=rndplugin" \
--data "config.securityMatrixPath=http://securitymatrixhost:port/path/to/filter" \
--data "config.checkAuthPath=http://securitymatrixhost:port/path/to/check"
```

 `securityMatrixPath` parameter is a endpoint path to filter the payload. It will forward the original responses from services to security matrix using POST request method. you can use the additional header "Service-Path" added by the plugin to identify the request origin.

 `checkAuthPath` parameter is a endpont path to check the token authorization. It will do the GET request to the "check" endpoint and carrying the request token. if the token not authorized, it will return 401 (not-authorized) error early and won't forward the request to the backend services(and security matrix filter).
