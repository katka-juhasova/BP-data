-- alnbox, alignment viewer based on the curses library
-- Copyright (C) 2015 Boris Nagaev
-- See the LICENSE file for terms of use

-- See ROTE lib, file demo/boxshell.c
return function(curses)
    for foreground = 0, 7 do
        for background = 0, 7 do
            if foreground ~= 7 or background ~= 0 then
                local makePair = require 'alnbox.makePair'
                local pair = makePair(foreground, background)
                curses.init_pair(pair, foreground, background)
            end
        end
    end
end
