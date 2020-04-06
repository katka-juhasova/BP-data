# kong-plugin-rule-based-header-transformer

## Install
 - clone the git repo
 - add luarock api key to environment variables (LUAROCKS_API_KEY)

## Usage

### Create plugin
```
POST admin/plugins {
    service_id = service.id,
    name = "rule-based-header-transformer",
    config = {
        rules = {
            {
                output_header = "X-Output-Header",
                uri_matchers = { "/test-api/(.-)/" },
                input_headers = { "X-Input-Header" },
                input_query_parameter = "query_parameter"
            }
        }
    }
}
```

### Uri based
#### Before
```
> GET /test-api/123456/ HTTP/1.1
> Host: dev.local
```

#### After
```
> GET /test-api/123456/ HTTP/1.1
> Host: dev.local
> X-Output-Header: 123456
```

### Query parameter based
#### Before
```
> GET /?query_parameter=123456 HTTP/1.1
> Host: dev.local
```

#### After
```
> GET /?query_parameter=123456 HTTP/1.1
> Host: dev.local
> X-Output-Header: 123456
```

### Header based
#### Before
```
> GET / HTTP/1.1
> Host: dev.local
> X-Input-Header: 123456
```

#### After
```
> GET / HTTP/1.1
> Host: dev.local
> X-Input-Header: 123456
> X-Output-Header: 123456
```


## Build local development environment

`make build`

## Start local development environment

`make up`

## Start local development environment

`make down`

## Restart local development environment

`make restart`

## Setup initially local development environment

`make dev-env`

## Access local DB

- `make db`

## Enter to the local development environment docker image shell

- `make ssh`

## Running all tests from project folder:

`make test`

## Running unit tests from project folder:

`make unit`

## Running end to end tests from project folder:

`make e2e`

## Publish new release
 - rename rockspec file to the new version
 - change then version and source.tag in rockspec file
 - commit the changes
 - create a new tag (ex.: git tag 0.1.0)
 - push the changes with the tag (git push --tag)
 - `make publish`
