local class = require 'middleclass'
--local parquet_codec = require 'parquet.codec'
--local parquet_compression = require 'parquet.compression'
local parquet_schema = require 'parquet.schema'
local parquet_ttypes = require 'parquet.parquet_ttypes'
local parquet_util = require 'parquet.util'
local ParquetCursor = require 'parquet.ParquetCursor'
local ParquetEnvelopeReader = require 'parquet.ParquetEnvelopeReader'

--[[
 * Parquet File Format Version
--]]
local PARQUET_VERSION = 1

--[[
 * A parquet reader allows retrieving the rows from a parquet file in order.
 * The basic usage is to create a reader and then retrieve a cursor/iterator
 * which allows you to consume row after row until all rows have been read. It is
 * important that you call close() after you are finished reading the file to
 * avoid leaking file descriptors.
--]]
local ParquetReader = class('ParquetReader')

--[[
 * Open the parquet file pointed to by the specified path and return a new
 * parquet reader
--]]
function ParquetReader.openFile(filePath)
  local envelopeReader = ParquetEnvelopeReader.openFile(filePath)
  local ok, parquetReader = pcall(function()
    envelopeReader:readHeader()
    local metadata = envelopeReader:readFooter()
    return ParquetReader:new(metadata, envelopeReader)
  end)
  if not ok then
    envelopeReader:close()
    error(parquetReader)
  end
  return parquetReader
end

function ParquetReader.openString(buffer)
  local envelopeReader = ParquetEnvelopeReader.openString(buffer)
  local ok, parquetReader = pcall(function()
    envelopeReader:readHeader()
    local metadata = envelopeReader:readFooter()
    return ParquetReader:new(metadata, envelopeReader)
  end)
  if not ok then
    envelopeReader:close()
    error(parquetReader)
  end
  return parquetReader
end

--[[
 * Create a new parquet reader from the file metadata and an envelope reader.
 * It is not recommended to call this constructor directly except for advanced
 * and internal use cases. Consider using one of the open{File,Buffer} methods
 * instead
--]]
function ParquetReader:initialize(metadata, envelopeReader)
  if metadata.version ~= PARQUET_VERSION then
    error('invalid parquet version')
  end

  self.metadata = metadata
  self.envelopeReader = envelopeReader
  self.schema = parquet_schema.ParquetSchema:new(self:decodeSchema(self.metadata.schema))
end

--[[
 * Return a cursor to the file. You may open more than one cursor and use
 * them concurrently. All cursors become invalid once close() is called on
 * the reader object.
 *
 * The required_columns parameter controls which columns are actually read
 * from disk. An empty array or no value implies all columns. A list of column
 * names means that only those columns should be loaded from disk.
--]]
function ParquetReader:getCursor(columnList)
  columnList = columnList or {}
  return ParquetCursor:new(self.metadata, self.envelopeReader, self.schema, columnList)
end

--[[
 * Return the number of rows in this file. Note that the number of rows is
 * not neccessarily equal to the number of rows in each column.
--]]
function ParquetReader:getRowCount()
  return self.metadata.num_rows
end

--[[
 * Returns the ParquetSchema for this file
--]]
function ParquetReader:getSchema()
  return self.schema
end

--[[
 * Returns the user (key/value) metadata for this file
--]]
function ParquetReader:getMetadata()
  local md = {}
  for _, kv in pairs(self.metadata.key_value_metadata) do
    md[kv.key] = kv.value
  end
  return md
end

--[[
 * Close this parquet reader. You MUST call this method once you're finished
 * reading rows
--]]
function ParquetReader:close()
  self.envelopeReader:close()
  self.envelopeReader = nil
  self.metadata = nil
end

