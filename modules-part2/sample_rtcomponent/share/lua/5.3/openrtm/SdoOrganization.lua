---------------------------------
--! @file SdoOrganization.lua
--! @brief SDOオーガナイゼーション操作クラス定義
---------------------------------

--[[
Copyright (c) 2017 Nobuhiko Miyamoto
]]

local SdoOrganization= {}
local RTCUtil = require "openrtm.RTCUtil"
--_G["openrtm.SdoOrganization"] = SdoOrganization
local uuid = require "uuid"
local CORBA_SeqUtil = require "openrtm.CORBA_SeqUtil"
local oil = require "oil"



local nv_name = function(name)
	local obj = {}
	obj._name = name

	local call_func = function(self, nv)
		return (self._name == nv.name)
	end
	setmetatable(obj, {__call=call_func})
	return obj
end


local sdo_id = function(id_)
	local obj = {}
	obj._id = id_

	local call_func = function(self, sdo)
		local id_ = sdo:get_sdo_id()
		return (self._id == id_)
	end
	setmetatable(obj, {__call=call_func})
	return obj
end


Organization_impl.new = function(sdo)
	local obj = {}
	local Manager = require "openrtm.Manager"
	obj._manager = Manager:instance()
	obj._orb = obj._manager:getORB()
	

	obj._pId = str(uuid())

	obj._orgProperty = {properties={}}
	obj._varOwner = sdo
	obj._DependencyType = obj._orb.types:lookup("::SDOPackage::DependencyType").labelvalue
	obj._memberList  = {obj._DependencyType.OWN}
	obj.__rtcout = obj._manager:getLogbuf("rtobject")
	

	-- オブジェクトリファレンス生成
	function obj:createRef()
		self._svr = self._orb:newservant(self, nil, "IDL:org.omg/SDOPackage/Organization:1.0")
		self._objref = RTCUtil.getReference(self._orb, self._svr, "IDL:org.omg/SDOPackage/Organization:1.0")
	end

	function obj:get_organization_id()
    	self.__rtcout:RTC_TRACE("get_organization_id() = %s", self._pId)
		return self._pId
	end

	function obj:get_organization_property()
		self.__rtcout:RTC_TRACE("get_organization_property()")
		local prop = {properties = self._orgProperty.properties}
		return prop
	end


	function obj:get_organization_property_value(name)
		self.__rtcout:RTC_TRACE("get_organization_property_value(%s)", name)
		if name == "" then
			error(self._orb:newexcept{"SDOPackage::InvalidParameter",
				description="Empty name."
			})
		end
	
		local index = CORBA_SeqUtil.find(self._orgProperty.properties, nv_name(name))
	
		if index < 0 then
			error(self._orb:newexcept{"SDOPackage::InvalidParameter",
				description="Not found."
			})
		end

		return self._orgProperty.properties[index].value
	
	
	end

	function obj:add_organization_property(org_property)
		self.__rtcout:RTC_TRACE("add_organization_property()")
		if org_property == nil then
			error(self._orb:newexcept{"SDOPackage::InvalidParameter",
				description="org_property is Empty."
			})
		end
	
	
		
		self._orgProperty = org_property
		return true
	end

	function obj:set_organization_property_value(name, value)
		self.__rtcout:RTC_TRACE("set_organization_property_value(name=%s)", name)
		if name == "" then
			error(self._orb:newexcept{"SDOPackage::InvalidParameter",
					description="set_organization_property_value(): Enpty name."
			})
		end

    	local index = CORBA_SeqUtil.find(self._orgProperty.properties, nv_name(name))

    	if index < 0 then
    		local nv = SDOPackage.NameValue(name, value)
    		CORBA_SeqUtil.push_back_list(self._orgProperty.properties, nv)
		else
			self._orgProperty.properties[index].value = value
		end

		return true
	end

	function obj:remove_organization_property(name)
		self.__rtcout:RTC_TRACE("remove_organization_property(%s)", name)
		if name == "" then
			error(self._orb:newexcept{"SDOPackage::InvalidParameter",
					description="remove_organization_property_value(): Enpty name."
			})
		end

		local index = CORBA_SeqUtil.find(self._orgProperty.properties, nv_name(name))

		if index < 0 then
			error(self._orb:newexcept{"SDOPackage::InvalidParameter",
					description="remove_organization_property_value(): Not found."
			})
		end

		table.remove(self._orgProperty.properties, index)
    	
		return true
	end


	function obj:get_owner()
		self.__rtcout:RTC_TRACE("get_owner()")
		return self._varOwner
	end

	function obj:set_owner(sdo)
		self.__rtcout:RTC_TRACE("set_owner()")
		if sdo == oil.corba.idl.null then
			error(self._orb:newexcept{"SDOPackage::InvalidParameter",
				description="set_owner(): sdo is nil"
			})
		end
	
		self._varOwner = sdo

		return true
	end

	function obj:get_members(sdo)
		self.__rtcout:RTC_TRACE("get_members()")
		return self._memberList
	end

	function obj:set_members(sdo)
		self.__rtcout:RTC_TRACE("set_members()")
		if sdos == nil then
			error(self._orb:newexcept{"SDOPackage::InvalidParameter",
				description="set_members(): SDOList is empty."
			})
		end
	
	
		self._memberList = sdos
		return true
	end

	function obj:add_members(sdo_list)
		self.__rtcout:RTC_TRACE("add_members()")
		if #sdo_list == 0 then
			error(self._orb:newexcept{"SDOPackage::InvalidParameter",
				description="add_members(): SDOList is empty."
			})
			local success, exception = oil.pcall(
				function()
					CORBA_SeqUtil.push_back_list(self._memberList, sdo_list)
				end)
			if not success then
				self._rtcout:RTC_ERROR(exception)
				error(self._orb:newexcept{"SDOPackage::InternalError",
					description="add_members()"
				})
			else
				return true
			end
		end
	end


	function obj:add_members(id)
		self.__rtcout:RTC_TRACE("remove_member(%s)", id)
		if id == "" then
			self.__rtcout:RTC_ERROR("remove_member(): Enpty name.")
			error(self._orb:newexcept{"SDOPackage::InvalidParameter",
					description="remove_member(): Empty name."
			})
		end

    	local index = CORBA_SeqUtil.find(self._memberList, sdo_id(id))

		if index < 0 then
			self.__rtcout.RTC_ERROR("remove_member(): Not found.")
			error(self._orb:newexcept{"SDOPackage::InvalidParameter",
					description="remove_member(): Not found."
			})
		end
      

		table.remove(self._memberList, index)
    	return true
	end

	function obj:get_dependency()
		self.__rtcout:RTC_TRACE("get_dependency()")
    	return self._dependency
	end

	function obj:set_dependency(dependency)
		self.__rtcout:RTC_TRACE("set_dependency()")
		if dependency == nil then
			error(self._orb:newexcept{"SDOPackage::InvalidParameter",
				description="set_dependency(): Empty dependency."
			})
		end

    	self._dependency = dependency
    	return true
	end

	function obj:getObjRef()
		return self._objref
	end




	return obj
end


return SdoOrganization
