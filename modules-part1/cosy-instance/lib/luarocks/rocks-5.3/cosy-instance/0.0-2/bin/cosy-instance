#! /usr/bin/env lua

local Instance = require "cosy.instance"

local Config = {
  num_workers = assert (os.getenv "NPROC" or 1),
  auth0       = {
    domain        = assert (os.getenv "AUTH0_DOMAIN"),
    client_id     = assert (os.getenv "AUTH0_ID"    ),
    client_secret = assert (os.getenv "AUTH0_SECRET"),
    api_token     = assert (os.getenv "AUTH0_TOKEN" ),
  },
  docker      = {
    username = assert (os.getenv "DOCKER_USER"  ),
    api_key  = assert (os.getenv "DOCKER_SECRET"),
  },
}

local instance = Instance.create (Config)
print ("Server instantiated at:", instance.server)
