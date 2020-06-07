local class = require 'stuart.class'

local SparkSession = class.new()

function SparkSession:_init(sparkContext, _, _, extensions)
  self.sparkContext = sparkContext
  self.extensions = extensions
  local DataFrameReader = require 'stuart-sql.DataFrameReader'
  self.read = DataFrameReader.new(self)
end

function SparkSession.builder()
  local Builder = require 'stuart-sql.SparkSession_Builder'
  return Builder.new()
end

function SparkSession.clearDefaultSession()
  SparkSession.defaultSession = nil
end

function SparkSession.getDefaultSession()
  return SparkSession.defaultSession
end

function SparkSession.setDefaultSession(session)
  SparkSession.defaultSession = session
end

return SparkSession
