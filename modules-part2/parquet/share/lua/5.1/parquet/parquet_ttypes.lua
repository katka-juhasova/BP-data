local class = require 'middleclass'
local TType = require 'thrift.protocol.TType'

local M = {}

M.Type = {
  BOOLEAN = 0,
  INT32 = 1,
  INT64 = 2,
  INT96 = 3,
  FLOAT = 4,
  DOUBLE = 5,
  BYTE_ARRAY = 6,
  FIXED_LEN_BYTE_ARRAY = 7
}

M.ConvertedType = {
  UTF8 = 0,
  MAP = 1,
  MAP_KEY_VALUE = 2,
  LIST = 3,
  ENUM = 4,
  DECIMAL = 5,
  DATE = 6,
  TIME_MILLIS = 7,
  TIME_MICROS = 8,
  TIMESTAMP_MILLIS = 9,
  TIMESTAMP_MICROS = 10,
  UINT_8 = 11,
  UINT_16 = 12,
  UINT_32 = 13,
  UINT_64 = 14,
  INT_8 = 15,
  INT_16 = 16,
  INT_32 = 17,
  INT_64 = 18,
  JSON = 19,
  BSON = 20,
  INTERVAL = 21,
  NULL = 25
}

M.FieldRepetitionType = {
  REQUIRED = 0,
  OPTIONAL = 1,
  REPEATED = 2
}

M.Encoding = {
  PLAIN = 0,
  PLAIN_DICTIONARY = 2,
  RLE = 3,
  BIT_PACKED = 4,
  DELTA_BINARY_PACKED = 5,
  DELTA_LENGTH_BYTE_ARRAY = 6,
  DELTA_BYTE_ARRAY = 7,
  RLE_DICTIONARY = 8
}

M.CompressionCodec = {
  UNCOMPRESSED = 0,
  SNAPPY = 1,
  GZIP = 2,
  LZO = 3,
  BROTLI = 4
}

M.PageType = {
  DATA_PAGE = 0,
  INDEX_PAGE = 1,
  DICTIONARY_PAGE = 2,
  DATA_PAGE_V2 = 3
}

M.Statistics = class('Statistics')

function M.Statistics:read(iprot)
  iprot:readStructBegin()
  while true do
    local _, ftype, fid = iprot:readFieldBegin()
    if ftype == TType.STOP then
      break
    elseif fid == 1 then
      if ftype == TType.STRING then
        self.max = iprot:readString()
      else
        iprot:skip(ftype)
      end
    elseif fid == 2 then
      if ftype == TType.STRING then
        self.min = iprot:readString()
      else
        iprot:skip(ftype)
      end
    elseif fid == 3 then
      if ftype == TType.I64 then
        self.null_count = iprot:readI64()
      else
        iprot:skip(ftype)
      end
    elseif fid == 4 then
      if ftype == TType.I64 then
        self.distinct_count = iprot:readI64()
      else
        iprot:skip(ftype)
      end
    else
      iprot:skip(ftype)
    end
    iprot:readFieldEnd()
  end
  iprot:readStructEnd()
end

function M.Statistics:write(oprot)
  oprot:writeStructBegin('Statistics')
  if self.max ~= nil then
    oprot:writeFieldBegin('max', TType.STRING, 1)
    oprot:writeString(self.max)
    oprot:writeFieldEnd()
  end
  if self.min ~= nil then
    oprot:writeFieldBegin('min', TType.STRING, 2)
    oprot:writeString(self.min)
    oprot:writeFieldEnd()
  end
  if self.null_count ~= nil then
    oprot:writeFieldBegin('null_count', TType.I64, 3)
    oprot:writeI64(self.null_count)
    oprot:writeFieldEnd()
  end
  if self.distinct_count ~= nil then
    oprot:writeFieldBegin('distinct_count', TType.I64, 4)
    oprot:writeI64(self.distinct_count)
    oprot:writeFieldEnd()
  end
  oprot:writeFieldStop()
  oprot:writeStructEnd()
end

M.SchemaElement = class('SchemaElement')

function M.SchemaElement:read(iprot)
  iprot:readStructBegin()
  while true do
    local _, ftype, fid = iprot:readFieldBegin()
    if ftype == TType.STOP then
      break
    elseif fid == 1 then
      if ftype == TType.I32 then
        self.type = iprot:readI32()
      else
        iprot:skip(ftype)
      end
    elseif fid == 2 then
      if ftype == TType.I32 then
        self.type_length = iprot:readI32()
      else
        iprot:skip(ftype)
      end
    elseif fid == 3 then
      if ftype == TType.I32 then
        self.repetition_type = iprot:readI32()
      else
        iprot:skip(ftype)
      end
    elseif fid == 4 then
      if ftype == TType.STRING then
        self.name = iprot:readString()
      else
        iprot:skip(ftype)
      end
    elseif fid == 5 then
      if ftype == TType.I32 then
        self.num_children = iprot:readI32()
      else
        iprot:skip(ftype)
      end
    elseif fid == 6 then
      if ftype == TType.I32 then
        self.converted_type = iprot:readI32()
      else
        iprot:skip(ftype)
      end
    elseif fid == 7 then
      if ftype == TType.I32 then
        self.scale = iprot:readI32()
      else
        iprot:skip(ftype)
      end
    elseif fid == 8 then
      if ftype == TType.I32 then
        self.precision = iprot:readI32()
      else
        iprot:skip(ftype)
      end
    elseif fid == 9 then
      if ftype == TType.I32 then
        self.field_id = iprot:readI32()
      else
        iprot:skip(ftype)
      end
    else
      iprot:skip(ftype)
    end
    iprot:readFieldEnd()
  end
  iprot:readStructEnd()
