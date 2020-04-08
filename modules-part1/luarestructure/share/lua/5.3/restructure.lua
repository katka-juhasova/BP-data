local exports = {}

exports.EncodeStream = require ('restructure.EncodeStream')
exports.DecodeStream = require('restructure.DecodeStream')
exports.Array = require('restructure.Array')
exports.LazyArray = require('restructure.LazyArray')
exports.Bitfield = require('restructure.Bitfield')
exports.Boolean = require('restructure.Boolean')
exports.Buffer = require('restructure.Buffer')
exports.Enum = require('restructure.Enum')
exports.Optional = require('restructure.Optional')
exports.Reserved = require('restructure.Reserved')
exports.String = require('restructure.String')
exports.Struct = require('restructure.Struct')
exports.VersionedStruct = require('restructure.VersionedStruct')

local Number = require("restructure.Number")
local Pointer = require("restructure.Pointer")

for k,v in pairs(Number) do
  exports[k] = v
end

for k,v in pairs(Pointer) do
  exports[k] = v
end

return exports