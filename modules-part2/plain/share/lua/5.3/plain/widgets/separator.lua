---------------------------------------------------------------------------
-- @author Ivan Zinovyev <vanyazin@gmail.com>
-- @copyright 2017 Ivan Zinovyev 
-- @release 1.0.0
---------------------------------------------------------------------------

local Widget = require('plain.widgets.widget')

--- Separator widget.
-- plain.widget.battery
local Separator = {}
setmetatable(Separator, { __index = Widget })

--- Init base values and actions.
-- @return A widget instance.
function Separator:init(status)
  self.status = status or '$$' 
end

return Separator 