end

function M.SchemaElement:write(oprot)
  oprot:writeStructBegin('SchemaElement')
  if self.type ~= nil then
    oprot:writeFieldBegin('type', TType.I32, 1)
    oprot:writeI32(self.type)
    oprot:writeFieldEnd()
  end
  if self.type_length ~= nil then
    oprot:writeFieldBegin('type_length', TType.I32, 2)
    oprot:writeI32(self.type_length)
    oprot:writeFieldEnd()
  end
  if self.repetition_type ~= nil then
    oprot:writeFieldBegin('repetition_type', TType.I32, 3)
    oprot:writeI32(self.repetition_type)
    oprot:writeFieldEnd()
  end
  if self.name ~= nil then
    oprot:writeFieldBegin('name', TType.STRING, 4)
    oprot:writeString(self.name)
    oprot:writeFieldEnd()
  end
  if self.num_children ~= nil then
    oprot:writeFieldBegin('num_children', TType.I32, 5)
    oprot:writeI32(self.num_children)
    oprot:writeFieldEnd()
  end
  if self.converted_type ~= nil then
    oprot:writeFieldBegin('converted_type', TType.I32, 6)
    oprot:writeI32(self.converted_type)
    oprot:writeFieldEnd()
  end
  if self.scale ~= nil then
    oprot:writeFieldBegin('scale', TType.I32, 7)
    oprot:writeI32(self.scale)
    oprot:writeFieldEnd()
  end
  if self.precision ~= nil then
    oprot:writeFieldBegin('precision', TType.I32, 8)
    oprot:writeI32(self.precision)
    oprot:writeFieldEnd()
  end
  if self.field_id ~= nil then
    oprot:writeFieldBegin('field_id', TType.I32, 9)
    oprot:writeI32(self.field_id)
    oprot:writeFieldEnd()
  end
  oprot:writeFieldStop()
  oprot:writeStructEnd()
end

M.DataPageHeader = class('DataPageHeader')

function M.DataPageHeader:read(iprot)
  iprot:readStructBegin()
  while true do
    local _, ftype, fid = iprot:readFieldBegin()
    if ftype == TType.STOP then
      break
    elseif fid == 1 then
      if ftype == TType.I32 then
        self.num_values = iprot:readI32()
      else
        iprot:skip(ftype)
      end
    elseif fid == 2 then
      if ftype == TType.I32 then
        self.encoding = iprot:readI32()
      else
        iprot:skip(ftype)
      end
    elseif fid == 3 then
      if ftype == TType.I32 then
        self.definition_level_encoding = iprot:readI32()
      else
        iprot:skip(ftype)
      end
    elseif fid == 4 then
      if ftype == TType.I32 then
        self.repetition_level_encoding = iprot:readI32()
      else
        iprot:skip(ftype)
      end
    elseif fid == 5 then
      if ftype == TType.STRUCT then
        self.statistics = M.Statistics:new{}
        self.statistics:read(iprot)
      else
        iprot:skip(ftype)
      end
    else
      iprot:skip(ftype)
    end
    iprot:readFieldEnd()
  end
  iprot:readStructEnd()
end

function M.DataPageHeader:write(oprot)
  oprot:writeStructBegin('DataPageHeader')
  if self.num_values ~= nil then
    oprot:writeFieldBegin('num_values', TType.I32, 1)
    oprot:writeI32(self.num_values)
    oprot:writeFieldEnd()
  end
  if self.encoding ~= nil then
    oprot:writeFieldBegin('encoding', TType.I32, 2)
    oprot:writeI32(self.encoding)
    oprot:writeFieldEnd()
  end
  if self.definition_level_encoding ~= nil then
    oprot:writeFieldBegin('definition_level_encoding', TType.I32, 3)
    oprot:writeI32(self.definition_level_encoding)
    oprot:writeFieldEnd()
  end
  if self.repetition_level_encoding ~= nil then
    oprot:writeFieldBegin('repetition_level_encoding', TType.I32, 4)
    oprot:writeI32(self.repetition_level_encoding)
    oprot:writeFieldEnd()
  end
  if self.statistics ~= nil then
    oprot:writeFieldBegin('statistics', TType.STRUCT, 5)
    self.statistics:write(oprot)
    oprot:writeFieldEnd()
  end
  oprot:writeFieldStop()
  oprot:writeStructEnd()
