---------------------------------
--! @file ManagerActionListener.lua
--! @brief マネージャアクションコールバックの定義
---------------------------------

--[[
Copyright (c) 2017 Nobuhiko Miyamoto
]]

local ManagerActionListener= {}
--_G["openrtm.ManagerActionListener"] = ManagerActionListener


local ListenerHolder = require "openrtm.ListenerHolder"


ManagerActionListener.ManagerActionListener = {}
ManagerActionListener.ManagerActionListener.new = function()
	local obj = {}
	function obj:preShutdown()
	end
	function obj:postShutdown()
	end
	function obj:preReinit()
	end
	function obj:postReinit()
	end

	return obj
end


ManagerActionListener.ModuleActionListener = {}
ManagerActionListener.ModuleActionListener.new = function()
	local obj = {}
	function obj:preLoad(modname, funcname)
	end
	function obj:postLoad(modname, funcname)
	end
	function obj:preUnload(modname)
	end
	function obj:postUnload(modname)
	end

	return obj
end




ManagerActionListener.RtcLifecycleActionListener = {}
ManagerActionListener.RtcLifecycleActionListener.new = function()
	local obj = {}
	function obj:preCreate(args)
	end
	function obj:postCreate(rtobj)
	end
	function obj:preConfigure(prop)
	end
	function obj:postConfigure(prop)
	end
	function obj:preInitialize()
	end
	function obj:postInitialize()
	end

	return obj
end




ManagerActionListener.NamingActionListener = {}
ManagerActionListener.NamingActionListener.new = function()
	local obj = {}
	function obj:preBind(rtobj, name)
	end
	function obj:postBind(rtobj, name)
	end
	function obj:preUnbind(rtobj, name)
	end
	function obj:postUnbind(rtobj, name)
	end

	return obj
end



ManagerActionListener.LocalServiceActionListener = {}
ManagerActionListener.LocalServiceActionListener.new = function()
	local obj = {}
	function obj:preServiceRegister(service_name)
	end
	function obj:postServiceRegister(service_name, service)
	end
	function obj:preServiceInit(prop, service)
	end
	function obj:postServiceInit(prop, service)
	end
	function obj:preServiceReinit(prop, service)
	end
	function obj:postServiceReinit(prop, service)
	end
	function obj:preServiceFinalize(service_name, service)
	end
	function obj:postServiceFinalize(service_name, service)
	end

	return obj
end



ManagerActionListener.ManagerActionListenerHolder = {}

ManagerActionListener.ManagerActionListenerHolder.new = function()
	local obj = {}
	setmetatable(obj, {__index=ListenerHolder.new()})
	function obj:preShutdown()
		self:notify("preShutdown")
	end
	function obj:postShutdown()
		self:notify("postShutdown")
	end
	function obj:preReinit()
		self:notify("preReinit")
	end
	function obj:postReinit()
		self:notify("postReinit")
	end
	return obj
end


ManagerActionListener.ModuleActionListenerHolder = {}
ManagerActionListener.ModuleActionListenerHolder.new = function()
	local obj = {}
	setmetatable(obj, {__index=ListenerHolder.new()})
	function obj:preLoad(modname, funcname)
		self:notify("preLoad", modname, funcname)
	end
	function obj:postLoad(modname, funcname)
		self:notify("postLoad", modname, funcname)
	end
	function obj:preUnload(modname)
		self:notify("preUnload", modname)
	end
	function obj:postUnload(modname)
		self:notify("postUnload", modname)
	end
	return obj
end



ManagerActionListener.RtcLifecycleActionListenerHolder = {}
ManagerActionListener.RtcLifecycleActionListenerHolder.new = function()
	local obj = {}
	setmetatable(obj, {__index=ListenerHolder.new()})
	function obj:preCreate(args)
		self:notify("preCreate", args)
	end
	function obj:postCreate(rtobj)
		self:notify("postCreate", rtobj)
	end
	function obj:preConfigure(prop)
		self:notify("preConfigure", prop)
	end
	function obj:postConfigure(prop)
		self:notify("postConfigure", prop)
	end
	function obj:preInitialize()
		self:notify("preInitialize")
	end
	function obj:postInitialize()
		self:notify("postInitialize")
	end
	return obj
end



ManagerActionListener.NamingActionListenerHolder = {}
ManagerActionListener.NamingActionListenerHolder.new = function()
	local obj = {}
	setmetatable(obj, {__index=ListenerHolder.new()})
	function obj:preBind(rtobj, name)
		self:notify("preBind", rtobj, name)
	end
	function obj:postBind(rtobj, name)
		self:notify("postBind", rtobj, name)
	end
	function obj:preUnbind(rtobj, name)
		self:notify("preUnbind", rtobj, name)
	end
	function obj:postUnbind(rtobj, name)
		self:notify("postUnbind", rtobj, name)
	end
	return obj
end


ManagerActionListener.LocalServiceActionListenerHolder = {}
ManagerActionListener.LocalServiceActionListenerHolder.new = function()
	local obj = {}
	setmetatable(obj, {__index=ListenerHolder.new()})
	function obj:preServiceRegister(service_name)
		self:notify("preServiceRegister", service_name)
	end
	function obj:postServiceRegister(service_name, service)
		self:notify("postServiceRegister", service_name, service)
	end
	function obj:preServiceInit(prop, service)
		self:notify("preServiceInit", prop, service)
	end
	function obj:postServiceInit(prop, service)
		self:notify("postServiceInit", prop, service)
	end
	function obj:preServiceReinit(prop, service)
		self:notify("preServiceReinit", prop, service)
	end
	function obj:postServiceReinit(prop, service)
		self:notify("postServiceReinit", prop, service)
	end
	function obj:preServiceFinalize(service_name, service)
		self:notify("preServiceFinalize", service_name, service)
	end
	function obj:postServiceFinalize(service_name, service)
		self:notify("postServiceFinalize", service_name, service)
	end
	return obj
end


ManagerActionListener.ManagerActionListeners = {}

ManagerActionListener.ManagerActionListeners.new = function()
	local obj = {}
	obj.manager_      = ManagerActionListener.ManagerActionListenerHolder.new()
    obj.module_       = ManagerActionListener.ModuleActionListenerHolder.new() 
    obj.rtclifecycle_ = ManagerActionListener.RtcLifecycleActionListenerHolder.new()
    obj.naming_       = ManagerActionListener.NamingActionListenerHolder.new()
    obj.localservice_ = ManagerActionListener.LocalServiceActionListenerHolder.new()

	return obj
end


return ManagerActionListener
