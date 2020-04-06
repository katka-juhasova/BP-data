local class = require 'stuart.class'

local DataFrameReader = class.new()

function DataFrameReader:_init(sparkSession)
  self.sparkSession = sparkSession
end

function DataFrameReader:format(source)
  self.source = source
  return self
end

function DataFrameReader:schema(schema)
  self.userSpecifiedSchema = schema
  return self
end

function DataFrameReader:parquet(path)
  self:format('parquet')
  local fileSystemFactory = require 'stuart.fileSystemFactory'
  local fs, openPath = fileSystemFactory.createForOpenPath(path)
  if fs:isDirectory(openPath) then
    local fileStatuses = fs:listStatus(openPath)
    local rdds = {}
    for _,fileStatus in ipairs(fileStatuses) do
      local firstChar = fileStatus.pathSuffix:sub(1,1)
      if fileStatus.type == 'FILE'
        and firstChar ~= '.'
        and firstChar ~= '_'
        and fileStatus.pathSuffix:find('.parquet')
      then
        rdds[#rdds+1] = self:parquet(path .. '/' .. fileStatus.pathSuffix):rdd()
      end
    end
    local df = {
      rdd = function()
        return self.sparkSession.sparkContext:union(rdds)
      end
    }
    return df
  end
  
  local buffer = fs:open(openPath)
  local has_parquet, parquet = pcall(require, 'parquet')
  assert(has_parquet)
  local reader = parquet.ParquetReader.openString(buffer)
  local cursor = reader:getCursor()
  
  local data = {}
  while true do
    local row = cursor:next()
    if row == nil then break end
    local values = {}
    if row.point and row.point.values and row.point.values.list then
      for i=1,#row.point.values.list do
        values[#values+1] = row.point.values.list[i].element
      end
    end
    data[#data+1] = {row.id, values}
  end
  reader:close()
  
  local df = {
    rdd = function()
      return self.sparkSession.sparkContext:parallelize(data)
    end
  }
  return df
end

return DataFrameReader
