---------------------------------
--! @file CdrBufferBase.lua
--! @brief リングバッファ基底クラス定義
--! バッファ生成ファクトリはCdrBufferFactoryに登録する
---------------------------------

--[[
Copyright (c) 2017 Nobuhiko Miyamoto
]]

local CdrBufferBase= {}
--_G["openrtm.CdrBufferBase"] = CdrBufferBase

local GlobalFactory = require "openrtm.GlobalFactory"
local Factory = GlobalFactory.Factory
local BufferBase = require "openrtm.BufferBase"


-- リングバッファ初期化
-- @return バッファオブジェクト
CdrBufferBase.new = function()
	local obj = {}
	setmetatable(obj, {__index=BufferBase.new()})
	return obj
end


CdrBufferBase.CdrBufferFactory = {}
setmetatable(CdrBufferBase.CdrBufferFactory, {__index=Factory.new()})

function CdrBufferBase.CdrBufferFactory:instance()
	return self
end


return CdrBufferBase
