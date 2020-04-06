
local base = require("ansi.base")

local term = {}


local csi = {
  moveUp = "A",
  moveDown = "B",
  moveBack = "C",
  moveFwd = "D",
  setPos = "H",
  eraseDisplay = "J",
  eraseLine = "K",
  scrollUp = "S",
  scrollDown = "T",
  saveCursor = "s",
  restoreCursor = "u"
}

term.erase = {
  cursorToEnd = 0,
  cursorToStart = 1,
  all = 2
}


function term.moveUp(lines, handle)
  return base.buildCode({ lines }, csi.moveUp, handle)
end

function term.moveDown(lines, handle)
  return base.buildCode({ lines }, csi.moveDown, handle)
end

function term.moveBack(cols, handle)
  return base.buildCode({ lines }, csi.moveBack, handle)
end

function term.moveFwd(cols, handle)
  return base.buildCode({ cols }, csi.moveFwd, handle)
end

function term.setCursor(line, col, handle)
  return base.buildCode({ line, col }, csi.setPos, handle)
end

function term.eraseDisplay(mode, handle)
  return base.buildCode({ mode }, csi.eraseDisplay, handle)
end

function term.eraseScreen(mode, handle)
  return base.buildCode({ mode }, csi.eraseScreen, handle)
end

function term.scrollUp(lines, handle)
  return base.buildCode({ lines }, csi.scrollUp, handle)
end

function term.scrollDown(lines, handle)
  return base.buildCode({ lines }, csi.scrollDown, handle)
end

function term.saveCursor(handle)
  return base.buildCode(nil, csi.saveCursor, handle)
end

function term.restoreCursor(handle)
  return base.buildCode(nil, csi.restoreCursor, handle)
end


function term.clearScreen(handle)
  return term.eraseScreen(term.erase.all)
end

return term

