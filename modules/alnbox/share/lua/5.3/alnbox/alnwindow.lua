-- alnbox, alignment viewer based on the curses library
-- Copyright (C) 2015 Boris Nagaev
-- See the LICENSE file for terms of use

-- starts interactive pager in curses window
-- Arguments:
-- 1. curses window
-- 2. table of properties:
--  * rows -- number of rows
--  * cols -- number of cols
--  * getCell -- function (row, col) -> table of fields:
--      character, foreground, background,
--      bold, blink, underline
--  * top_headers -- number of top header rows
--  * left_headers -- number of left header rows
--  * right_headers -- number of right header rows
--  * bottom_headers -- number of bottom header rows
--  * getTopHeader -- function(row, col) -> table of fields
--  * getLeftHeader -- function(row, col) -> table of fields
--  * getRightHeader -- function(row, col) -> table of fields
--  * getBottomHeader -- function(row, col) -> table of fields
--  * getTopLeft -- function(row, col) -> table of fields
--  * getTopRight -- function(row, col) -> table of fields
--  * getBottomLeft -- function(row, col) -> table of fields
--  * getBottomRight -- function(row, col) -> table of fields
-- Result:
-- Object with the following methods:
--  * drawAll
--  * moveTo(self, row, col)
--  * moveUp
--  * moveDown
--  * moveLeft
--  * moveRight
--  * moveUpEnd
--  * moveDownEnd
--  * moveRightEnd
--  * moveLeftEnd
return function(window, p)
    assert(p.rows >= 1)
    assert(p.cols >= 1)

    assert(not p.top_headers or p.getTopHeader)
    assert(not p.left_headers or p.getLeftHeader)
    assert(not p.bottom_headers or p.getBottomHeader)
    assert(not p.right_headers or p.getRightHeader)

    assert(p.getCell)

    local top_headers = p.top_headers or 0
    local left_headers = p.left_headers or 0
    local right_headers = p.right_headers or 0
    local bottom_headers = p.bottom_headers or 0

    -- enable hardware character insert/delete
    window:idcok()
    window:idlok()

    local win_rows, win_cols = window:getmaxyx()
    win_rows = math.min(win_rows, top_headers + p.rows + bottom_headers)
    win_cols = math.min(win_cols, left_headers + p.cols + right_headers)
    local table_rows = win_rows - top_headers - bottom_headers
    local table_cols = win_cols - left_headers - right_headers
    assert(table_rows >= 1)
    assert(table_cols >= 1)

    local start_row = 0
    local start_col = 0

    local function pgetCell(row, col)
        local top_header = row < top_headers
        local left_header = col < left_headers
        local bottom_header = row + bottom_headers >= win_rows
        local right_header = col + right_headers >= win_cols
        local row1 = start_row + row - top_headers
        local col1 = start_col + col - left_headers
        if top_header and left_header and p.getTopLeft then
            return p.getTopLeft(row, col)
        elseif top_header and right_header and p.getTopRight then
            local col2 = col - left_headers - table_cols
            return p.getTopRight(row, col2)
        elseif bottom_header and left_header and p.getBottomLeft then
            local row2 = row - top_headers - table_rows
            return p.getBottomLeft(row2, col)
        elseif bottom_header and right_header and p.getBottomRight then
            local row2 = row - top_headers - table_rows
            local col2 = col - left_headers - table_cols
            return p.getBottomRight(row2, col2)
        elseif (top_header or bottom_header) and
                (left_header or right_header) then
            return ' '
        elseif top_header then
            return p.getTopHeader(row, col1)
        elseif left_header then
            return p.getLeftHeader(row1, col)
        elseif bottom_header then
            local row2 = row - top_headers - table_rows
            return p.getBottomHeader(row2, col1)
        elseif right_header then
            local col2 = col - left_headers - table_cols
            return p.getRightHeader(row1, col2)
        else
            return p.getCell(row1, col1)
        end
    end

    local function drawCell(row, col)
        local putCell = require 'alnbox.putCell'
        local cell = pgetCell(row, col)
        putCell(window, row, col, cell)
    end

    local function drawAll()
        for row = 0, win_rows - 1 do
            for col = 0, win_cols - 1 do
                drawCell(row, col)
            end
        end
    end

    local function moveTo(self, row, col)
        row = math.max(row, 0)
        row = math.min(row, win_rows - 1)
        col = math.max(col, 0)
        col = math.min(col, win_cols - 1)
        start_row = row
        start_col = col
        drawAll()
    end

    local function moveUp()
        if start_row > 0 then
            start_row = start_row - 1
            --
            local removed_row = top_headers +
                table_rows - 1
            local new_row = top_headers
            window:move(removed_row, 0)
            window:deleteln()
            window:move(new_row, 0)
            window:insertln()
            --
            for col = 0, win_cols - 1 do
                drawCell(new_row, col)
            end
        end
    end

    local function moveDown()
        if start_row + table_rows < p.rows then
            start_row = start_row + 1
            --
            local removed_row = top_headers
            local new_row = top_headers +
                table_rows - 1
            window:move(removed_row, 0)
            window:deleteln()
            window:move(new_row, 0)
            window:insertln()
            --
            for col = 0, win_cols - 1 do
                drawCell(new_row, col)
            end
        end
    end

    local function moveLeft()
        if start_col > 0 then
            start_col = start_col - 1
            --
            local removed_col = left_headers +
                table_cols - 1
            local new_col = left_headers
            for row = 0, win_rows - 1 do
                window:move(row, removed_col)
                window:delch()
                window:move(row, new_col)
                window:winsch(' ')
                drawCell(row, new_col)
            end
        end
    end

    local function moveRight()
        if start_col + table_cols < p.cols then
            start_col = start_col + 1
            --
            local removed_col = left_headers
            local new_col = left_headers +
                table_cols - 1
            for row = 0, win_rows - 1 do
                window:move(row, removed_col)
                window:delch()
                window:move(row, new_col)
                window:winsch(' ')
                drawCell(row, new_col)
            end
        end
    end

    local function moveUpEnd()
        if start_row > 0 then
            start_row = 0
            drawAll()
        end
    end

    local function moveDownEnd()
        if start_row + table_rows < p.rows then
            start_row = p.rows - table_rows
            drawAll()
        end
    end

    local function moveLeftEnd()
        if start_col > 0 then
            start_col = 0
            drawAll()
        end
    end

    local function moveRightEnd()
        if start_col + table_cols < p.cols then
            start_col = p.cols - table_cols
            drawAll()
        end
    end

    return {
        drawAll = drawAll,
        moveTo = moveTo,
        moveUp = moveUp,
        moveDown = moveDown,
        moveRight = moveRight,
        moveLeft = moveLeft,
        moveUpEnd = moveUpEnd,
        moveDownEnd = moveDownEnd,
        moveRightEnd = moveRightEnd,
        moveLeftEnd = moveLeftEnd,
    }
end