end

M.IndexPageHeader = class('IndexPageHeader')

function M.IndexPageHeader:read(iprot)
  iprot:readStructBegin()
  while true do
    local _, ftype, _ = iprot:readFieldBegin()
    if ftype == TType.STOP then
      break
    else
      iprot:skip(ftype)
    end
    iprot:readFieldEnd()
  end
  iprot:readStructEnd()
end

function M.IndexPageHeader:write(oprot)
  oprot:writeStructBegin('IndexPageHeader')
  oprot:writeFieldStop()
  oprot:writeStructEnd()
end

M.DictionaryPageHeader = class('DictionaryPageHeader')

function M.DictionaryPageHeader:read(iprot)
  iprot:readStructBegin()
  while true do
    local _, ftype, fid = iprot:readFieldBegin()
    if ftype == TType.STOP then
      break
    elseif fid == 1 then
      if ftype == TType.I32 then
        self.num_values = iprot:readI32()
      else
        iprot:skip(ftype)
      end
    elseif fid == 2 then
      if ftype == TType.I32 then
        self.encoding = iprot:readI32()
      else
        iprot:skip(ftype)
      end
    elseif fid == 3 then
      if ftype == TType.BOOL then
        self.is_sorted = iprot:readBool()
      else
        iprot:skip(ftype)
      end
    else
      iprot:skip(ftype)
    end
    iprot:readFieldEnd()
  end
  iprot:readStructEnd()
end

function M.DictionaryPageHeader:write(oprot)
  oprot:writeStructBegin('DictionaryPageHeader')
  if self.num_values ~= nil then
    oprot:writeFieldBegin('num_values', TType.I32, 1)
    oprot:writeI32(self.num_values)
    oprot:writeFieldEnd()
  end
  if self.encoding ~= nil then
    oprot:writeFieldBegin('encoding', TType.I32, 2)
    oprot:writeI32(self.encoding)
    oprot:writeFieldEnd()
  end
  if self.is_sorted ~= nil then
    oprot:writeFieldBegin('is_sorted', TType.BOOL, 3)
    oprot:writeBool(self.is_sorted)
    oprot:writeFieldEnd()
  end
  oprot:writeFieldStop()
  oprot:writeStructEnd()
end

M.DataPageHeaderV2 = class('DataPageHeaderV2')

function M.DataPageHeaderV2:read(iprot)
  iprot:readStructBegin()
  while true do
    local _, ftype, fid = iprot:readFieldBegin()
    if ftype == TType.STOP then
      break
    elseif fid == 1 then
      if ftype == TType.I32 then
        self.num_values = iprot:readI32()
      else
        iprot:skip(ftype)
      end
    elseif fid == 2 then
      if ftype == TType.I32 then
        self.num_nulls = iprot:readI32()
      else
        iprot:skip(ftype)
      end
    elseif fid == 3 then
      if ftype == TType.I32 then
        self.num_rows = iprot:readI32()
      else
        iprot:skip(ftype)
      end
    elseif fid == 4 then
      if ftype == TType.I32 then
        self.encoding = iprot:readI32()
      else
        iprot:skip(ftype)
      end
    elseif fid == 5 then
      if ftype == TType.I32 then
        self.definition_levels_byte_length = iprot:readI32()
      else
        iprot:skip(ftype)
      end
    elseif fid == 6 then
      if ftype == TType.I32 then
        self.repetition_levels_byte_length = iprot:readI32()
      else
        iprot:skip(ftype)
      end
    elseif fid == 7 then
      if ftype == TType.BOOL then
        self.is_compressed = iprot:readBool()
      else
        iprot:skip(ftype)
      end
    elseif fid == 8 then
      if ftype == TType.STRUCT then
        self.statistics = M.Statistics:new{}
        self.statistics:read(iprot)
      else
        iprot:skip(ftype)
      end
    else
      iprot:skip(ftype)
    end
    iprot:readFieldEnd()
  end
  iprot:readStructEnd()
end

