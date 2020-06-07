local class = require 'stuart.class'

--[[
  A local matrix.
--]]
local Matrix = class.new()

function Matrix:_init()
  -- Flag that keeps track whether the matrix is transposed or not. False by default.
  self.isTransposed = false
end

function Matrix:__tostring()
  return self:toString()
end

--[[
  Convenience method for `Matrix`-`DenseVector` multiplication. For binary compatibility.
--]]
function Matrix:multiply()
   error('NIY')
end

-- Converts to a dense array in column major
function Matrix:toArray()
  local moses = require 'moses'
  local newArray = moses.zeros(self.numRows + self.numCols)
  self:foreachActive(function(i, j, v)
    newArray[1 + j * self.numRows + i] = v
  end)
  return newArray
end

-- A human readable representation of the matrix
-- https://github.com/scalanlp/breeze/blob/releases/v0.13.1/math/src/main/scala/breeze/linalg/Matrix.scala#L68-L122
function Matrix:toString(maxLines, maxWidth)
  maxLines = maxLines or 80
  maxWidth = maxWidth or 80
  local showRows
  if self.numRows > maxLines then
    showRows = maxLines-1
  else
    showRows = self.numRows
  end
  
  local moses = require 'moses'
  local function colWidth(col)
    if showRows > 0 then
      local maxColWidth = 0
      for row = 0, showRows-1 do
        local v = self:get(row,col)
        if v == nil then
          maxColWidth = math.max(maxColWidth, 3)
        else
          maxColWidth = math.max(maxColWidth, 2 + #tostring(v))
        end
      end
      return maxColWidth
    else
      return 0
    end
  end
  
  local colWidths = {}
  do
    local col = 0
    while col < self.numCols and moses.sum(colWidths) < maxWidth do
      colWidths[#colWidths+1] = colWidth(col)
      col = col + 1
    end
  end
    
  -- make space for "... (K total)"
  if #colWidths < self.numCols then
    while moses.sum(colWidths) + #string.format('%d', self.numCols)+12 >= maxWidth do
      if #colWidths == 0 then
        return string.format('%d x %d matrix', self.numRows, self.numCols)
      end
      table.remove(colWidths, #colWidths)
    end
  end
  
  local rv = ''
  for row = 0, showRows-1 do
    for col = 0, #colWidths-1 do
      local cell
      local cellValue = self:get(row, col)
      if cellValue == nil then
        cell = '--'
      else
        cell = tostring(cellValue)
      end
      rv = rv .. cell
      rv = rv .. string.rep(' ', colWidths[col+1] - #cell)
      if col == #colWidths-1 then
        if col < self.numCols-1 then
          rv = rv .. '...'
          if row == 0 then
            rv = rv .. string.format(' (%d total)', self.numCols)
          end
        end
        if row+1 < showRows then
          rv = rv .. '\n'
        end
      end
    end
  end
  
  if self.numRows > showRows then
    rv = rv .. string.format('\n... (%d total)', self.numRows)
  end
  
  return rv
end

return Matrix
