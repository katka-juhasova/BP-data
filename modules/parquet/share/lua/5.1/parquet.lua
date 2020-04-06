local reader = require 'parquet.reader'
local schema = require 'parquet.schema'
local shredder = require 'parquet.shred'

local M = {
  ParquetReader = reader.ParquetReader,
  ParquetSchema = schema.ParquetSchema,
  ParquetShredder = shredder
}

return M