function M.DataPageHeaderV2:write(oprot)
  oprot:writeStructBegin('DataPageHeaderV2')
  if self.num_values ~= nil then
    oprot:writeFieldBegin('num_values', TType.I32, 1)
    oprot:writeI32(self.num_values)
    oprot:writeFieldEnd()
  end
  if self.num_nulls ~= nil then
    oprot:writeFieldBegin('num_nulls', TType.I32, 2)
    oprot:writeI32(self.num_nulls)
    oprot:writeFieldEnd()
  end
  if self.num_rows ~= nil then
    oprot:writeFieldBegin('num_rows', TType.I32, 3)
    oprot:writeI32(self.num_rows)
    oprot:writeFieldEnd()
  end
  if self.encoding ~= nil then
    oprot:writeFieldBegin('encoding', TType.I32, 4)
    oprot:writeI32(self.encoding)
    oprot:writeFieldEnd()
  end
  if self.definition_levels_byte_length ~= nil then
    oprot:writeFieldBegin('definition_levels_byte_length', TType.I32, 5)
    oprot:writeI32(self.definition_levels_byte_length)
    oprot:writeFieldEnd()
  end
  if self.repetition_levels_byte_length ~= nil then
    oprot:writeFieldBegin('repetition_levels_byte_length', TType.I32, 6)
    oprot:writeI32(self.repetition_levels_byte_length)
    oprot:writeFieldEnd()
  end
  if self.is_compressed ~= nil then
    oprot:writeFieldBegin('is_compressed', TType.BOOL, 7)
    oprot:writeBool(self.is_compressed)
    oprot:writeFieldEnd()
  end
  if self.statistics ~= nil then
    oprot:writeFieldBegin('statistics', TType.STRUCT, 8)
    self.statistics:write(oprot)
    oprot:writeFieldEnd()
  end
  oprot:writeFieldStop()
  oprot:writeStructEnd()
end

M.PageHeader = class('PageHeader')

function M.PageHeader:read(iprot)
  iprot:readStructBegin()
  while true do
    local _, ftype, fid = iprot:readFieldBegin()
    if ftype == TType.STOP then
      break
    elseif fid == 1 then
      if ftype == TType.I32 then
        self.type = iprot:readI32()
      else
        iprot:skip(ftype)
      end
    elseif fid == 2 then
      if ftype == TType.I32 then
        self.uncompressed_page_size = iprot:readI32()
      else
        iprot:skip(ftype)
      end
    elseif fid == 3 then
      if ftype == TType.I32 then
        self.compressed_page_size = iprot:readI32()
      else
        iprot:skip(ftype)
      end
    elseif fid == 4 then
      if ftype == TType.I32 then
        self.crc = iprot:readI32()
      else
        iprot:skip(ftype)
      end
    elseif fid == 5 then
      if ftype == TType.STRUCT then
        self.data_page_header = M.DataPageHeader:new{}
        self.data_page_header:read(iprot)
      else
        iprot:skip(ftype)
      end
    elseif fid == 6 then
      if ftype == TType.STRUCT then
        self.index_page_header = M.IndexPageHeader:new{}
        self.index_page_header:read(iprot)
      else
        iprot:skip(ftype)
      end
    elseif fid == 7 then
      if ftype == TType.STRUCT then
        self.dictionary_page_header = M.DictionaryPageHeader:new{}
        self.dictionary_page_header:read(iprot)
      else
        iprot:skip(ftype)
      end
    elseif fid == 8 then
      if ftype == TType.STRUCT then
        self.data_page_header_v2 = M.DataPageHeaderV2:new{}
        self.data_page_header_v2:read(iprot)
      else
        iprot:skip(ftype)
      end
    else
      iprot:skip(ftype)
    end
    iprot:readFieldEnd()
  end
  iprot:readStructEnd()
end

function M.PageHeader:write(oprot)
  oprot:writeStructBegin('PageHeader')
  if self.type ~= nil then
    oprot:writeFieldBegin('type', TType.I32, 1)
    oprot:writeI32(self.type)
    oprot:writeFieldEnd()
  end
  if self.uncompressed_page_size ~= nil then
    oprot:writeFieldBegin('uncompressed_page_size', TType.I32, 2)
    oprot:writeI32(self.uncompressed_page_size)
    oprot:writeFieldEnd()
  end
  if self.compressed_page_size ~= nil then
    oprot:writeFieldBegin('compressed_page_size', TType.I32, 3)
    oprot:writeI32(self.compressed_page_size)
    oprot:writeFieldEnd()
  end
  if self.crc ~= nil then
    oprot:writeFieldBegin('crc', TType.I32, 4)
    oprot:writeI32(self.crc)
    oprot:writeFieldEnd()
  end
  if self.data_page_header ~= nil then
    oprot:writeFieldBegin('data_page_header', TType.STRUCT, 5)
    self.data_page_header:write(oprot)
    oprot:writeFieldEnd()
  end
  if self.index_page_header ~= nil then
    oprot:writeFieldBegin('index_page_header', TType.STRUCT, 6)
    self.index_page_header:write(oprot)
    oprot:writeFieldEnd()
  end
  if self.dictionary_page_header ~= nil then
    oprot:writeFieldBegin('dictionary_page_header', TType.STRUCT, 7)
    self.dictionary_page_header:write(oprot)
    oprot:writeFieldEnd()
  end
  if self.data_page_header_v2 ~= nil then
    oprot:writeFieldBegin('data_page_header_v2', TType.STRUCT, 8)
    self.data_page_header_v2:write(oprot)
    oprot:writeFieldEnd()
  end
  oprot:writeFieldStop()
  oprot:writeStructEnd()
