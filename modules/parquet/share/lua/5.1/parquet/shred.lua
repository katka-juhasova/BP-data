local Long = require 'long'
local parquet_types = require 'parquet.types'
local parquet_util = require 'parquet.util'

local M, _M = {}, {}

_M.shredRecordInternal = function(fields, record, data, rlvl, dlvl)
  for fieldName in pairs(fields) do
    local field = fields[fieldName]
    local fieldType = field.originalType or field.primitiveType
    local fieldPath = table.concat(field.path,',')

    -- fetch values
    local values = {}
    if record and record[fieldName] then
      if parquet_util.isArray(record[fieldName]) then
        values = record[fieldName]
      else
        parquet_util.arrayPush(values, record[fieldName])
      end
    end

    -- check values
    if #values == 0 and record and field.repetitionType == 'REQUIRED' then
      error('missing required field: ' .. field.name)
    end

    if #values > 1 and field.repetitionType ~= 'REPEATED' then
      error('too many values for field: ' .. field.name)
    end

    -- push null
    if #values == 0 then
      if field.isNested then
        _M.shredRecordInternal(
            field.fields,
            nil,
            data,
            rlvl,
            dlvl)
      else
        parquet_util.arrayPush(data[fieldPath].rlevels, rlvl)
        parquet_util.arrayPush(data[fieldPath].dlevels, dlvl)
        data[fieldPath].count = data[fieldPath].count + 1
      end
      
    else
    
      -- push values
      for i=1,#values do
        local rlvl_i
        if i == 1 then rlvl_i = rlvl else rlvl_i = field.rLevelMax end
  
        if field.isNested then
          _M.shredRecordInternal(
              field.fields,
              values[i],
              data,
              rlvl_i,
              field.dLevelMax)
        else
          parquet_util.arrayPush(data[fieldPath].values, parquet_types.toPrimitive(fieldType, values[i]))
          parquet_util.arrayPush(data[fieldPath].rlevels, rlvl_i)
          parquet_util.arrayPush(data[fieldPath].dlevels, field.dLevelMax)
          data[fieldPath].count = data[fieldPath].count + 1
        end
      end
      
    end
  end
end

--[[
 * 'Shred' a record into a list of <value, repetition_level, definition_level>
 * tuples per column using the Google Dremel Algorithm..
 *
 * The buffer argument must point to an object into which the shredded record
 * will be returned. You may re-use the buffer for repeated calls to this function
 * to append to an existing buffer, as long as the schema is unchanged.
 *
 * The format in which the shredded records will be stored in the buffer is as
 * follows:
 *
 *   buffer = {
 *     columnData: [
 *       'my_col': {
 *          dlevels: [d1, d2, .. dN],
 *          rlevels: [r1, r2, .. rN],
 *          values: [v1, v2, .. vN],
 *        }, ...
 *      ],
 *      rowCount: X,
 *   }
 *
--]]
M.shredRecord = function(schema, record, buffer)
  -- shred the record, this may raise an error
  local recordShredded = {}
  for _,field in pairs(schema.fieldList) do
    local fieldPath = table.concat(field.path,',')
    recordShredded[fieldPath] = {
      dlevels={},
      rlevels={},
      values={},
      count=0
    }
  end

  _M.shredRecordInternal(schema.fields, record, recordShredded, 0, 0)

  -- if no error during shredding, add the shredded record to the buffer
  if buffer.columnData == nil or buffer.rowCount == nil then
    buffer.rowCount = 0
    buffer.columnData = {}

    for _,field in pairs(schema.fieldList) do
      local fieldPath = table.concat(field.path,',')
      buffer.columnData[fieldPath] = {
        dlevels={},
        rlevels={},
        values={},
        count=0
      }
    end
  end

  buffer.rowCount = buffer.rowCount + 1
  for _,field in pairs(schema.fieldList) do
    local fieldPath = table.concat(field.path,',')
    local columnDataForFieldPath = buffer.columnData[fieldPath]
    local recordShreddedForFieldPath = recordShredded[fieldPath]
     
    parquet_util.arrayPush(columnDataForFieldPath.rlevels, recordShreddedForFieldPath.rlevels)
    parquet_util.arrayPush(columnDataForFieldPath.dlevels, recordShreddedForFieldPath.dlevels)
    parquet_util.arrayPush(columnDataForFieldPath.values, recordShreddedForFieldPath.values)
    columnDataForFieldPath.count = columnDataForFieldPath.count + recordShredded[fieldPath].count
  end
end

_M.materializeRecordField = function(record, branch, rLevels, dLevel, value)
  local node = branch[1]

  if dLevel < node.dLevelMax then return end

  if #branch > 1 then
    if node.repetitionType == "REPEATED" then
      if record[node.name] == nil then
        record[node.name] = {}
      end

      while #record[node.name] < rLevels[1] + 1 do
        record[node.name][#record[node.name]+1] = {}
      end
      
      _M.materializeRecordField(
        record[node.name][rLevels[1]+1],
        parquet_util.slice(branch, 2),
        parquet_util.slice(rLevels, 2),
        dLevel,
        value)
    else
      record[node.name] = record[node.name] or {}

      _M.materializeRecordField(
          record[node.name],
          parquet_util.slice(branch, 2),
          rLevels,
          dLevel,
          value)
    end
  else
    if node.repetitionType == "REPEATED" then
      if record[node.name] == nil then
        record[node.name] = {}
      end

      while #record[node.name] < rLevels[1] + 1 do
        parquet_util.arrayPush(record[node.name], math.huge) -- Lua doesn't support nil table values
      end

      record[node.name][rLevels[1] + 1] = value
    else
      record[node.name] = value
    end
  end
end

--[[
 * 'Materialize' a list of <value, repetition_level, definition_level>
 * tuples back to nested records (objects/arrays) using the Google Dremel
 * Algorithm..
 *
 * The buffer argument must point to an object with the following structure (i.e.
 * the same structure that is returned by shredRecords):
 *
 *   buffer = {
 *     columnData: [
 *       'my_col': {
 *          dlevels: [d1, d2, .. dN],
 *          rlevels: [r1, r2, .. rN],
 *          values: [v1, v2, .. vN],
 *        }, ...
 *      ],
 *      rowCount: X,
 *   }
 *
--]]
M.materializeRecords = function(schema, buffer)
  local records = {}
  local rowCount = buffer.rowCount
  if parquet_util.isInstanceOf(rowCount, Long) then rowCount = rowCount:toInt() end
  for i=1,rowCount do
    records[i] = {}
  end

  for k in pairs(buffer.columnData) do
    local field = schema:findField(k)
    local fieldBranch = schema:findFieldBranch(k)
    local columnData = buffer.columnData[k]
    local valuesIter = parquet_util.iterator(columnData.values)

    local rLevels = {}
    for i=1,field.rLevelMax+1 do rLevels[i] = 0 end

    for i=1,buffer.columnData[k].count do
      local dLevel = columnData.dlevels[i]
      local rLevel = columnData.rlevels[i]
      
      rLevels[rLevel+1] = rLevels[rLevel+1] + 1
      for j=rLevel+2,#rLevels do rLevels[j] = 0 end
      
      local value
      if dLevel == field.dLevelMax then
        value = parquet_types.fromPrimitive(
          field.originalType or field.primitiveType,
          valuesIter())
      end
    
      _M.materializeRecordField(
        records[rLevels[1]],
        fieldBranch,
        parquet_util.slice(rLevels, 2),
        dLevel,
        value)
      
    end
  end

  return records
end

return M
