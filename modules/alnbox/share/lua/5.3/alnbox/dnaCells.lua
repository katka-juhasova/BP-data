-- alnbox, alignment viewer based on the curses library
-- Copyright (C) 2015 Boris Nagaev
-- See the LICENSE file for terms of use

return function(curses)
    local dnaCells = {}
    return {
        A = curses.COLOR_GREEN,
        T = curses.COLOR_BLUE,
        G = curses.COLOR_RED,
        C = curses.COLOR_YELLOW,
        N = curses.COLOR_RED,
        ['-'] = curses.COLOR_WHITE,
    }
end
