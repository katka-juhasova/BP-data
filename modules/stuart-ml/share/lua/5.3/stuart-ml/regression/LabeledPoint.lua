local class = require 'stuart.class'

-- The features and labels of a data point.

local LabeledPoint = class.new()

function LabeledPoint:_init(label, features)
  self.label = label
  self.features = features
end

function LabeledPoint:__tostring()
  return '(' .. tostring(self.label) .. ',' .. tostring(self.features) .. ')'
end

function LabeledPoint:asML()
  return LabeledPoint.new(self.label, self.features)
end

function LabeledPoint.parse(s)
  local Vectors = require 'stuart-ml.linalg.Vectors'
  if s:sub(1,1) == '(' then
    local NumericParser = require 'stuart-ml.util.NumericParser'
    local parsed = NumericParser.parse(s)
    return LabeledPoint.new(parsed[1], Vectors.parseNumeric(parsed[2]))
  else -- dense format used before v1.0
    local moses = require 'moses'
    local util = require 'stuart.util'
    local NumericParser = require 'stuart-ml.util.NumericParser'
    local parts = util.split(s, ',')
    local function trim(s2) return (s2:gsub('^%s*(.-)%s*$', '%1')) end
    local label = NumericParser.parse(parts[1])
    local features = Vectors.dense(moses.map(util.split(trim(parts[2]), ' '), function(x) return NumericParser.parse(x) end))
    return LabeledPoint.new(label, features)
  end
end

return LabeledPoint
