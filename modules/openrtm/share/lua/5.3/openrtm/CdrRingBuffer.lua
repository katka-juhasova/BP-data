---------------------------------
--! @file CdrRingBuffer.lua
--! @brief リングバッファ定義
--! CdrBufferFactoryからring_bufferという名前で生成できる
---------------------------------


--[[
Copyright (c) 2017 Nobuhiko Miyamoto
]]

local CdrRingBuffer= {}
--_G["openrtm.CdrRingBuffer"] = CdrRingBuffer


local RingBuffer = require "openrtm.RingBuffer"
local Factory = require "openrtm.Factory"
local CdrBufferBase = require "openrtm.CdrBufferBase"
local CdrBufferFactory = CdrBufferBase.CdrBufferFactory

-- リングバッファ初期化
-- @return バッファオブジェクト
CdrRingBuffer.new = function()
	local obj = {}
	setmetatable(obj, {__index=RingBuffer.new()})
	return obj
end

-- リングバッファをファクトリへ登録
CdrRingBuffer.Init = function()
	CdrBufferFactory:instance():addFactory("ring_buffer",
		CdrRingBuffer.new,
		Factory.Delete)
end


return CdrRingBuffer
