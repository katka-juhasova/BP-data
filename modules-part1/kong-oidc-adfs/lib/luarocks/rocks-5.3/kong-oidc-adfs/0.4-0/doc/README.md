# What is Kong OIDC ADFS
This is a fork of the Kong OIDC plugin by Nokia, which adds some extra functionality to help support ADFS. ADFS has some "quirks" that mean the original plugin does not work out of the box. 

Problems discovered when trying to use Kong OIDC with ADFS:
 - Custom claims are not passed through without specifying a non-OIDC-standard "resource" parameter to be the same as the relying party trust id. See `relying_party_trust_id`
 - Timing of JWT tokens can be out by a fair amount, resulting in errors such as "token is not valid yet".  Use the `slack` parameter below to solve this issue.
 - In the OIDC flow, if the user fails *authentication* (wrong username and password), they are stopped at the credentials entry screen presented by ADFS. However, if the user authenticates but is not *authorised* to view the particular resource, which could happen if, for example, the user does not belong to the correct group, then ADFS still authenticates them and passes them back to Kong requesting an error page. This can result in continuous redirects between Kong and ADFS, and so needs to be handled by the plugin. See `auth_error_filter`
 - ADFS does not implment the userinfo endpoint correctly. Instead, it passes custom claims through id_token. The userinfo endpoint appears hard-coded to only pass the "sub" claim. See `use_id_token_for_userinfo`

### Extra Parameters Added On Top Of Kong-OIDC

| Parameter | Default  | Required | description |
| --- | --- | --- | --- |
| `slack` | 120 | false | the amount of discrepancy allowed between timestamps in JWT tokens |
| `relying_party_trust_id` |  | false | the relying party trust id. This MUST be specified if you wish to receive custom claims |
| `use_id_token_for_userinfo` | false | false | should the plugin pass the claims in id_token in the X-Userinfo header |
| `auth_error_filter` |  | false | filters (regex) matched against the entire request URL that will force the plugin to report a 401 unauthorized |

### Installation
If using luarocks (like you should), this plugin has been published to the luarocks repository, and can be installed using:
```
luarocks install kong-oidc-adfs
```

Original README.MD from the kong-oidc plugin included below for convenience.

# What is Kong OIDC plugin

