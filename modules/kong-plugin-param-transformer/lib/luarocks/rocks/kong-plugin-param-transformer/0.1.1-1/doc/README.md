# param-transformer

I can transfor param into upstream.

1. add api

```
curl -i -X POST \
  --url http://localhost:8001/apis/ \
  --data 'name=example-api' \
  --data 'uris=/test/(?<p1>\S+)' \
  --data 'upstream_url=http://mockbin.com/request/{{p1}}'
```

1. enabling plugin

```
curl -i -X POST \
  --url http://localhost:8001/apis/example-api/plugins/ \
  --data 'name=param-transformer'
```

1. query api

```
curl 'http://localhost:8000/test/123'

kong will request http://mockbin.com/request/123

response
{
  "startedDateTime": "2017-12-13T09:48:56.000Z",
  "clientIPAddress": "10.0.2.2",
  "method": "GET",
  "url": "http://localhost/request/123",
  "httpVersion": "HTTP/1.1",
  "cookies": {},
  "headers": {
    "host": "mockbin.com",
    "connection": "close",
    "accept-encoding": "gzip",
    "x-forwarded-for": "10.0.2.2,111.200.62.30, 173.245.48.85",
    "cf-ray": "3cc802b155ca13c5-LAX",
    "x-forwarded-proto": "http",
    "cf-visitor": "{\"scheme\":\"http\"}",
    "x-forwarded-host": "localhost",
    "x-forwarded-port": "80",
    "user-agent": "curl/7.54.0",
    "accept": "*/*",
    "cf-connecting-ip": "111.200.62.30",
    "x-request-id": "2efe5cc9-9f86-41eb-9d5f-b37f87e50c6a",
    "via": "1.1 vegur",
    "connect-time": "0",
    "x-request-start": "1513158535998",
    "total-route-time": "0"
  },
  "queryString": {},
  "postData": {
    "mimeType": "application/octet-stream",
    "text": "",
    "params": []
  },
  "headersSize": 508,
  "bodySize": 0
* Connection #0 to host localhost left intact
}
```