end

M.KeyValue = class('KeyValue')

function M.KeyValue:read(iprot)
  iprot:readStructBegin()
  while true do
    local _, ftype, fid = iprot:readFieldBegin()
    if ftype == TType.STOP then
      break
    elseif fid == 1 then
      if ftype == TType.STRING then
        self.key = iprot:readString()
      else
        iprot:skip(ftype)
      end
    elseif fid == 2 then
      if ftype == TType.STRING then
        self.value = iprot:readString()
      else
        iprot:skip(ftype)
      end
    else
      iprot:skip(ftype)
    end
    iprot:readFieldEnd()
  end
  iprot:readStructEnd()
end

function M.KeyValue:write(oprot)
  oprot:writeStructBegin('KeyValue')
  if self.key ~= nil then
    oprot:writeFieldBegin('key', TType.STRING, 1)
    oprot:writeString(self.key)
    oprot:writeFieldEnd()
  end
  if self.value ~= nil then
    oprot:writeFieldBegin('value', TType.STRING, 2)
    oprot:writeString(self.value)
    oprot:writeFieldEnd()
  end
  oprot:writeFieldStop()
  oprot:writeStructEnd()
end

M.SortingColumn = class('SortingColumn')

function M.SortingColumn:read(iprot)
  iprot:readStructBegin()
  while true do
    local _, ftype, fid = iprot:readFieldBegin()
    if ftype == TType.STOP then
      break
    elseif fid == 1 then
      if ftype == TType.I32 then
        self.column_idx = iprot:readI32()
      else
        iprot:skip(ftype)
      end
    elseif fid == 2 then
      if ftype == TType.BOOL then
        self.descending = iprot:readBool()
      else
        iprot:skip(ftype)
      end
    elseif fid == 3 then
      if ftype == TType.BOOL then
        self.nulls_first = iprot:readBool()
      else
        iprot:skip(ftype)
      end
    else
      iprot:skip(ftype)
    end
    iprot:readFieldEnd()
  end
  iprot:readStructEnd()
end

function M.SortingColumn:write(oprot)
  oprot:writeStructBegin('SortingColumn')
  if self.column_idx ~= nil then
    oprot:writeFieldBegin('column_idx', TType.I32, 1)
    oprot:writeI32(self.column_idx)
    oprot:writeFieldEnd()
  end
  if self.descending ~= nil then
    oprot:writeFieldBegin('descending', TType.BOOL, 2)
    oprot:writeBool(self.descending)
    oprot:writeFieldEnd()
  end
  if self.nulls_first ~= nil then
    oprot:writeFieldBegin('nulls_first', TType.BOOL, 3)
    oprot:writeBool(self.nulls_first)
    oprot:writeFieldEnd()
  end
  oprot:writeFieldStop()
  oprot:writeStructEnd()
end

M.PageEncodingStats = class('PageEncodingStats')

function M.PageEncodingStats:read(iprot)
  iprot:readStructBegin()
  while true do
    local _, ftype, fid = iprot:readFieldBegin()
    if ftype == TType.STOP then
      break
    elseif fid == 1 then
      if ftype == TType.I32 then
        self.page_type = iprot:readI32()
      else
        iprot:skip(ftype)
      end
    elseif fid == 2 then
      if ftype == TType.I32 then
        self.encoding = iprot:readI32()
      else
        iprot:skip(ftype)
      end
    elseif fid == 3 then
      if ftype == TType.I32 then
        self.count = iprot:readI32()
      else
        iprot:skip(ftype)
      end
    else
      iprot:skip(ftype)
    end
    iprot:readFieldEnd()
  end
  iprot:readStructEnd()
end

function M.PageEncodingStats:write(oprot)
  oprot:writeStructBegin('PageEncodingStats')
  if self.page_type ~= nil then
    oprot:writeFieldBegin('page_type', TType.I32, 1)
    oprot:writeI32(self.page_type)
    oprot:writeFieldEnd()
  end
  if self.encoding ~= nil then
    oprot:writeFieldBegin('encoding', TType.I32, 2)
    oprot:writeI32(self.encoding)
    oprot:writeFieldEnd()
  end
  if self.count ~= nil then
    oprot:writeFieldBegin('count', TType.I32, 3)
    oprot:writeI32(self.count)
    oprot:writeFieldEnd()
  end
  oprot:writeFieldStop()
  oprot:writeStructEnd()
end

M.ColumnMetaData = class('ColumnMetaData')

