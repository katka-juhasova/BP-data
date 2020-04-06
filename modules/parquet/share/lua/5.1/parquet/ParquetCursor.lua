local class = require 'middleclass'
local parquet_shredder = require 'parquet.shred'

--[[
 * A parquet cursor is used to retrieve rows from a parquet file in order
--]]
local ParquetCursor = class('parquet.ParquetCursor')

--[[
 * Create a new parquet reader from the file metadata and an envelope reader.
 * It is usually not recommended to call this constructor directly except for
 * advanced and internal use cases. Consider using getCursor() on the
 * ParquetReader instead
--]]
function ParquetCursor:initialize(metadata, envelopeReader, schema, columnList)
  self.metadata = metadata
  self.envelopeReader = envelopeReader
  self.schema = schema
  self.columnList = columnList
  self.rowGroup = {}
  self.rowGroupIndex = 0
end

--[[
 * Retrieve the next row from the cursor. Returns a row or NULL if the end
 * of the file was reached
--]]
function ParquetCursor:next()
  if #self.rowGroup == 0 then
    if self.rowGroupIndex >= #self.metadata.row_groups then return nil end
  
    local rowBuffer = self.envelopeReader:readRowGroup(
      self.schema,
      self.metadata.row_groups[self.rowGroupIndex + 1],
      self.columnList)
  
    self.rowGroup = parquet_shredder.materializeRecords(self.schema, rowBuffer)
    self.rowGroupIndex = self.rowGroupIndex + 1
  end
  return table.remove(self.rowGroup, 1)
end

--[[
 * Rewind the cursor the the beginning of the file
--]]
function ParquetCursor:rewind()
  self.rowGroup = {}
  self.rowGroupIndex = 0
end

return ParquetCursor
