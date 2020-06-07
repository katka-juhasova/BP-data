---------------------------------
--! @file SdoServiceAdmin.lua
--! @brief SDOサービス管理クラス定義
---------------------------------

--[[
Copyright (c) 2017 Nobuhiko Miyamoto
]]

local SdoServiceAdmin= {}
local StringUtil = require "openrtm.StringUtil"
local SdoServiceProviderBase = require "openrtm.SdoServiceProviderBase"
local SdoServiceProviderFactory = SdoServiceProviderBase.SdoServiceProviderFactory
local StringUtil = require "openrtm.StringUtil"
local NVUtil = require "openrtm.NVUtil"
local SdoServiceConsumerBase = require "openrtm.SdoServiceConsumerBase"
local SdoServiceConsumerFactory = SdoServiceConsumerBase.SdoServiceConsumerFactory
local uuid = require "uuid"

--_G["openrtm.SdoServiceAdmin"] = SdoServiceAdmin


-- SDOサービス管理オブジェクト初期化
-- @param rtobj RTC
-- @return SDOサービス管理オブジェクト
SdoServiceAdmin.new = function(rtobj)
	local obj = {}
	obj._rtobj = rtobj
    obj._consumerTypes = {}
    obj._providers = {}
	obj._consumers = {}
	obj._allConsumerEnabled = false
	local Manager = require "openrtm.Manager"
	obj._manager = Manager:instance()
	
	obj._rtcout = obj._manager:getLogbuf("rtobject.sdo_config")
    -- 初期化時にRTC設定
    -- @param rtobj RTC
	function obj:init(rtobj)
		self._rtcout:RTC_TRACE("SdoServiceAdmin::SdoServiceAdmin(%s)",
		rtobj:getProperties():getProperty("instance_name"))

		local prop = self._rtobj:getProperties()

		local enabledProviderTypes = StringUtil.split(prop:getProperty("sdo.service.provider.enabled_services"),",")
		enabledProviderTypes = StringUtil.strip(enabledProviderTypes)
		
		self._rtcout:RTC_DEBUG("sdo.service.provider.enabled_services: %s", prop:getProperty("sdo.service.provider.enabled_services"))

		local availableProviderTypes = SdoServiceProviderFactory:instance():getIdentifiers()
		prop:setProperty("sdo.service.provider.available_services", tostring(StringUtil.flatten(availableProviderTypes)))
		self._rtcout:RTC_DEBUG("sdo.service.provider.available_services: %s", prop:getProperty("sdo.service.provider.available_services"))


		local activeProviderTypes = {}
		
		for i,ep_type in ipairs(enabledProviderTypes) do
			local tmp = string.lower(ep_type)
			
			if tmp == "all" then
				--print(tmp)
				activeProviderTypes = availableProviderTypes
				self._rtcout:RTC_DEBUG("sdo.service.provider.enabled_services: ALL")
				break
			end
			for j,ap_type in ipairs(availableProviderTypes) do
				if ap_type == ep_type then
					table.insert(activeProviderTypes, ap_type)
				end
			end
		end

		local factory = SdoServiceProviderFactory:instance()
		for i,ap_type in ipairs(activeProviderTypes) do
			local svc = factory:createObject(ap_type)
			local propkey = self:ifrToKey(ap_type)
			local properties = {}
			NVUtil.copyFromProperties(properties, prop:getNode(tostring(propkey)))
			local prof = {
				id = tostring(ap_type),
				interface_type = tostring(ap_type),
				properties = properties,
				service = svc._svr}
				
				

			if not svc:init(rtobj, prof) then
				svc:finalize()
			else
				table.insert(self._providers, svc)
			end
		end




		local constypes = prop:getProperty("sdo.service.consumer.enabled_services")

		
		self._consumerTypes = StringUtil.split(constypes,",")
		self._consumerTypes = StringUtil.strip(self._consumerTypes)
		self._rtcout:RTC_DEBUG("sdo.service.consumer.enabled_services: %s", tostring(constypes))

		prop:setProperty("sdo.service.consumer.available_services",
			tostring(StringUtil.flatten(SdoServiceConsumerFactory:instance():getIdentifiers())))
		self._rtcout:RTC_DEBUG("sdo.service.consumer.available_services: %s",
			prop:getProperty("sdo.service.consumer.available_services"))

		

		for i, ctype in ipairs(self._consumerTypes) do
			local tmp = string.lower(ctype)
			if tmp == "all" then
				self._allConsumerEnabled = true
				self._rtcout:RTC_DEBUG("sdo_service.consumer_types: ALL")
			end
		end
	end
	-- 終了処理
	function obj:exit()

		for i, provider in ipairs(self._providers) do
			provider:finalize()
		end

		self._providers = {}


		for i, consumer in ipairs(self._consumers) do
			consumer:finalize()
		end

		self._consumers = {}
	end
	
	function obj:getServiceProviderProfiles()
		local prof = {}
		for i,provider in ipairs(self._providers) do
			table.insert(prof, provider:getProfile())
		end
		return prof
	end

	function obj:getServiceProviderProfile(id)
		local idstr = id

		for i,provider in ipairs(self._providers) do
			if idstr == tostring(provider:getProfile().id) then
				return provider:getProfile()
			end
		end

		error(self._orb:newexcept{"SDOPackage::InvalidParameter",
				description=""
			})
	end

	function obj:getServiceProvider(id)
		local prof = self:getServiceProviderProfile(id)
    	return prof.service
	end

	function obj:addSdoServiceProvider(prof, provider)
		self._rtcout:RTC_TRACE("SdoServiceAdmin::addSdoServiceProvider(if=%s)",
                           prof.interface_type)
    	local id = prof.id
    	for i,provider in ipairs(self._providers) do
    		if id == tostring(provider:getProfile().id) then
    			self._rtcout:RTC_ERROR("SDO service(id=%s, ifr=%s) already exists",
							   tostring(prof.id), tostring(prof.interface_type))
				return false
			end
		end

		table.insert(self._providers, provider)
    	return true
	end

	function obj:removeSdoServiceProvider(id)
		self._rtcout:RTC_TRACE("removeSdoServiceProvider(%d)", id)
    
    	local strid = id
    	
		for i,provider in ipairs(self._providers) do
			if strid == tostring(provider:getProfile().id) then
        		provider:finalize()
        		local factory = SdoServiceProviderFactory:instance()
    			factory:deleteObject(self._providers[idx])
				table.remove(self._providers, i)
    			self._rtcout:RTC_INFO("SDO service provider has been deleted: %s", id)
				return true
			end
		end
   		self._rtcout:RTC_WARN("Specified SDO service provider not found: %s", id)
    	return false
	end

	function obj:addSdoServiceConsumer(sProfile)
		self._rtcout:RTC_TRACE("addSdoServiceConsumer(IFR = %s)",
                           sProfile.interface_type)
    	local profile = sProfile
    

    	if not self:isEnabledConsumerType(sProfile) then
    		self._rtcout:RTC_ERROR("Not supported consumer type. %s", profile.interface_type)
			return false
		end
  
    	if not self:isExistingConsumerType(sProfile) then
      		self._rtcout:RTC_ERROR("type %s not exists.", profile.interface_type)
			return false
		end
    	if tostring(profile.id) ==  "" then
    		self._rtcout:RTC_WARN("No id specified. It should be given by clients.")
			return false
		end


		local id = tostring(sProfile.id)
    	for i,consumer in ipairs(self._consumers) do
      		if id == tostring(self._consumers[i]:getProfile().id) then
        		self._rtcout:RTC_INFO("Existing consumer is reinitilized.")
        		self._rtcout:RTC_DEBUG("Propeteis are: %s",
                               NVUtil.toString(sProfile.properties))
				return consumer:reinit(sProfile)
			end
		end


    	local factory = SdoServiceConsumerFactory:instance()
    	local ctype = tostring(profile.interface_type)
    	local consumer = factory:createObject(ctype)


    	if not consumer:init(self._rtobj, sProfile) then
    		self._rtcout:RTC_WARN("SDO service initialization was failed.")
    		self._rtcout:RTC_DEBUG("id:         %s", tostring(sProfile.id))
    		self._rtcout:RTC_DEBUG("IFR:        %s", tostring(sProfile.interface_type))
    		self._rtcout:RTC_DEBUG("properties: %s", NVUtil.toString(sProfile.properties))
      		factory:deleteObject(consumer)
      		self._rtcout:RTC_INFO("SDO consumer was deleted by initialization failure")
			return false
		end


    	table.insert(self._consumers, consumer)

    	return true
	end

	function obj:removeSdoServiceConsumer(id)
		if id == "" then
			self._rtcout:RTC_ERROR("removeSdoServiceConsumer(): id is invalid.")
    		return false
		end
		self._rtcout:RTC_TRACE("removeSdoServiceConsumer(id = %s)", id)

    	local strid = id

		for idx,cons in ipairs(self._consumers) do
    		if strid == tostring(cons:getProfile().id) then
        		cons:finalize()
        		table.remove(self._consumers, idx)
    			local factory = SdoServiceConsumerFactory:instance()
        		factory:deleteObject(cons)
        		self._rtcout:RTC_INFO("SDO service has been deleted: %s", id)
				return true
			end
		end

    	self._rtcout:RTC_WARN("Specified SDO consumer not found: %s", id)
    	return false
	end

	function obj:isEnabledConsumerType(sProfile)
		if self._allConsumerEnabled then
			return true
		end

    	for i, consumer in ipairs(self._consumerTypes) do
    		if consumer == tostring(sProfile.interface_type) then
    			self._rtcout:RTC_DEBUG("%s is supported SDO service.",
							   tostring(sProfile.interface_type))
				return true
			end
		end

    	self._rtcout:RTC_WARN("Consumer type is not supported: %s",
                          tostring(sProfile.interface_type))
    	return false
	end

	function obj:isExistingConsumerType(sProfile)
		local factory = SdoServiceConsumerFactory:instance()
		local consumerTypes = factory:getIdentifiers()
		--print(#consumerTypes, sProfile.interface_type)
    	for i, consumer in ipairs(consumerTypes) do
    		if consumer == tostring(sProfile.interface_type) then
    			self._rtcout:RTC_DEBUG("%s exists in the SDO service factory.", tostring(sProfile.interface_type))
        		self._rtcout:RTC_PARANOID("Available SDO serices in the factory: %s", tostring(StringUtil.flatten(consumerTypes)))
				return true
			end
		end
    	self._rtcout:RTC_WARN("No available SDO service in the factory: %s",
                          tostring(sProfile.interface_type))
    	return false
	end

	function obj:getUUID()
		return uuid()
	end

	function obj:ifrToKey(ifr)
		local ifrvstr = StringUtil.split(ifr, ":")
		ifrvstr[2] = string.lower(ifrvstr[2])
		ifrvstr[2] = string.gsub(ifrvstr[2], "%.", "_")
		ifrvstr[2] = string.gsub(ifrvstr[2], "/", "%.")
    	return ifrvstr[2]
	end

	return obj
end


return SdoServiceAdmin
