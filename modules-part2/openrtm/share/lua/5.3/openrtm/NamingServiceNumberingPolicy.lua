---------------------------------
--! @file NamingServiceNumberingPolicy.lua
--! @brief ネームサーバーによる名前付けポリシー定義
---------------------------------

--[[
Copyright (c) 2017 Nobuhiko Miyamoto
]]

local NamingServiceNumberingPolicy= {}
--_G["openrtm.NamingServiceNumberingPolicy"] = NamingServiceNumberingPolicy

local Factory = require "openrtm.Factory"
local NumberingPolicy = require "openrtm.NumberingPolicy"
local NumberingPolicyBase = require "openrtm.NumberingPolicyBase"
local NumberingPolicyFactory = NumberingPolicyBase.NumberingPolicyFactory
local StringUtil = require "openrtm.StringUtil"

NamingServiceNumberingPolicy.new = function()
	local obj = {}
	setmetatable(obj, {__index=NumberingPolicy.new()})
	obj._objects = {}
	local Manager = require "openrtm.Manager"
	obj._mgr = Manager:instance()
	function obj:onCreate(_obj)
		local num = 0
   		while true do
      		local num_str = tostring(num)
      
			local name = _obj:getTypeName()..num_str
			
      		if not self:find(name) then
        		return num_str
      		else
				num = num+1
			end
		end
		return tostring(num)
	end
	function obj:onDelete(_obj)
	end

	function obj:find(name)
    	local rtcs = {}
		local rtc_name = "rtcname://*/*/"
    	rtc_name = rtc_name..name
   		local rtcs = self._mgr:getNaming():string_to_component(rtc_name)
    
    	if #rtcs > 0 then
    		return true
    	else
			return false
		end
	end
	
	return obj
end


NamingServiceNumberingPolicy.Init = function()
	NumberingPolicyFactory:instance():addFactory("ns_unique",
		NamingServiceNumberingPolicy.new,
		Factory.Delete)
end


return NamingServiceNumberingPolicy
