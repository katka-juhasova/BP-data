---------------------------------
--! @file FactoryInit.lua
--! @brief 各ファクトリの登録を実行する関数
---------------------------------

--[[
Copyright (c) 2017 Nobuhiko Miyamoto
]]

-- 各ファクトリの登録を実行する
local FactoryInit= function()
	--local InPortCorbaCdrProvider = require "openrtm.InPortCorbaCdrProvider"
	--local InPortCorbaCdrProviderInit = InPortCorbaCdrProvider.InPortCorbaCdrProviderInit
	--local InPortCorbaCdrConsumer = require "openrtm.InPortCorbaCdrConsumer"
	--local InPortCorbaCdrConsumerInit = InPortCorbaCdrConsumer.InPortCorbaCdrConsumerInit
	--local OutPortCorbaCdrProvider = require "openrtm.OutPortCorbaCdrProvider"
	--local OutPortCorbaCdrProviderInit = OutPortCorbaCdrProvider.OutPortCorbaCdrProviderInit
	--local OutPortCorbaCdrConsumer = require "openrtm.OutPortCorbaCdrConsumer"
	--local OutPortCorbaCdrConsumerInit = OutPortCorbaCdrConsumer.OutPortCorbaCdrConsumerInit
	local InPortDSProvider = require "openrtm.InPortDSProvider"
	local InPortDSConsumer = require "openrtm.InPortDSConsumer"
	local OutPortDSProvider = require "openrtm.OutPortDSProvider"
	local OutPortDSConsumer = require "openrtm.OutPortDSConsumer"
	local NumberingPolicy = require "openrtm.NumberingPolicy"
	local ProcessUniquePolicy = NumberingPolicy.ProcessUniquePolicy
	local NamingServiceNumberingPolicy = require "openrtm.NamingServiceNumberingPolicy"
	local NodeNumberingPolicy = require "openrtm.NodeNumberingPolicy"
	local CdrRingBuffer = require "openrtm.CdrRingBuffer"
	local PublisherFlush = require "openrtm.PublisherFlush"
	local LogstreamFile = require "openrtm.LogstreamFile"

	CdrRingBuffer.Init()

	--InPortCorbaCdrConsumerInit()
	--InPortCorbaCdrProviderInit()
	--OutPortCorbaCdrConsumerInit()
	--OutPortCorbaCdrProviderInit()
	InPortDSConsumer.Init()
	InPortDSProvider.Init()
	OutPortDSConsumer.Init()
	OutPortDSProvider.Init()
	ProcessUniquePolicy.Init()
	NamingServiceNumberingPolicy.Init()
	NodeNumberingPolicy.Init()

	PublisherFlush.Init()
	
	LogstreamFile.Init()
end

--_G["openrtm.FactoryInit"] = FactoryInit




return FactoryInit