--[[
 * Decode a consecutive array of data using one of the parquet encodings
--]]
--function decodeValues(type, encoding, cursor, count, opts) {
--  if (!(encoding in parquet_codec)) {
--    throw 'invalid encoding: ' + encoding;
--  }
--
--  return parquet_codec[encoding].decodeValues(type, cursor, count, opts);
--}
--
--function decodeDataPages(buffer, opts) {
--  let cursor = {
--    buffer: buffer,
--    offset: 0,
--    size: buffer.length
--  };
--
--  let data = {
--    rlevels: [],
--    dlevels: [],
--    values: [],
--    count: 0
--  };
--
--  while (cursor.offset < cursor.size) {
--    const pageHeader = new parquet_thrift.PageHeader();
--    cursor.offset += parquet_util.decodeThrift(pageHeader, cursor.buffer);
--
--    const pageType = parquet_util.getThriftEnum(
--        parquet_thrift.PageType,
--        pageHeader.type);
--
--    let pageData = null;
--    switch (pageType) {
--      case 'DATA_PAGE':
--        pageData = decodeDataPage(cursor, pageHeader, opts);
--        break;
--      case 'DATA_PAGE_V2':
--        pageData = decodeDataPageV2(cursor, pageHeader, opts);
--        break;
--      default:
--        throw "invalid page type: " + pageType;
--    }
--
--    Array.prototype.push.apply(data.rlevels, pageData.rlevels);
--    Array.prototype.push.apply(data.dlevels, pageData.dlevels);
--    Array.prototype.push.apply(data.values, pageData.values);
--    data.count += pageData.count;
--  }
--
--
--  return data;
--}
--
--function decodeDataPage(cursor, header, opts) {
--  let valueCount = header.data_page_header.num_values;
--  let valueEncoding = parquet_util.getThriftEnum(
--      parquet_thrift.Encoding,
--      header.data_page_header.encoding);
--
--  /* read repetition levels */
--  let rLevelEncoding = parquet_util.getThriftEnum(
--      parquet_thrift.Encoding,
--      header.data_page_header.repetition_level_encoding);
--
--  let rLevels = new Array(valueCount);
--  if (opts.rLevelMax > 0) {
--    rLevels = decodeValues(
--        PARQUET_RDLVL_TYPE,
--        rLevelEncoding,
--        cursor,
--        valueCount,
--        { bitWidth: parquet_util.getBitWidth(opts.rLevelMax) });
--  } else {
--    rLevels.fill(0);
--  }
--
--  /* read definition levels */
--  let dLevelEncoding = parquet_util.getThriftEnum(
--      parquet_thrift.Encoding,
--      header.data_page_header.definition_level_encoding);
--
--  let dLevels = new Array(valueCount);
--  if (opts.dLevelMax > 0) {
--    dLevels = decodeValues(
--        PARQUET_RDLVL_TYPE,
--        dLevelEncoding,
--        cursor,
--        valueCount,
--        { bitWidth: parquet_util.getBitWidth(opts.dLevelMax) });
--  } else {
--    dLevels.fill(0);
--  }
--
--  /* read values */
--  let valueCountNonNull = 0;
--  for (let dlvl of dLevels) {
--    if (dlvl === opts.dLevelMax) {
--      ++valueCountNonNull;
--    }
--  }
--
--  let values = decodeValues(
--      opts.type,
--      valueEncoding,
--      cursor,
--      valueCountNonNull,
--      {});
--
--  return {
--    dlevels: dLevels,
--    rlevels: rLevels,
--    values: values,
--    count: valueCount
--  };
--}
--
--function decodeDataPageV2(cursor, header, opts) {
--  const cursorEnd = cursor.offset + header.compressed_page_size;
--
--  const valueCount = header.data_page_header_v2.num_values;
--  const valueCountNonNull = valueCount - header.data_page_header_v2.num_nulls;
--  const valueEncoding = parquet_util.getThriftEnum(
--      parquet_thrift.Encoding,
--      header.data_page_header_v2.encoding);
--
--  /* read repetition levels */
--  let rLevels = new Array(valueCount);
--  if (opts.rLevelMax > 0) {
--    rLevels = decodeValues(
--        PARQUET_RDLVL_TYPE,
--        PARQUET_RDLVL_ENCODING,
--        cursor,
--        valueCount,
--        {
--          bitWidth: parquet_util.getBitWidth(opts.rLevelMax),
--          disableEnvelope: true
--        });
--  } else {
--    rLevels.fill(0);
--  }
--
--  /* read definition levels */
--  let dLevels = new Array(valueCount);
--  if (opts.dLevelMax > 0) {
--    dLevels = decodeValues(
--        PARQUET_RDLVL_TYPE,
--        PARQUET_RDLVL_ENCODING,
--        cursor,
--        valueCount,
--        {
--          bitWidth: parquet_util.getBitWidth(opts.dLevelMax),
--          disableEnvelope: true
--        });
--  } else {
--    dLevels.fill(0);
--  }
--
--  /* read values */
--  let valuesBufCursor = cursor;
--
--  if (header.data_page_header_v2.is_compressed) {
--    let valuesBuf = parquet_compression.inflate(
--        opts.compression,
--        cursor.buffer.slice(cursor.offset, cursorEnd));
--
--    valuesBufCursor = {
--      buffer: valuesBuf,
--      offset: 0,
--      size: valuesBuf.length
--    };
--
--    cursor.offset = cursorEnd;
--  }
--
--  let values = decodeValues(
--        opts.type,
--        valueEncoding,
--        valuesBufCursor,
--        valueCountNonNull,
--        {});
--
--  return {
--    dlevels: dLevels,
--    rlevels: rLevels,
--    values: values,
--    count: valueCount
--  };
--}

function ParquetReader:decodeSchema(schemaElements)
  local iter = parquet_util.iterator(schemaElements)
  local root = iter()
  return self:buildChildren(iter, root.num_children)
end

function ParquetReader:buildChildren(schemaElementIterator, childrenCount)
  local schema = {}
  for i = 1, childrenCount do
    local schemaElement = schemaElementIterator()
    
    local repetitionType = parquet_util.getThriftEnum(
      parquet_ttypes.FieldRepetitionType,
      (schemaElement or {}).repetition_type)

    local optional, repeated = false, false
    if repetitionType == 'OPTIONAL' then
      optional = true
    elseif repetitionType == 'REPEATED' then
      repeated = true
    end

    if schemaElement.num_children or 0 > 0 then
      schema[schemaElement.name] = {
        optional=optional,
        repeated=repeated,
        fields=self:buildChildren(schemaElementIterator, schemaElement.num_children)
      }
    else
      local logicalType = parquet_util.getThriftEnum(parquet_ttypes.Type, schemaElement.type)

      if schemaElement.converted_type ~= nil then
        logicalType = parquet_util.getThriftEnum(parquet_ttypes.ConvertedType, schemaElement.converted_type)
      end

      schema[schemaElement.name] = {
        type=logicalType,
        optional=optional,
        repeated=repeated
      }
    end
  end

  return schema
end

return ParquetReader
