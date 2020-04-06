local helpers = require "spec.helpers"
local cjson = require "cjson"
local table = require "table"


describe("Plugin: key-secret (access)", function()
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
      name   = "key-secret",
      api_id = api2.id,
    })

    assert(helpers.start_kong({
      nginx_conf = "spec/fixtures/custom_nginx.template",
      custom_plugins = "key-secret"
    }))
    admin_client = helpers.admin_client()
  end)

  teardown(function()
    if admin_client then
      admin_client:close()
    end

    helpers.stop_kong()
  end)

  before_each(function()
    proxy_client = helpers.proxy_client()
  end)

  after_each(function()
    if proxy_client then
      proxy_client:close()
    end
  end)

  describe("key_secret", function()
    it("off", function()
      local res = assert(proxy_client:send{
        method = "GET",
        path = "/api-1",
      })

      local body = assert.res_status(200, res)
    end)

    it("on no sign", function()
      local res = assert(proxy_client:send{
        method = "GET",
        path = "/api-2",
      })

      local body = assert.res_status(403, res)
    end)

    it("on wrong sign", function()
      local param_table = {
        method = "get",
        ts = 100,
        app_key = 'abcd',
        app_secret = '1234',
      }
      local param_list = {}
      local params = ""
      for k, v in pairs(param_table) do
        table.insert(param_list, k .."=" .. v)
      end
      table.sort(param_list)

      local d = table.concat(param_list, "&")
      local sign = ngx.md5(d) .. "1"
      local res = assert(proxy_client:send{
        method = "GET",
        path = "/api-2?sign=" .. sign .. "&" .. d,
      })

      local body = assert.res_status(403, res)
    end)

    it("on success", function()
      local param_table = {
        method = "get",
        ts = 100,
        app_key = 'abcd',
        app_secret = '',
      }
      param_table["app_secret"] = ngx.md5(param_table["app_key"] .. "qianbao")
      local param_list = {}
      local params = ""
      for k, v in pairs(param_table) do
        table.insert(param_list, k .."=" .. v)
      end
      table.sort(param_list)

      local d = table.concat(param_list, "&")
      local sign = ngx.md5(d)
      local res = assert(proxy_client:send{
        method = "GET",
        path = "/api-2?sign=" .. sign .. "&" .. d,
      })

      local body = assert.res_status(200, res)
    end)

  end)

end)
