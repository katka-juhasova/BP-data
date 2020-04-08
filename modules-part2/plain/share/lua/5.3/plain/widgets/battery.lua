---------------------------------------------------------------------------
-- @author Ivan Zinovyev <vanyazin@gmail.com>
-- @copyright 2017 Ivan Zinovyev 
-- @release 1.0.0
---------------------------------------------------------------------------

local Widget = require('plain.widgets.widget')

--- Battery widget.
-- plain.widget.battery
local Battery = {}
setmetatable(Battery, { __index = Widget })

--- Init base values and actions.
-- @return A widget instance.
function Battery:init()
  self:start_timer(5, function()
    self:refresh()
    self:redraw()
  end)
end

--- Refresh battery status.
function Battery:refresh()
  local fh = io.popen("acpi | awk -F'[ ,]' '{time = \" (\"$7\")\"; if ($3 == \"Charging\") status=\"CHR\"; else if ($3 == \"Full\") {status = \"FULL\"; time = \"\"} else status = \"BAT\"} {printf(\"%s %s\", status, $5)}'", "r")
  self.status = fh:read("*l") or 'Unknown'

  return self
end

return Battery 
