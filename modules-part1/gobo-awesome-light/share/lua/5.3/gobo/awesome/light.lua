
local light = {}

local awful = require("awful")
local wibox = require("wibox")
local gears = require("gears")
local timer = gears.timer or timer
local lgi = require("lgi")
local cairo = lgi.require("cairo")

local function draw_glow(cr, x, y, w, h, r, g, b, a, rad)
   local glow = cairo.Pattern.create_mesh()
   local function set_colors()
      glow:set_corner_color_rgba(0, r, g, b, a)
      glow:set_corner_color_rgba(1, r, g, b, 0)
      glow:set_corner_color_rgba(2, r, g, b, 0)
      glow:set_corner_color_rgba(3, r, g, b, a)
   end
   local function draw_side(x1, y1, x2, y2, x3, y3, x4, y4)
      glow:begin_patch()
      glow:move_to(x1, y1)
      glow:line_to(x2, y2)
      glow:line_to(x3, y3)
      glow:line_to(x4, y4)
      glow:line_to(x1, y1)
      set_colors()
      glow:end_patch()
   end
   draw_side(x, y, x-rad, y-rad, x-rad, y+h+rad, x, y+h) -- left
   draw_side(x, y, x-rad, y-rad, x+w+rad, y-rad, x+w, y) -- top
   draw_side(x+w, y, x+w+rad, y-rad, x+w+rad, y+h+rad, x+w, y+h) -- right
   draw_side(x+w, y+h, x+w+rad, y+h+rad, x-rad, y+h+rad, x, y+h) -- bottom
   cr:set_source(glow)
   cr:paint()
end

local function glow_rectangle(cr, x, y, w, h, r, g, b, a, rad)
   draw_glow(cr, x, y, w, h, r * 0.8, g * 0.8, b * 0.8, a, rad)
   cr:set_source_rgb(r, g, b)
   cr:rectangle(x, y, w, h)
   cr:fill()
end

local function draw_handle(cr, x, y, w, h)
   local pat = cairo.Pattern.create_linear(50, y, 50, y + h)
   pat:add_color_stop_rgb(0, 0.7, 0.8, 0.8)
   pat:add_color_stop_rgb(0.2, 0.5, 0.5, 0.5)
   pat:add_color_stop_rgb(0.8, 0.5, 0.5, 0.5)
   pat:add_color_stop_rgb(1, 0.3, 0.3, 0.3)
   cr:set_source(pat)
   cr:rectangle(x, y, w, h)
   cr:fill()
end

local function draw_icon(surface, state)

   local b = state.brightness / 100

   local cr = cairo.Context(surface)

   local gc = b -- * 0.8 + 0.2
   glow_rectangle(cr, 48, 10, 6, 80, gc, gc, gc * 0.8, 1.0, 5 + (b * 5))
   draw_handle(cr, 22, 10 + (60 * (1 - b)), 56, 20)

end

local function update_icon(widget, state)
   local image = cairo.ImageSurface("ARGB32", 100, 100)
   draw_icon(image, state)
   widget:set_image(image)
end

local function pread(cmd)
   local pd = io.popen(cmd, "r")
   if not pd then
      return ""
   end
   local data = pd:read("*a")
   pd:close()
   return data
end

function light.new()
   local widget = wibox.widget.imagebox()
   local state = {
      valid = false,
      brightness = 0,
   }

   local function update(cmd)
      local brightness = pread(cmd):match("^(%d+)")
      if not brightness then
         state.valid = false
         return
      end
      state.brightness = tonumber(brightness)
      update_icon(widget, state)
   end

   widget.inc_brightness = function(self, val)
      update("gobolight -inc "..val)
   end

   widget.dec_brightness = function(self, val)
      val = math.min(val, state.brightness - 1)
      update("gobolight -dec "..val)
   end

   local widget_timer = timer({timeout=10})
   widget_timer:connect_signal("timeout", function()
      update("gobolight")
   end)
   widget_timer:start()
   widget:buttons(awful.util.table.join(
      awful.button({ }, 1, function()
         mousegrabber.run(
            function(_mouse)
               if _mouse.buttons[1] then
                  update("gobolight " .. math.max(1, 100 - (_mouse.y * 4)))
                  return true
               end
               return false
            end,
            "fleur"
         )
      end),
      awful.button({ }, 3, function()
         if state.brightness == 1 then
            update("gobolight 100")
         elseif state.brightness <= 25 then
            update("gobolight 1")
         elseif state.brightness <= 50 then
            update("gobolight 25")
         elseif state.brightness <= 75 then
            update("gobolight 50")
         elseif state.brightness <= 100 then
            update("gobolight 75")
         end
      end),
      awful.button({ }, 4, function()
         widget:inc_brightness(5)
      end),
      awful.button({ }, 5, function()
         widget:dec_brightness(5)
      end)
   ))
   update("gobolight")
   widget:connect_signal("mouse::enter", function() update("gobolight") end)
   return widget
end

return light

