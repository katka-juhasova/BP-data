-- alnbox, alignment viewer based on the curses library
-- Copyright (C) 2015 Boris Nagaev
-- See the LICENSE file for terms of use

-- based on npge/src/gui/AlignmentModel.cpp

-- returns a digit as a string
return function(section, length)
    local col = section + 1
    local next_10 = math.floor((col + 9) / 10) * 10
    if next_10 > length then
        return ' '
    end
    local digits_shift = next_10 - col;
    if digits_shift == 0 then
        return '0'
    end
    for i = 0, digits_shift - 1 do
        next_10 = math.floor(next_10 / 10)
    end
    if next_10 == 0 then
        return ' '
    end
    return tostring(next_10 % 10)
end
