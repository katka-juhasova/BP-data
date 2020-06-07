---------------------------------------------------------------------------
-- @author Ivan Zinovyev <vanyazin@gmail.com>
-- @copyright 2017 Ivan Zinovyev 
-- @release 1.0.0
---------------------------------------------------------------------------

local Widget = require('plain.widgets.widget')

--- Brightness widget.
-- plain.widget.brightness
local Brightness = { step = 15 }
setmetatable(Brightness, { __index = Widget })

--- Init base values and actions.
-- @return A widget instance.
function Brightness:init()
  self:mouse_events(true)
  self:start_timer(5, function()
    self:refresh()
    self:redraw()
  end)
end

--- Refresh battery status.
function Brightness:refresh()
  local fh = io.popen("xbacklight -get | awk '{print \"LGT \" int($0) \"%\"}' ", "r")
  self.status = fh:read("*l") or 'Unknown'

  return self
end

function Brightness:mouse_click()
  os.execute('amixer set Master toggle')
end

function Brightness:mouse_up()
  os.execute('xbacklight -inc ' .. tonumber(self.step))
end

function Brightness:mouse_down()
  os.execute('xbacklight -dec ' .. tonumber(self.step))
end

return Brightness 
