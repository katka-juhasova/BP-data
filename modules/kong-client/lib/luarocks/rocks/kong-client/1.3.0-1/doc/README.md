# KongClient

## Install
 - clone the git repo
 - add luarock api key to environment variables (LUAROCKS_API_KEY)

## Build local development environment

`make build`

## Start local development environment

`make up`

## Start local development environment

`make down`

## Restart local development environment

`make restart`

## Access local DB

`make db`

## Enter to the local development environment docker image shell

`make ssh`

## Running all tests from project folder:

`make test`

## Running all tests and generating coverage report:

`make coverage`

## Publish new release
 - rename rockspec file to the new version
 - change then version and source.tag in rockspec file
 - commit the changes
 - create a new tag (ex.: git tag 0.1.0)
 - push the changes with the tag (git push --tag)
 - `make publish`