function M.ColumnMetaData:read(iprot)
  iprot:readStructBegin()
  while true do
    local _, ftype, fid = iprot:readFieldBegin()
    if ftype == TType.STOP then
      break
    elseif fid == 1 then
      if ftype == TType.I32 then
        self.type = iprot:readI32()
      else
        iprot:skip(ftype)
      end
    elseif fid == 2 then
      if ftype == TType.LIST then
        self.encodings = {}
        local _, _size0 = iprot:readListBegin()
        for _i=1,_size0 do
          local _elem4 = iprot:readI32()
          table.insert(self.encodings, _elem4)
        end
        iprot:readListEnd()
      else
        iprot:skip(ftype)
      end
    elseif fid == 3 then
      if ftype == TType.LIST then
        self.path_in_schema = {}
        local _, _size5 = iprot:readListBegin()
        for _i=1,_size5 do
          local _elem9 = iprot:readString()
          table.insert(self.path_in_schema, _elem9)
        end
        iprot:readListEnd()
      else
        iprot:skip(ftype)
      end
    elseif fid == 4 then
      if ftype == TType.I32 then
        self.codec = iprot:readI32()
      else
        iprot:skip(ftype)
      end
    elseif fid == 5 then
      if ftype == TType.I64 then
        self.num_values = iprot:readI64()
      else
        iprot:skip(ftype)
      end
    elseif fid == 6 then
      if ftype == TType.I64 then
        self.total_uncompressed_size = iprot:readI64()
      else
        iprot:skip(ftype)
      end
    elseif fid == 7 then
      if ftype == TType.I64 then
        self.total_compressed_size = iprot:readI64()
      else
        iprot:skip(ftype)
      end
    elseif fid == 8 then
      if ftype == TType.LIST then
        self.key_value_metadata = {}
        local _, _size10 = iprot:readListBegin()
        for _i=1,_size10 do
          local _elem14 = M.KeyValue:new{}
          _elem14:read(iprot)
          table.insert(self.key_value_metadata, _elem14)
        end
        iprot:readListEnd()
      else
        iprot:skip(ftype)
      end
    elseif fid == 9 then
      if ftype == TType.I64 then
        self.data_page_offset = iprot:readI64()
      else
        iprot:skip(ftype)
      end
    elseif fid == 10 then
      if ftype == TType.I64 then
        self.index_page_offset = iprot:readI64()
      else
        iprot:skip(ftype)
      end
    elseif fid == 11 then
      if ftype == TType.I64 then
        self.dictionary_page_offset = iprot:readI64()
      else
        iprot:skip(ftype)
      end
    elseif fid == 12 then
      if ftype == TType.STRUCT then
        self.statistics = M.Statistics:new{}
        self.statistics:read(iprot)
      else
        iprot:skip(ftype)
      end
    elseif fid == 13 then
      if ftype == TType.LIST then
        self.encoding_stats = {}
        local _, _size15 = iprot:readListBegin()
        for _i=1,_size15 do
          local _elem19 = M.PageEncodingStats:new{}
          _elem19:read(iprot)
          table.insert(self.encoding_stats, _elem19)
        end
        iprot:readListEnd()
      else
        iprot:skip(ftype)
      end
    else
      iprot:skip(ftype)
    end
    iprot:readFieldEnd()
  end
  iprot:readStructEnd()
end

