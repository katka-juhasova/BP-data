local cjson = require "cjson"
local helpers = require "spec.helpers"
local http = require "resty.http"


local X_PROXIED = "X-Kong-Proxied"

describe("Plugin:extend-headers (header-filters)", function()
    setup(function()
        helpers.run_migrations()

        local api1 = assert(helpers.dao.apis:insert {
            name         = "api-1",
            uris         = {"/api-1"},
            upstream_url = helpers.mock_upstream_url,
        })
      
        local api2 = assert(helpers.dao.apis:insert {
            name         = "api-2",
            uris         = {"/api-2"},
            upstream_url = "http://ttttt.com/anything",
        })

        assert(helpers.dao.plugins:insert {
            name   = "extend-headers",
            config = {},
        })

        assert(helpers.start_kong({
            nginx_conf = "spec/fixtures/custom_nginx.template",
            custom_plugins = "extend-headers"
          }))
          admin_client = helpers.admin_client()
    end)
    
    teardown(function()
        helpers.stop_kong()
    end)

    before_each(function()
        client = helpers.proxy_client(3000)
    end)

    after_each(function()
        if client then client:close() end
    end)

    -- describe("not enable plugin",function() 
    --     it("api 200", function()
    --         local res = assert(client:send({
    --             method = "GET",
    --             path = "/api-1",
    --         }))
    --         assert.response(res).has.status(200)
    --         assert.response(res).has_no.header(X_PROXIED)
    --     end)

    --     it("api 503", function()
    --         local res = assert(client:send({
    --             method = "GET",
    --             path = "/api-2",
    --         }))
    --         assert.response(res).has.status(503)
    --         assert.response(res).has_no.header(X_PROXIED)
    --     end)

    --     it("api 404", function()
    --         local res = assert(client:send({
    --             method = "GET",
    --             path = "/api-3",
    --         }))
    --         assert.response(res).has.status(404)
    --         assert.response(res).has_no.header(X_PROXIED)
    --     end)

    -- end)

    describe("enable plugin",function() 
        it("api 200", function()
            local res = assert(client:send({
                method = "GET",
                path = "/api-1",
            }))
            assert.response(res).has.status(200)
            local proxied = assert.response(res).has.header(X_PROXIED)
            assert.equal(proxied, "true")
        end)

        it("api 503", function()
            local res = assert(client:send({
                method = "GET",
                path = "/api-2",
            }))
            assert.response(res).has.status(503)
            local proxied = assert.response(res).has.header(X_PROXIED)
            assert.equal(proxied, "false")
        end)

        it("api 404", function()
            local res = assert(client:send({
                method = "GET",
                path = "/api-3",
            }))
            assert.response(res).has.status(404)
            local proxied = assert.response(res).has.header(X_PROXIED)
            assert.equal(proxied, "false")
        end)
    end)

end)
