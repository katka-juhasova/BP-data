-- alnbox, alignment viewer based on the curses library
-- Copyright (C) 2015 Boris Nagaev
-- See the LICENSE file for terms of use

-- gets an alignment, return parameters for alnbox
return function(alignment, curses)
    local p = {}
    p.rows = #alignment.names
    assert(p.rows > 0)
    p.cols = 0
    local bottom_left = "consensus"
    p.getBottomLeft = function(_, col)
        local ch = bottom_left:sub(col + 1, col + 1)
        return {character = ch,
            bold = true,
        }
    end
    p.left_headers = #bottom_left
    for name, text in pairs(alignment.name2text) do
        p.cols = math.max(p.cols, #text)
        p.left_headers = math.max(p.left_headers, #name)
    end
    assert(p.cols > 0)
    local spaces = p.left_headers - #bottom_left
    bottom_left = (" "):rep(spaces) .. bottom_left
    p.left_headers = p.left_headers + 1
    p.getCell = function(row, col)
        local name = alignment.names[row + 1]
        local text = alignment.name2text[name]
        local ch = text:sub(col + 1, col + 1)
        -- assume DNA
        local dnaCells = require('alnbox.dnaCells')(curses)
        return {
            character = ch,
            foreground = curses.COLOR_BLACK,
            background = dnaCells[ch],
        }
    end
    p.getLeftHeader = function(row, col)
        local name = alignment.names[row + 1]
        return name:sub(col + 1, col + 1)
    end
    p.top_headers = 1
    p.getTopHeader = function(_, col)
        local columnDigit = require 'alnbox.columnDigit'
        return columnDigit(col, p.cols)
    end
    p.bottom_headers = 1
    p.getBottomHeader = function(_, col)
        local consensusChar = require 'alnbox.consensusChar'
        local ch, ident = consensusChar(col, alignment)
        local bg = curses.COLOR_WHITE
        local fg = curses.COLOR_BLACK
        if ident >= 0.9 then
            bg = curses.COLOR_BLACK
            fg = curses.COLOR_WHITE
        elseif ident >= 0.4 then
            bg = curses.COLOR_CYAN
            fg = curses.COLOR_BLACK
        end
        return {
            character = ch,
            background = bg,
            foreground = fg,
        }
    end
    return p
end
