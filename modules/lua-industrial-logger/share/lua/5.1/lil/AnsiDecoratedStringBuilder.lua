local DebugLogger = require "lil.DebugLogger"

local CODE_MAP = 
{
    reset = 0,
    bold = 1,
    faint = 2,
    italic = 3,
    underline = 4,
    crossthrough = 9,
    black = 30,
    red = 31,
    green = 32,
    yellow = 33,
    blue = 34,
    magenta = 35,
    cyan = 36,
    white = 37,
    ["bright black"] = 90,
    ["bright red"] = 91,
    ["bright green"] = 92,
    ["bright yellow"] = 93,
    ["bright blue"] = 94,
    ["bright magenta"] = 95,
    ["bright cyan"] = 96,
    ["bright white"] = 97
}

local BACKGROUND_OFFSET = 10

local buildAnsiCodeString = function(code)
    DebugLogger.log("building ansi string with code = '%s'", code)
    return string.format("%s[%dm", string.char(27), code)
end

local AnsiDecoratedStringBuilder = function(subjectString)
    DebugLogger.log("building ansi decorated string with subjectString = '%s'", subjectString)

    local self = {}
    local resetString = buildAnsiCodeString(CODE_MAP.reset)

    self.modifier = function(modifierName)
        if modifierName then
            self.modifierCode = CODE_MAP[modifierName]
        end

        return self
    end

    self.foregroundColour = function(colour)
        if colour then
            self.foregroundCode = CODE_MAP[colour]
        end

        return self
    end

    self.backgroundColour = function(colour)
        if colour then
            self.backgroundCode = CODE_MAP[colour] + BACKGROUND_OFFSET
        end

        return self
    end

    self.build = function()
        local ansiDecoratedString = resetString

        if self.modifierCode then
            ansiDecoratedString = string.format("%s%s", ansiDecoratedString, buildAnsiCodeString(self.modifierCode))
        end

        if self.foregroundCode then
            ansiDecoratedString = string.format("%s%s", ansiDecoratedString, buildAnsiCodeString(self.foregroundCode))
        end

        if self.backgroundCode then
            ansiDecoratedString = string.format("%s%s", ansiDecoratedString, buildAnsiCodeString(self.backgroundCode))
        end

        return string.format("%s%s%s", ansiDecoratedString, subjectString, resetString)
    end

    return self
end

return AnsiDecoratedStringBuilder
