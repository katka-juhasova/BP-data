local helpers = require "spec.helpers"
local http = require "resty.http"


local HTTP_PORT_1 = 20001

describe("Plugin: token-agent (access)", function()

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
            upstream_url = helpers.mock_upstream_url,
        })

        assert(helpers.dao.plugins:insert {
            name   = "token-agent",
            config = {
                verify_url = "http://httpbin.org/anything",
                -- verify_url = "http://apis.qianbao.com/echo",

                -- verify_body_func(table)
                -- @param table {up="xx", uid="xx", sid="xx"}
                -- @return body string, nil where err
                verify_body_func = [[
                    return 
                        function(t)
                            local d = {}
                            for k, v in pairs(t) do
                                table.insert(d, k .. '=' .. v)
                            end
                            
                            return table.concat(d, '&')
                        end
                ]],
                -- verify_check_func(response)
                -- @param response the response of http, see lua-resty-http request_uri function
                -- @return true or false, nil where err
                verify_check_func = [[
                    local cjson = require "cjson"
                    return 
                        function(resp) 
                            if resp.status ~= 200 then 
                                return false 
                            end

                            body = cjson.decode(resp.body) 
                            if body.args.uid ~= "bbb" then
                                return false
                            end

                            return true
                        end
                ]],
            },
            api_id = api2.id,
        })

        assert(helpers.start_kong({
            nginx_conf = "spec/fixtures/custom_nginx.template",
            custom_plugins = "token-agent"
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
          local res = assert(client:send({
              method = "GET",
              path = "/api-1",
          }))
          assert.res_status(200, res)
        end)

        it("hit plugin, not auth", function()
          local res = assert(client:send({
              method = "GET",
              path = "/api-2",
              headers = {
                ["X-App-Name"] = "aaa",
                ["X-User-Id"] = "ccc",
                ["X-Access-Token"] = "ccc",
              },
          }))
          assert.res_status(401, res)
        end)

        it("hit plugin, auth", function()
            local res = assert(client:send({
                method = "GET",
                path = "/api-2",
                headers = {
                    ["X-App-Name"] = "aaa",
                    ["X-User-Id"] = "bbb",
                    ["X-Access-Token"] = "ccc",
                },
            }))
            print(res)
            assert.res_status(200, res)
        end)

    end)

end)