[![Join the chat at https://gitter.im/nokia/kong-oidc](https://badges.gitter.im/nokia/kong-oidc.svg)](https://gitter.im/nokia/kong-oidc?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

**Continuous Integration:** [![Build Status](https://travis-ci.org/nokia/kong-oidc.svg?branch=master)](https://travis-ci.org/nokia/kong-oidc) 
[![Coverage Status](https://coveralls.io/repos/github/nokia/kong-oidc/badge.svg?branch=master)](https://coveralls.io/github/nokia/kong-oidc?branch=master) <br/>

**kong-oidc** is a plugin for [Kong](https://github.com/Mashape/kong) implementing the
[OpenID Connect](http://openid.net/specs/openid-connect-core-1_0.html) Relying Party (RP) functionality.

It authenticates users against an OpenID Connect Provider using
[OpenID Connect Discovery](http://openid.net/specs/openid-connect-discovery-1_0.html)
and the Basic Client Profile (i.e. the Authorization Code flow).

It maintains sessions for authenticated users by leveraging `lua-resty-openidc` thus offering
a configurable choice between storing the session state in a client-side browser cookie or use
in of the server-side storage mechanisms `shared-memory|memcache|redis`.

It supports server-wide caching of resolved Discovery documents and validated Access Tokens.

It can be used as a reverse proxy terminating OAuth/OpenID Connect in front of an origin server so that
the origin server/services can be protected with the relevant standards without implementing those on
the server itself.

Introspection functionality add capability for already authenticated users and/or applications that
already posses acces token to go through kong. The actual token verification is then done by Resource Server.

## How does it work

The diagram below shows the message exchange between the involved parties.

![alt Kong OIDC flow](https://github.com/Trojan295/kong-oidc/raw/issue-15/docs/kong_oidc_flow.png)

The `X-Userinfo` header contains the payload from the Userinfo Endpoint

```
X-Userinfo: {"preferred_username":"alice","id":"60f65308-3510-40ca-83f0-e9c0151cc680","sub":"60f65308-3510-40ca-83f0-e9c0151cc680"}
```

The plugin also sets the `ngx.ctx.authenticated_consumer` variable, which can be using in other Kong plugins:
```
ngx.ctx.authenticated_consumer = {
    id = "60f65308-3510-40ca-83f0-e9c0151cc680",   -- sub field from Userinfo
    username = "alice"                             -- preferred_username from Userinfo
}
```


## Dependencies

**kong-oidc** depends on the following package:

- [`lua-resty-openidc`](https://github.com/pingidentity/lua-resty-openidc/)


## Installation

If you're using `luarocks` execute the following:

     luarocks install kong-oidc

You also need to set the `KONG_CUSTOM_PLUGINS` environment variable

     export KONG_CUSTOM_PLUGINS=oidc
     
## Usage

### Parameters

| Parameter | Default  | Required | description |
| --- | --- | --- | --- |
| `name` || true | plugin name, has to be `oidc` |
| `config.client_id` || true | OIDC Client ID |
| `config.client_secret` || true | OIDC Client secret |
| `config.discovery` | https://.well-known/openid-configuration | false | OIDC Discovery Endpoint (`/.well-known/openid-configuration`) |
| `config.scope` | oidc | false| OAuth2 Token scope. To use OIDC it has to contains the `oidc` scope |
| `config.ssl_verify` | false | false | Enable SSL verification to OIDC Provider |
| `config.session_secret` | | false | Additional parameter, which is used to encrypt the session cookie. Needs to be random |
| `config.introspection_endpoint` | | false | Token introspection endpoint |
| `config.bearer_only` | no | false | Only introspect tokens without redirecting |
| `config.realm` | kong | false | Realm used in WWW-Authenticate response header |
| `config.logout_path` | /logout | false | Absolute path used to logout from the OIDC RP |
| `config.http_proxy` || false | Http proxy url |
| `config.https_proxy` || false | https proxy url (only supports url format __http__://proxy and not __https__://proxy)

### Enabling

To enable the plugin only for one API:

```
POST /apis/<api_id>/plugins/ HTTP/1.1
Host: localhost:8001
Content-Type: application/x-www-form-urlencoded
Cache-Control: no-cache

name=oidc&config.client_id=kong-oidc&config.client_secret=29d98bf7-168c-4874-b8e9-9ba5e7382fa0&config.discovery=https%3A%2F%2F<oidc_provider>%2F.well-known%2Fopenid-configuration
```

To enable the plugin globally:
```
POST /apis HTTP/1.1
Host: localhost:8001
Content-Type: application/x-www-form-urlencoded
Cache-Control: no-cache

name=oidc&config.client_id=kong-oidc&config.client_secret=29d98bf7-168c-4874-b8e9-9ba5e7382fa0&config.discovery=https%3A%2F%2F<oidc_provider>%2F.well-known%2Fopenid-configuration
```

A successful response:
```
HTTP/1.1 201 Created
Date: Tue, 24 Oct 2017 19:37:38 GMT
Content-Type: application/json; charset=utf-8
Transfer-Encoding: chunked
Connection: keep-alive
Access-Control-Allow-Origin: *
Server: kong/0.11.0

{
    "created_at": 1508871239797,
    "config": {
        "response_type": "code",
        "client_id": "kong-oidc",
        "discovery": "https://<oidc_provider>/.well-known/openid-configuration",
        "scope": "openid",
        "ssl_verify": "no",
        "client_secret": "29d98bf7-168c-4874-b8e9-9ba5e7382fa0",
        "token_endpoint_auth_method": "client_secret_post"
    },
    "id": "58cc119b-e5d0-4908-8929-7d6ed73cb7de",
    "enabled": true,
    "name": "oidc",
    "api_id": "32625081-c712-4c46-b16a-5d6d9081f85f"
}
```

### Upstream API request

The plugin adds a additional `X-Userinfo` header to the upstream request, which can be consumer by upstream server. It contains Userinfo base64 encoded:

```
GET / HTTP/1.1
Host: netcat:9000
Connection: keep-alive
X-Forwarded-For: 172.19.0.1
X-Forwarded-Proto: http
X-Forwarded-Host: localhost
X-Forwarded-Port: 8000
X-Real-IP: 172.19.0.1
Cache-Control: max-age=0
User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/61.0.3163.100 Safari/537.36
Upgrade-Insecure-Requests: 1
Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8
Accept-Encoding: gzip, deflate
Accept-Language: pl-PL,pl;q=0.8,en-US;q=0.6,en;q=0.4
Cookie: session=KOn1am4mhQLKazlCA.....
X-Userinfo: eyJnaXZlbl9uYW1lIjoixITEmMWaw5PFgcW7xbnEhiIsInN1YiI6ImM4NThiYzAxLTBiM2ItNDQzNy1hMGVlLWE1ZTY0ODkwMDE5ZCIsInByZWZlcnJlZF91c2VybmFtZSI6ImFkbWluIiwibmFtZSI6IsSExJjFmsOTxYHFu8W5xIYiLCJ1c2VybmFtZSI6ImFkbWluIiwiaWQiOiJjODU4YmMwMS0wYjNiLTQ0MzctYTBlZS1hNWU2NDg5MDAxOWQifQ==
```


## Development

### Run CI locally

To run the CI locally you can use the following command:

```
docker run --rm -it -v `pwd`:/app --workdir=/app python bash ci/run.sh
```
