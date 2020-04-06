local class = require 'middleclass'
local parquet_codec = require 'parquet.codec'
local parquet_compression = require 'parquet.compression'
local parquet_types = require 'parquet.types'
local parquet_util = require 'parquet.util'

local unpack = table.unpack or unpack

local arrayConcat = function(t1, t2)
  local t3 = {unpack(t1)}
  for i=1,#t2 do
    t3[#t1+i] = t2[i]
  end
  return t3
end

--[[
-- A parquet file schema
--]]
local ParquetSchema = class('ParquetSchema')

--[[
-- Create a new schema from a JSON schema definition
--]]
function ParquetSchema:initialize(schema)
  self.schema = schema
  self.fields = self:buildFields(schema)
  self.fieldList = self:listFields(self.fields)
end

--[[
 * Retrieve a field definition
--]]
function ParquetSchema:findField(path)
  if type(path) == 'string' then
    path = parquet_util.split(path, ',')
  end
  
  local n = self.fields
  for i=1,#path-1 do
    n = n[path[i]].fields
  end
  
  return n[path[#path]]
end

--[[
 * Retrieve a field definition and all the field's ancestors
--]]
function ParquetSchema:findFieldBranch(path)
  if type(path) == 'string' then
    path = parquet_util.split(tostring(path), ',')
  end
  
  local branch = {}
  local n = self.fields
  for i=1,#path do
    branch[#branch+1] = n[path[i]]
    if i < #path then
      n = n[path[i]].fields
    end
  end

  return branch
end

function ParquetSchema:buildFields(schema, rLevelParentMax, dLevelParentMax, path)
  if not rLevelParentMax then
    rLevelParentMax = 0
  end

  if not dLevelParentMax then
    dLevelParentMax = 0
  end

  if not path then
    path = {}
  end

  local fieldList = {}
  for name in pairs(schema) do
    local opts = schema[name]

    -- field repetition type
    local required = not opts.optional
    local repeated = not not opts.repeated
    local rLevelMax = rLevelParentMax
    local dLevelMax = dLevelParentMax

    local repetitionType = 'REQUIRED'
    if not required then
      repetitionType = 'OPTIONAL'
      dLevelMax = dLevelMax + 1
    end

    if repeated then
      repetitionType = 'REPEATED'
      rLevelMax = rLevelMax + 1

      if required then
        dLevelMax = dLevelMax + 1
      end
    end

    -- nested field
    if opts.fields then
      fieldList[name] = {
        name= name,
        path= arrayConcat(path, {name}),
        repetitionType= repetitionType,
        rLevelMax= rLevelMax,
        dLevelMax= dLevelMax,
        isNested= true,
        fieldCount= parquet_util.keyCount(opts.fields),
        fields= self:buildFields(
              opts.fields,
              rLevelMax,
              dLevelMax,
              arrayConcat(path, {name}))
      }

    else

      -- field type
      local typeDef = parquet_types.PARQUET_LOGICAL_TYPES[opts.type]
      assert(typeDef, 'invalid parquet type: ' .. tostring(opts.type))
  
      -- field encoding
      if not opts.encoding then
        opts.encoding = 'PLAIN'
      end
  
      assert(parquet_codec[opts.encoding], 'unsupported parquet encoding: ' .. opts.encoding)
  
      if not opts.compression then
        opts.compression = 'UNCOMPRESSED'
      end
  
      if not parquet_compression.PARQUET_COMPRESSION_METHODS[opts.compression] then
        error('unsupported compression method: ' .. opts.compression)
      end
  
      -- add to schema
      fieldList[name] = {
        name=name,
        primitiveType=typeDef.primitiveType,
        originalType=typeDef.originalType,
        path=arrayConcat(path, {name}),
        repetitionType=repetitionType,
        encoding=opts.encoding,
        compression=opts.compression,
        rLevelMax=rLevelMax,
        dLevelMax=dLevelMax
      }
    end
  end

  return fieldList
end

function ParquetSchema:listFields(fields)
  local list = {}

  for k in pairs(fields) do
    list[#list+1] = fields[k]

    if fields[k].isNested then
      list = arrayConcat(list, self:listFields(fields[k].fields))
    end
  end

  return list
end

local M = {ParquetSchema=ParquetSchema}
return M
