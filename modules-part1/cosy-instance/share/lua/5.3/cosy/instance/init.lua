local Mime    = require "mime"
local Et      = require "etlua"
local Hashids = require "hashids"
local Json    = require "cjson"
local Http    = require "cosy.instance.http"

local url = "https://cloud.docker.com"
local api = url .. "/api/app/v1/cosyverif"

local Instance = {}
Instance.__index = Instance

function Instance.create (config)
  config             = config             or {}
  config.mode        = config.mode        or "production"
  config.num_workers = config.num_workers or 1
  config.auth0       = config.auth0       or {
    domain        = assert (os.getenv "AUTH0_DOMAIN"),
    client_id     = assert (os.getenv "AUTH0_ID"    ),
    client_secret = assert (os.getenv "AUTH0_SECRET"),
    api_token     = assert (os.getenv "AUTH0_TOKEN" ),
  }
  config.docker      = config.docker      or {
    username      = assert (os.getenv "DOCKER_USER"  ),
    api_key       = assert (os.getenv "DOCKER_SECRET"),
  }
  config.branch      = config.branch      or (function ()
    local branch = assert (os.getenv "COSY_BRANCH" or os.getenv "WERCKER_GIT_BRANCH")
    if not branch or branch == "master" then
      local file = assert (io.popen ("git rev-parse --abbrev-ref HEAD", "r"))
      branch = assert (file:read "*line")
      file:close ()
    end
    return branch
  end) ()
  for _ = 1, 5 do
    local instance = setmetatable ({
      docker  = nil,
      server  = nil,
      headers = {
        ["Authorization"] = "Basic " .. Mime.b64 (config.docker.username .. ":" .. config.docker.api_key),
        ["Accept"       ] = "application/json",
        ["Content-type" ] = "application/json",
      }
    }, Instance)
    -- Create service:
    local id  = config.branch .. "-" .. Hashids.new (tostring (os.time ())):encode (666)
    local stack, stack_status = Http.json {
      url     = api .. "/stack/",
      method  = "POST",
      headers = instance.headers,
      body    = {
        name     = id,
        services = {
          { name  = "postgres",
            image = "postgres",
          },
          { name  = "redis",
            image = "redis:3.0.7",
          },
          { name  = "api",
            image = Et.render ("cosyverif/server:<%- branch %>", {
              branch = config.branch,
            }),
            ports = { "8080" },
            links = {
              "postgres",
              "redis",
            },
            environment = {
              NPROC             = config.num_workers,
              COSY_BRANCH       = config.branch,
              COSY_MODE         = config.mode,
              REDIS_PORT        = "tcp://redis:6379",
              POSTGRES_PORT     = "tcp://postgres:5432",
              POSTGRES_USER     = "postgres",
              POSTGRES_PASSWORD = "",
              POSTGRES_DATABASE = "postgres",
              AUTH0_DOMAIN      = config.auth0.domain,
              AUTH0_ID          = config.auth0.client_id,
              AUTH0_SECRET      = config.auth0.client_secret,
              AUTH0_TOKEN       = config.auth0.api_token,
              DOCKER_USER       = config.docker.username,
              DOCKER_SECRET     = config.docker.api_key,
            },
          },
        },
      },
    }
    assert (stack_status == 201)
    -- Start service:
    instance.docker = url .. stack.resource_uri
    local _, started_status = Http.json {
      url        = instance.docker .. "start/",
      method     = "POST",
      headers    = instance.headers,
      timeout    = 5, -- seconds
    }
    assert (started_status == 202, started_status)
    assert (instance:find_endpoint ())
    for _ = 1, 30 do
      local _, status = Http.json {
        url     = instance.server,
        method  = "GET",
      }
      if status == 200 then
        return instance
      else
        os.execute "sleep 1"
      end
    end
    -- cannot connect:
    instance:delete ()
  end
  assert (false)
end

function Instance.find_endpoint (instance)
  local services
  do
    local result, status
    while true do
      result, status = Http.json {
        url     = instance.docker,
        method  = "GET",
        headers = instance.headers,
      }
      if status == 200 and result.state:lower () ~= "starting" then
        services = result.services
        break
      else
        os.execute "sleep 1"
      end
    end
    assert (result.state:lower () == "running")
  end
  for _, path in ipairs (services) do
    local service, service_status = Http.json {
      url     = url .. path,
      method  = "GET",
      headers = instance.headers,
    }
    assert (service_status == 200)
    if service.name == "api" then
      local container, container_status = Http.json {
        url     = url .. service.containers [1],
        method  = "GET",
        headers = instance.headers,
      }
      assert (container_status == 200)
      for _, port in ipairs (container.container_ports) do
        local endpoint = port.endpoint_uri
        if endpoint and endpoint ~= Json.null then
          if endpoint:sub (-1) == "/" then
            endpoint = endpoint:sub (1, #endpoint-1)
          end
          instance.server = endpoint
          return instance.server
        end
      end
    end
  end
end

function Instance.delete (instance)
  while true do
    local _, deleted_status = Http.json {
      url     = instance.docker,
      method  = "DELETE",
      headers = instance.headers,
    }
    if deleted_status == 202 or deleted_status == 404 then
      break
    else
      os.execute "sleep 1"
    end
  end
end

return Instance
