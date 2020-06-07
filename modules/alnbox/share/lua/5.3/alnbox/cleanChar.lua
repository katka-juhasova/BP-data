-- alnbox, alignment viewer based on the curses library
-- Copyright (C) 2015 Boris Nagaev
-- See the LICENSE file for terms of use

-- convert anything to byte code
return function(ch)
    if ch == '' then
        ch = ' '
    end
    if type(ch) == 'number' and ch >= 0 and ch < 10 then
        ch = tostring(ch)
    end
    if type(ch) == 'string' then
        ch = string.byte(ch)
    end
    if type(ch) ~= 'number' then
        ch = string.byte(' ')
    end
    return ch
end
