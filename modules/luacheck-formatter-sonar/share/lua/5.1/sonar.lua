local format = require('luacheck.format')
local rapidjson = require('rapidjson')

local sonar_error = {
  severity = "BLOCKER",
  type = "BUG",
}
local sonar_warning = {
  severity = "MAJOR",
  type = "CODE_SMELL",
}

local function is_error(event)
   return event.code:sub(1, 1) == "0"
end

local function capitalize(str)
   return str:gsub("^.", string.upper)
end

local function fatal_type(file_report)
   return capitalize(file_report.fatal) .. " error"
end

local function add_json_line(buf, text, comma)
  local final = comma and text..',' or text
  table.insert(buf, final)
end

local function build_primary_location(file_name, event)
  local has_end_column = event.endColumn and event.endColumn > event.column
  local message = format.get_message(event)
  return {
    message = message,
    filePath = file_name,
    textRange = {
      startLine = event.line,
      startColumn = event.column - 1,
      endColumn = has_end_column and (event.endColumn - 1) or nil,
    }
  }
end

local function build_secondary_locations(file_name, event)
  local has_secondary_locations = event.prev_line ~= nil
  if not has_secondary_locations then
    return nil
  end

  local has_prev_column = event.prev_column ~= nil
  local has_prev_end_column = has_prev_column and (event.prev_end_column and event.prev_end_column > event.prev_column)

  return {
    {
      message = event.name,
      filePath = file_name,
      textRange = {
        startLine = event.prev_line,
        startColumn = has_prev_column and (event.prev_column - 1) or nil,
        endColumn = has_prev_end_column and (event.prev_end_column - 1) or nil,
      }
    }
  }
end

local function sonar_issue(file_name, event)
  local category = is_error(event) and sonar_error or sonar_warning

   return {
    engineId = "luacheck",
    ruleId = event.code,
    severity = category.severity,
    type = category.type,
    effortMinutes = 2,
    primaryLocation = build_primary_location(file_name, event),
    secondaryLocations = build_secondary_locations(file_name, event)
  }
end

local function snoar_fatal(file_name, file_report)
  return {
    engineId = "luacheck",
    ruleId = "FATAL",
    severity = "BLOCKER",
    type = "BUG",
    effortMinutes = 2,
    primaryLocation = {
      message = fatal_type(file_report),
      filePath = format(file_name),
      textRange = {
        startLine = 1
      }
    }
  }
end

local function sonar(report, file_names)
   local issues = setmetatable({}, {__jsontype='array'})

  for i, file_report in ipairs(report) do
     local file_name = file_names[i]
     if file_report.fatal then
         issues[#issues+1] = snoar_fatal(file_name, file_report)
     else
        for event_i, event in ipairs(file_report) do
           local is_last_event = event_i == #file_report
           issues[#issues+1] = sonar_issue(file_name, event)
        end
     end
  end

  local report = {
    issues = issues
  }

  return rapidjson.encode(report, {pretty = true, sort_keys = true})
end

return sonar

