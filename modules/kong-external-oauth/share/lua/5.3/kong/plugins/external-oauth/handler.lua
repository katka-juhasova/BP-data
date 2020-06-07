
-- Copyright 2016 Niko Usai
-- Modifications Copyright (C) 2019 wanghaoyu@agora.io

--    Licensed under the Apache License, Version 2.0 (the "License");
--    you may not use this file except in compliance with the License.
--    You may obtain a copy of the License at

--        http://www.apache.org/licenses/LICENSE-2.0

--    Unless required by applicable law or agreed to in writing, software
--    distributed under the License is distributed on an "AS IS" BASIS,
--    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
--    See the License for the specific language governing permissions and
-- limitations under the License.

local BasePlugin = require "kong.plugins.base_plugin"
local access = require "kong.plugins.external-oauth.access"

local ExtOauthPlugin = BasePlugin:extend()

-- Lower priority for proper request ordering with other plugin
-- ref: https://docs.konghq.com/1.4.x/plugin-development/custom-logic/#plugins-execution-order
ExtOauthPlugin.PRIORITY = 966
ExtOauthPlugin.VERSION  = "1.3-0"

function ExtOauthPlugin:new()
	ExtOauthPlugin.super.new(self, "external-oauth")
end

function ExtOauthPlugin:access(conf)
	ExtOauthPlugin.super.access(self)
	access.run(conf)
end

return ExtOauthPlugin
