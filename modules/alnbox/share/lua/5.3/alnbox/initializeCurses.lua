-- alnbox, alignment viewer based on the curses library
-- Copyright (C) 2015 Boris Nagaev
-- See the LICENSE file for terms of use

-- initialize curses session, returns curses window
return function(curses)
    local stdscr = curses.initscr()
    curses.echo(false)
    curses.start_color()
    curses.raw(true)
    curses.curs_set(0)
    stdscr:nodelay(false)
    stdscr:keypad(true)

    -- TODO has_colors()
    local initializeColors = require 'alnbox.initializeColors'
    initializeColors(curses)

    stdscr:clear()

    return stdscr
end
