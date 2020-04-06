-- alnbox, alignment viewer based on the curses library
-- Copyright (C) 2015 Boris Nagaev
-- See the LICENSE file for terms of use

-- starts curses session and the interactive pager
-- See arguments of alnbox.alnwindow
-- Additional property: navigate
-- Usage: alnbox {rows=5, cols=5,
--     getCell = function() return {character='5'} end,
--   }
return function(p)
    local curses = require 'curses'
    local initializeCurses = require 'alnbox.initializeCurses'
    local stdscr = initializeCurses(curses)

    local alnwindow = require 'alnbox.alnwindow'
    local win = alnwindow(stdscr, p)

    local navigate = p.navigate or require 'alnbox.navigate'
    local refresh = function() stdscr:refresh() end
    local getch = function() return stdscr:getch() end
    navigate(win, refresh, getch, nil, curses)

    curses.endwin()
end
