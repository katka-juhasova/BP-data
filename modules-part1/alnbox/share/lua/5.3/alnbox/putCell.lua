-- alnbox, alignment viewer based on the curses library
-- Copyright (C) 2015 Boris Nagaev
-- See the LICENSE file for terms of use

-- take a table with a cell properties
-- draw the cell on the window
return function(window, row, col, cell)
    local curses = require 'curses'
    if type(cell) ~= 'table' then
        cell = {character=cell}
    end
    window:move(row, col)
    local fg = cell.foreground or curses.COLOR_WHITE
    local bg = cell.background or curses.COLOR_BLACK
    local makePair = require 'alnbox.makePair'
    local pair = makePair(fg, bg)
    window:attrset(curses.color_pair(pair))
    if cell.bold then
        window:attron(curses.A_BOLD)
    end
    if cell.blink then
        window:attron(curses.A_BLINK)
    end
    if cell.underline then
        window:attron(curses.A_UNDERLINE)
    end
    local cleanChar = require 'alnbox.cleanChar'
    window:addch(cleanChar(cell.character))
end
