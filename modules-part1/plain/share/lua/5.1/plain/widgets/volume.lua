---------------------------------------------------------------------------
-- @author Ivan Zinovyev <vanyazin@gmail.com>
-- @copyright 2017 Ivan Zinovyev 
-- @release 1.0.0
---------------------------------------------------------------------------

local Widget = require('plain.widgets.widget')

--- Volume widget.
-- plain.widget.volume
local Volume = {
  step = 3
}
setmetatable(Volume, { __index = Widget })

--- Init base values and actions.
-- @return A widget instance.
function Volume:init()
  self:mouse_events(true)
  self:start_timer(5, function()
    self:refresh()
    self:redraw()
  end)
end

--- Refresh battery status.
function Volume:refresh()
  local fh = io.popen("amixer get Master | grep '%' | head -1 | awk -F'[][]' '{status = \"MUTE\"; if ($4 == \"on\" || $6 == \"on\") { status = \"VOL\" } else {}; print status\" \"$2}'", "r")
  self.status = fh:read("*l") or 'Unknown'

  return self
end

function Volume:mouse_click()
  os.execute('amixer set Master toggle')
end

function Volume:mouse_up()
  os.execute('amixer set Master ' .. tonumber(self.step) .. '%+')
end

function Volume:mouse_down()
  os.execute('amixer set Master ' .. tonumber(self.step) .. '%-')
end

return Volume 
