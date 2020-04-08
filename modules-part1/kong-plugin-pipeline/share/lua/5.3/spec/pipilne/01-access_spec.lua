local helpers = require "spec.helpers"

local HTTP_PORT_1 = 50001
local HTTP_PORT_2 = 50002
local HTTP_PORT_3 = 50003

describe("Plugin: pipeline (access)", function()
    local client

    setup(function()
        helpers.run_migrations()

        local api1 = assert(helpers.dao.apis:insert{
          name="api",
          uris={"/test"},
          upstream_url="http://test.com"
        })

        local api2 = assert(helpers.dao.apis:insert{
          name="api-2",
          uris={"/test2"},
          upstream_url="http://test.com"
        })

        local upstream1 = assert(helpers.dao.upstreams:insert {
            name = "test.com",
        })
        assert(helpers.dao.targets:insert {
            target = "127.0.0.1:" .. HTTP_PORT_1,
            upstream_id = upstream1.id,
        })

        local upstream2 = assert(helpers.dao.upstreams:insert {
            name = "test.com2",
        })
        assert(helpers.dao.targets:insert {
            target = "127.0.0.1:" .. HTTP_PORT_2,
            upstream_id = upstream2.id,
        })

        local upstream3 = assert(helpers.dao.upstreams:insert {
          name = "test.com3",
        })
        assert(helpers.dao.targets:insert {
          target = "127.0.0.1:" .. HTTP_PORT_3,
          upstream_id = upstream3.id,
        })

        assert(helpers.dao.plugins:insert({
            api_id = api1.id,
            name = "pipeline",
        }))

        assert(helpers.start_kong({
          nginx_conf = "spec/fixtures/custom_nginx.template",
          custom_plugins = "pipeline"
        }))
        admin_client = helpers.admin_client()
    end)

    teardown(function()
        helpers.stop_kong()
    end)

    before_each(function()
        client = helpers.proxy_client()
    end)

    after_each(function()
        if client then client:close() end
    end)

    describe("enable plugin",function() 
        it("no hit plugin", function()
          local server1 = helpers.http_server(HTTP_PORT_1)
          
          local res = assert(client:send({
              method = "GET",
              path = "/test2",
              headers = {
                  host = "test2.com",
              },
          }))
          assert.res_status(200, res)

        end)

        it("hit plugin", function()
          local server2 = helpers.http_server(HTTP_PORT_2)
          local server3 = helpers.http_server(HTTP_PORT_3)

          local res = assert(client:send({
              method = "GET",
              path = "/test",
              headers = {
                  host = "test.com",
              },
          }))
          assert.res_status(502, res)

          local res2 = assert(client:send({
            method = "GET",
            path = "/test",
            headers = {
                host = "test2.com",
            },
          }))
          assert.res_status(200, res2)

          local res3 = assert(client:send({
            method = "GET",
            path = "/test",
            headers = {
                host = "test3.com",
            },
          }))
          assert.res_status(200, res3)
          
        end)

    end)
end)
