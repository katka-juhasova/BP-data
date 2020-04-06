---------------------------------------------------------------------------
-- @author Ivan Zinovyev <vanyazin@gmail.com>
-- @copyright 2017 Ivan Zinovyev 
-- @release 1.0.0
---------------------------------------------------------------------------

local capi = { timer = timer }

--- Base plain widget.
-- plain.widget.widget
local Widget = {
  MOUSE_CLICK = 1,
  MOUSE_SCROLL_UP = 4,
  MOUSE_SCROLL_DOWN = 5,
  PROTO = {},
}

--- Define a prototype.
-- Should be called as a static method: Widget.__proto.
function Widget.__proto(proto)
  Widget.PROTO.wibox = proto.wibox
end

--- Create new widget.
-- @return A widget instance.
function Widget:new(...)
  local instance = {}
  setmetatable(instance, {
    __index = self,
    __call = function()
      return instance:get_widget()
    end,
  })
  instance:init(...)
  
  return instance 
end


--- Init base values and actions.
function Widget:init()
  return true
end

--- Mouse click callback 
function Widget:mouse_click()
end

--- Mouse scroll up callback
function Widget:mouse_up()
end

--- Mouse scroll down callback
function Widget:mouse_down()
end

--- Create a timer for repeating actions.
function Widget:start_timer(timeout, callback)
  if capi.timer then
    local timer = capi.timer { timeout = timeout }
    timer:connect_signal('timeout', callback)
    timer:start()
    timer:emit_signal('timeout')
  end
end

--- Initialize mouse events
function Widget:mouse_events(enable)
  if enable then
    widget = self:get_widget()
    if widget then
      widget:connect_signal('button::press', function(_tbl, _lx, _ly, button)
        if Widget.MOUSE_CLICK == button then
          event = true
          self:mouse_click()
        elseif Widget.MOUSE_SCROLL_UP == button then
          event = true
          self:mouse_up()
        elseif Widget.MOUSE_SCROLL_DOWN  == button then
          event = true
          self:mouse_down()
        end

        if event then
          self:refresh()
          self:redraw()
        end
      end)
    end
  end
end

--- Create a timer for repeating actions.
-- @return A string status.
function Widget:get_status()
  return self.status
end

--- Refresh widget status.
function Widget:refresh()
end

--- Refresh widget status.
function Widget:redraw()
  if self.widget then
    self.widget.markup = self.status
  end
end

--- Get widget instance.
function Widget:get_widget()
  if nil == self.widget and Widget.PROTO.wibox then
    self.widget = Widget.PROTO.wibox.widget{
      markup = self.status,
      align  = 'center',
      valign = 'center',
      widget = Widget.PROTO.wibox.widget.textbox
    }
  end

  return self.widget
end

return Widget
