local class = require 'middleclass'
local parquet_codec = require 'parquet.codec'
local parquet_compression = require 'parquet.compression'
local parquet_thrift = require 'parquet.parquet_ttypes'
local parquet_util = require 'parquet.util'
local vstruct = require 'vstruct'

-- Parquet File Magic String
local PARQUET_MAGIC = 'PAR1'

-- Internal type used for repetition/definition levels
local PARQUET_RDLVL_TYPE = 'INT32'
local PARQUET_RDLVL_ENCODING = 'RLE'

--[[
  Decode a consecutive array of data using one of the parquet encodings
--]]
local function decodeValues(type, encoding, cursor, count, opts)
  local x = parquet_codec[encoding]
  assert(x, 'invalid encoding: ' .. encoding)
  return x.decodeValues(type, cursor, count, opts)
end

local function decodeDataPage(cursor, header, opts)
  local valueCount = header.data_page_header.num_values
  local valueEncoding = parquet_util.getThriftEnum(
      parquet_thrift.Encoding,
      header.data_page_header.encoding)
  
  -- read repetition levels
  local rLevelEncoding = parquet_util.getThriftEnum(
      parquet_thrift.Encoding,
      header.data_page_header.repetition_level_encoding)
  
  --local rLevels = new Array(valueCount)
  local rLevels = {}
  if opts.rLevelMax > 0 then
    rLevels = decodeValues(
      PARQUET_RDLVL_TYPE,
      rLevelEncoding,
      cursor,
      valueCount,
      {bitWidth=parquet_util.getBitWidth(opts.rLevelMax)})
  else
    for i=1,valueCount do rLevels[#rLevels+1] = 0 end
  end
  
  -- read definition levels
  local dLevelEncoding = parquet_util.getThriftEnum(
      parquet_thrift.Encoding,
      header.data_page_header.definition_level_encoding)
  
  local dLevels = {}
  if opts.dLevelMax > 0 then
    dLevels = decodeValues(
      PARQUET_RDLVL_TYPE,
      dLevelEncoding,
      cursor,
      valueCount,
      { bitWidth=parquet_util.getBitWidth(opts.dLevelMax) })
  else
    for i=1,valueCount do dLevels[#dLevels+1] = 0 end
  end
  
  -- read values
  local valueCountNonNull = 0
  for _,dlvl in pairs(dLevels) do
    if dlvl == opts.dLevelMax then
      valueCountNonNull = valueCountNonNull + 1
    end
  end
  
  local values = decodeValues(
    opts.type,
    valueEncoding,
    cursor,
    valueCountNonNull,
    {})
  
  return {
    dlevels = dLevels,
    rlevels = rLevels,
    values = values,
    count = valueCount
  }
end

local function decodeDataPageV2(cursor, header, opts)
  local cursorEnd = cursor.offset + header.compressed_page_size
  local valueCount = header.data_page_header_v2.num_values
  local valueCountNonNull = valueCount - header.data_page_header_v2.num_nulls
  local valueEncoding = parquet_util.getThriftEnum(
    parquet_thrift.Encoding,
    header.data_page_header_v2.encoding)

  -- read repetition levels
  local rLevels = {}
  for i=1,valueCount do rLevels[#rLevels+1] = 0 end
  if opts.rLevelMax > 0 then
    rLevels = decodeValues(
      PARQUET_RDLVL_TYPE,
      PARQUET_RDLVL_ENCODING,
      cursor,
      valueCount,
      {
        bitWidth=parquet_util.getBitWidth(opts.rLevelMax),
        disableEnvelope=true
      })
  end
  
  -- read definition levels
  local dLevels = {}
  if opts.dLevelMax > 0 then
    dLevels = decodeValues(
      PARQUET_RDLVL_TYPE,
      PARQUET_RDLVL_ENCODING,
      cursor,
      valueCount,
      {bitWidth=parquet_util.getBitWidth(opts.dLevelMax), disableEnvelope=true})
  else
    for i=1,valueCount do dLevels[#dLevels+1] = 0 end
  end
  
  -- read values
  local valuesBufCursor = cursor

  if header.data_page_header_v2.is_compressed then
    local valuesBuf = parquet_compression.inflate(
      opts.compression,
      parquet_util.slice(cursor.buffer, cursor.offset, cursorEnd))

    valuesBufCursor = {
      buffer=valuesBuf,
      offset=0,
      size=#valuesBuf
    }

    cursor.offset = cursorEnd
  end

  local values = decodeValues(
    opts.type,
    valueEncoding,
    valuesBufCursor,
    valueCountNonNull,
    {})

  return {
    dlevels = dLevels,
    rlevels = rLevels,
    values = values,
    count = valueCount
  }
end

local function decodeDataPages(buffer, opts)
  local cursor = {
    buffer=buffer,
    offset=0,
    size=#buffer
  }

  local data = {
    rlevels={},
    dlevels={},
    values={},
    count=0
  }
  while cursor.offset < cursor.size do
    local pageHeader = parquet_thrift.PageHeader:new()
    cursor.offset = cursor.offset + parquet_util.decodeThrift(pageHeader, cursor.buffer)
  
    local pageType = parquet_util.getThriftEnum(parquet_thrift.PageType, pageHeader.type)
  
    local pageData
    if pageType == 'DATA_PAGE' then
      pageData = decodeDataPage(cursor, pageHeader, opts)
    elseif pageType == 'DATA_PAGE_V2' then
      pageData = decodeDataPageV2(cursor, pageHeader, opts)
    else
      error("invalid page type: " .. tostring(pageType))
    end
  
    parquet_util.arrayPush(data.rlevels, pageData.rlevels)
    parquet_util.arrayPush(data.dlevels, pageData.dlevels)
    parquet_util.arrayPush(data.values, pageData.values)
    data.count = data.count + pageData.count
  end
  
  return data
end

--[[
 * The parquet envelope reader allows direct, unbuffered access to the individual
 * sections of the parquet file, namely the header, footer and the row groups.
 * This class is intended for advanced/internal users; if you just want to retrieve
 * rows from a parquet file use the ParquetReader instead
--]]
local ParquetEnvelopeReader = class('ParquetEnvelopeReader')

function ParquetEnvelopeReader.openFile(filePath)
  local fileDescriptor = parquet_util.fopen(filePath)
  local fileSize = parquet_util.fsize(fileDescriptor)
  local readFn = function(position, length) return parquet_util.fread(fileDescriptor, position, length) end
  local closeFn = function() return parquet_util.fclose(fileDescriptor) end
  return ParquetEnvelopeReader:new(readFn, closeFn, fileSize)
end

function ParquetEnvelopeReader.openString(buffer)
  local fileSize = #buffer
  local readFn = function(position, length) return buffer:sub(position+1, position+length) end
  local closeFn = function() end
  return ParquetEnvelopeReader:new(readFn, closeFn, fileSize)
end

function ParquetEnvelopeReader:initialize(readFn, closeFn, fileSize)
  self.read = readFn
  self.close = closeFn
  self.fileSize = fileSize
end

function ParquetEnvelopeReader:close()
  self.close()
end

function ParquetEnvelopeReader:readHeader()
  local buf = self.read(0, #PARQUET_MAGIC)
  assert(buf == PARQUET_MAGIC, 'not valid parquet file')
end

function ParquetEnvelopeReader:readRowGroup(schema, rowGroup, columnList)
  local buffer = {
    rowCount=rowGroup.num_rows:toInt(),
    columnData={}
  }
  
  for _,colChunk in pairs(rowGroup.columns) do
    local colMetadata = colChunk.meta_data
    local colKey = table.concat(colMetadata.path_in_schema, ',')
  
    if not (#columnList > 0 and parquet_util.fieldIndexOf(columnList, colKey) == nil) then
      buffer.columnData[colKey] = self:readColumnChunk(schema, colChunk)
    end
  end
  
  return buffer
end

function ParquetEnvelopeReader:readColumnChunk(schema, colChunk)
  assert (colChunk.file_path == nil, 'external references are not supported')

  local field = schema:findField(colChunk.meta_data.path_in_schema)
  local type = parquet_util.getThriftEnum(parquet_thrift.Type, colChunk.meta_data.type)

  local compression = parquet_util.getThriftEnum(
    parquet_thrift.CompressionCodec,
    colChunk.meta_data.codec)

  local pagesOffset = colChunk.meta_data.data_page_offset
  local pagesSize = colChunk.meta_data.total_compressed_size
  local pagesBuf = self.read(pagesOffset:toInt(), pagesSize:toInt())

  return decodeDataPages(pagesBuf, {
    type=type,
    rLevelMax=field.rLevelMax,
    dLevelMax=field.dLevelMax,
    compression=compression
  })
end

function ParquetEnvelopeReader:readFooter()
  local trailerLen = #PARQUET_MAGIC + 4
  local trailerBuf = self.read(self.fileSize - trailerLen, trailerLen)
  
  if parquet_util.slice(trailerBuf, 5) ~= PARQUET_MAGIC then
    error('not a valid parquet file')
  end
  
  local metadataSize = vstruct.read('< u4', string.sub(trailerBuf, 1, 5))[1]
  
  local metadataOffset = self.fileSize - metadataSize - trailerLen
  if metadataOffset < #PARQUET_MAGIC then
    error('invalid metadata size')
  end
  
  local metadataBuf = self.read(metadataOffset, metadataSize)
  local metadata = parquet_thrift.FileMetaData:new()
  parquet_util.decodeThrift(metadata, metadataBuf)
  return metadata
end

return ParquetEnvelopeReader
