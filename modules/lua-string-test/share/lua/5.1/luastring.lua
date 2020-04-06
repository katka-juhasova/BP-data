local VERSION = '201709171' -- version history at end of file
local AUTHOR_NOTE = "-[ luastring.lua package by ldeveloperl1985 version 201709171 ]-"

local OBJDEF = {
    VERSION      = VERSION,
    AUTHOR_NOTE  = AUTHOR_NOTE,
}

function OBJDEF:echo ()
    print("String Testing");
end

function OBJDEF:echoSubString (str, start, no)
    return string.sub(str, start, no);
end

return OBJDEF;