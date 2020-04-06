local BasePlugin = require "kong.plugins.base_plugin"
local access = require "kong.plugins.kong-oidc-auth-akshay.access"

local KongOidcAuth = BasePlugin:extend()

function KongOidcAuth:new()
	KongOidcAuth.super.new(self, "kong-oidc-auth-akshay")
end

function KongOidcAuth:access(conf)
	KongOidcAuth.super.access(self)
	access.run(conf)
end

KongOidcAuth.PRIORITY = 1000

return KongOidcAuth