function M.ColumnMetaData:write(oprot)
  oprot:writeStructBegin('ColumnMetaData')
  if self.type ~= nil then
    oprot:writeFieldBegin('type', TType.I32, 1)
    oprot:writeI32(self.type)
    oprot:writeFieldEnd()
  end
  if self.encodings ~= nil then
    oprot:writeFieldBegin('encodings', TType.LIST, 2)
    oprot:writeListBegin(TType.I32, #self.encodings)
    for _,iter20 in ipairs(self.encodings) do
      oprot:writeI32(iter20)
    end
    oprot:writeListEnd()
    oprot:writeFieldEnd()
  end
  if self.path_in_schema ~= nil then
    oprot:writeFieldBegin('path_in_schema', TType.LIST, 3)
    oprot:writeListBegin(TType.STRING, #self.path_in_schema)
    for _,iter21 in ipairs(self.path_in_schema) do
      oprot:writeString(iter21)
    end
    oprot:writeListEnd()
    oprot:writeFieldEnd()
  end
  if self.codec ~= nil then
    oprot:writeFieldBegin('codec', TType.I32, 4)
    oprot:writeI32(self.codec)
    oprot:writeFieldEnd()
  end
  if self.num_values ~= nil then
    oprot:writeFieldBegin('num_values', TType.I64, 5)
    oprot:writeI64(self.num_values)
    oprot:writeFieldEnd()
  end
  if self.total_uncompressed_size ~= nil then
    oprot:writeFieldBegin('total_uncompressed_size', TType.I64, 6)
    oprot:writeI64(self.total_uncompressed_size)
    oprot:writeFieldEnd()
  end
  if self.total_compressed_size ~= nil then
    oprot:writeFieldBegin('total_compressed_size', TType.I64, 7)
    oprot:writeI64(self.total_compressed_size)
    oprot:writeFieldEnd()
  end
  if self.key_value_metadata ~= nil then
    oprot:writeFieldBegin('key_value_metadata', TType.LIST, 8)
    oprot:writeListBegin(TType.STRUCT, #self.key_value_metadata)
    for _,iter22 in ipairs(self.key_value_metadata) do
      iter22:write(oprot)
    end
    oprot:writeListEnd()
    oprot:writeFieldEnd()
  end
  if self.data_page_offset ~= nil then
    oprot:writeFieldBegin('data_page_offset', TType.I64, 9)
    oprot:writeI64(self.data_page_offset)
    oprot:writeFieldEnd()
  end
  if self.index_page_offset ~= nil then
    oprot:writeFieldBegin('index_page_offset', TType.I64, 10)
    oprot:writeI64(self.index_page_offset)
    oprot:writeFieldEnd()
  end
  if self.dictionary_page_offset ~= nil then
    oprot:writeFieldBegin('dictionary_page_offset', TType.I64, 11)
    oprot:writeI64(self.dictionary_page_offset)
    oprot:writeFieldEnd()
  end
  if self.statistics ~= nil then
    oprot:writeFieldBegin('statistics', TType.STRUCT, 12)
    self.statistics:write(oprot)
    oprot:writeFieldEnd()
  end
  if self.encoding_stats ~= nil then
    oprot:writeFieldBegin('encoding_stats', TType.LIST, 13)
    oprot:writeListBegin(TType.STRUCT, #self.encoding_stats)
    for _,iter23 in ipairs(self.encoding_stats) do
      iter23:write(oprot)
    end
    oprot:writeListEnd()
    oprot:writeFieldEnd()
  end
  oprot:writeFieldStop()
  oprot:writeStructEnd()
end

M.ColumnChunk = class('ColumnChunk')

function M.ColumnChunk:read(iprot)
  iprot:readStructBegin()
  while true do
    local _, ftype, fid = iprot:readFieldBegin()
    if ftype == TType.STOP then
      break
    elseif fid == 1 then
      if ftype == TType.STRING then
        self.file_path = iprot:readString()
      else
        iprot:skip(ftype)
      end
    elseif fid == 2 then
      if ftype == TType.I64 then
        self.file_offset = iprot:readI64()
      else
        iprot:skip(ftype)
      end
    elseif fid == 3 then
      if ftype == TType.STRUCT then
        self.meta_data = M.ColumnMetaData:new{}
        self.meta_data:read(iprot)
      else
        iprot:skip(ftype)
      end
    else
      iprot:skip(ftype)
    end
    iprot:readFieldEnd()
  end
  iprot:readStructEnd()
end

function M.ColumnChunk:write(oprot)
  oprot:writeStructBegin('ColumnChunk')
  if self.file_path ~= nil then
    oprot:writeFieldBegin('file_path', TType.STRING, 1)
    oprot:writeString(self.file_path)
    oprot:writeFieldEnd()
  end
  if self.file_offset ~= nil then
    oprot:writeFieldBegin('file_offset', TType.I64, 2)
    oprot:writeI64(self.file_offset)
    oprot:writeFieldEnd()
  end
  if self.meta_data ~= nil then
    oprot:writeFieldBegin('meta_data', TType.STRUCT, 3)
    self.meta_data:write(oprot)
    oprot:writeFieldEnd()
  end
  oprot:writeFieldStop()
  oprot:writeStructEnd()
end

M.RowGroup = class('RowGroup')

function M.RowGroup:read(iprot)
  iprot:readStructBegin()
  while true do
    local _, ftype, fid = iprot:readFieldBegin()
    if ftype == TType.STOP then
      break
    elseif fid == 1 then
      if ftype == TType.LIST then
        self.columns = {}
        local _, _size24 = iprot:readListBegin()
        for _i=1,_size24 do
          local _elem28 = M.ColumnChunk:new{}
          _elem28:read(iprot)
          table.insert(self.columns, _elem28)
        end
        iprot:readListEnd()
      else
        iprot:skip(ftype)
      end
    elseif fid == 2 then
      if ftype == TType.I64 then
        self.total_byte_size = iprot:readI64()
      else
        iprot:skip(ftype)
      end
    elseif fid == 3 then
      if ftype == TType.I64 then
        self.num_rows = iprot:readI64()
      else
        iprot:skip(ftype)
      end
    elseif fid == 4 then
      if ftype == TType.LIST then
        self.sorting_columns = {}
        local _, _size29 = iprot:readListBegin()
        for _i=1,_size29 do
          local _elem33 = M.SortingColumn:new{}
          _elem33:read(iprot)
          table.insert(self.sorting_columns, _elem33)
        end
        iprot:readListEnd()
      else
        iprot:skip(ftype)
      end
    else
      iprot:skip(ftype)
    end
    iprot:readFieldEnd()
  end
  iprot:readStructEnd()
end

function M.RowGroup:write(oprot)
  oprot:writeStructBegin('RowGroup')
  if self.columns ~= nil then
    oprot:writeFieldBegin('columns', TType.LIST, 1)
    oprot:writeListBegin(TType.STRUCT, #self.columns)
    for _,iter34 in ipairs(self.columns) do
      iter34:write(oprot)
    end
    oprot:writeListEnd()
    oprot:writeFieldEnd()
  end
  if self.total_byte_size ~= nil then
    oprot:writeFieldBegin('total_byte_size', TType.I64, 2)
    oprot:writeI64(self.total_byte_size)
    oprot:writeFieldEnd()
  end
  if self.num_rows ~= nil then
    oprot:writeFieldBegin('num_rows', TType.I64, 3)
    oprot:writeI64(self.num_rows)
    oprot:writeFieldEnd()
  end
  if self.sorting_columns ~= nil then
    oprot:writeFieldBegin('sorting_columns', TType.LIST, 4)
    oprot:writeListBegin(TType.STRUCT, #self.sorting_columns)
    for _,iter35 in ipairs(self.sorting_columns) do
      iter35:write(oprot)
    end
    oprot:writeListEnd()
    oprot:writeFieldEnd()
  end
  oprot:writeFieldStop()
  oprot:writeStructEnd()
end

M.FileMetaData = class('FileMetaData')

function M.FileMetaData:read(iprot)
  iprot:readStructBegin()
  while true do
    local _, ftype, fid = iprot:readFieldBegin()
    if ftype == TType.STOP then
      break
    elseif fid == 1 then
      if ftype == TType.I32 then
        self.version = iprot:readI32()
      else
        iprot:skip(ftype)
      end
    elseif fid == 2 then
      if ftype == TType.LIST then
        self.schema = {}
        local _, _size36 = iprot:readListBegin()
        for _i=1,_size36 do
          local _elem40 = M.SchemaElement:new{}
          _elem40:read(iprot)
          table.insert(self.schema, _elem40)
        end
        iprot:readListEnd()
      else
        iprot:skip(ftype)
      end
    elseif fid == 3 then
      if ftype == TType.I64 then
        self.num_rows = iprot:readI64()
      else
        iprot:skip(ftype)
      end
    elseif fid == 4 then
      if ftype == TType.LIST then
        self.row_groups = {}
        local _, _size41 = iprot:readListBegin()
        for _i=1,_size41 do
          local _elem45 = M.RowGroup:new{}
          _elem45:read(iprot)
          table.insert(self.row_groups, _elem45)
        end
        iprot:readListEnd()
      else
        iprot:skip(ftype)
      end
    elseif fid == 5 then
      if ftype == TType.LIST then
        self.key_value_metadata = {}
        local _, _size46 = iprot:readListBegin()
        for _i=1,_size46 do
          local _elem50 = M.KeyValue:new{}
          _elem50:read(iprot)
          table.insert(self.key_value_metadata, _elem50)
        end
        iprot:readListEnd()
      else
        iprot:skip(ftype)
      end
    elseif fid == 6 then
      if ftype == TType.STRING then
        self.created_by = iprot:readString()
      else
        iprot:skip(ftype)
      end
    else
      iprot:skip(ftype)
    end
    iprot:readFieldEnd()
  end
  iprot:readStructEnd()
end

function M.FileMetaData:write(oprot)
  oprot:writeStructBegin('FileMetaData')
  if self.version ~= nil then
    oprot:writeFieldBegin('version', TType.I32, 1)
    oprot:writeI32(self.version)
    oprot:writeFieldEnd()
  end
  if self.schema ~= nil then
    oprot:writeFieldBegin('schema', TType.LIST, 2)
    oprot:writeListBegin(TType.STRUCT, #self.schema)
    for _,iter51 in ipairs(self.schema) do
      iter51:write(oprot)
    end
    oprot:writeListEnd()
    oprot:writeFieldEnd()
  end
  if self.num_rows ~= nil then
    oprot:writeFieldBegin('num_rows', TType.I64, 3)
    oprot:writeI64(self.num_rows)
    oprot:writeFieldEnd()
  end
  if self.row_groups ~= nil then
    oprot:writeFieldBegin('row_groups', TType.LIST, 4)
    oprot:writeListBegin(TType.STRUCT, #self.row_groups)
    for _,iter52 in ipairs(self.row_groups) do
      iter52:write(oprot)
    end
    oprot:writeListEnd()
    oprot:writeFieldEnd()
  end
  if self.key_value_metadata ~= nil then
    oprot:writeFieldBegin('key_value_metadata', TType.LIST, 5)
    oprot:writeListBegin(TType.STRUCT, #self.key_value_metadata)
    for _,iter53 in ipairs(self.key_value_metadata) do
      iter53:write(oprot)
    end
    oprot:writeListEnd()
    oprot:writeFieldEnd()
  end
  if self.created_by ~= nil then
    oprot:writeFieldBegin('created_by', TType.STRING, 6)
    oprot:writeString(self.created_by)
    oprot:writeFieldEnd()
  end
  oprot:writeFieldStop()
  oprot:writeStructEnd()
end

return M
