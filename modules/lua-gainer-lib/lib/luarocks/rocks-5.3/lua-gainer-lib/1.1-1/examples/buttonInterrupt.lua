local gainer = require 'gainer'

---
-- Example for using button interrupt to control on-board LED on gainer device.

local board = gainer.new()

local prevButtonState = false

local function buttonChanged(data)
  print("Button:", data)
  if data ~= prevButtonState then
    if data == true then
    board:digitalWrite(gainer.HIGH, gainer.LED)
    else
    board:digitalWrite(gainer.LOW, gainer.LED)
    end
  end
  prevButtonState = data
end

local function setup()
  board:init()
  board:attatchInterrupt("button", buttonChanged)
end

local function loop()
 -- Wait to not clog the CPU
 gainer.sleep(0.01)
end

board:start(setup, loop)