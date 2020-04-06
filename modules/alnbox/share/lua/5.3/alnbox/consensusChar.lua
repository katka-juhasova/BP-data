-- alnbox, alignment viewer based on the curses library
-- Copyright (C) 2015 Boris Nagaev
-- See the LICENSE file for terms of use

-- return consensus char + identity of a column
return function(col, alignment)
    local ch2count = {}
    for name, text in pairs(alignment.name2text) do
        local ch = text:sub(col + 1, col + 1)
        if ch == '' then
            ch = '-'
        end
        ch2count[ch] = (ch2count[ch] or 0) + 1
    end
    local mostCh = ' '
    local groups = 0
    for ch, count in pairs(ch2count) do
        groups = groups + 1
        if ch ~= '-' then
            local c1 = ch2count[ch] or 0
            local c0 = ch2count[mostCh] or 0
            -- if counts are equal then wins
            -- the character with lesser byte number
            local prior = string.byte(ch) < string.byte(mostCh)
            if (c1 > c0) or (c1 == c0 and prior) then
                mostCh = ch
            end
        end
    end
    local identity = 0
    if groups == 1 then
        identity = 1
    elseif groups == 2 and ch2count['-'] then
        identity = 0.5
    end
    return mostCh, identity
end
