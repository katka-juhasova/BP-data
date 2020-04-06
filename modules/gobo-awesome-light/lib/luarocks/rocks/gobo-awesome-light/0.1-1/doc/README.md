gobo-awesome-light
==================

A backlight widget for Awesome WM, designed for [http://gobolinux.org](GoboLinux).

Requirements
------------

* Awesome 3.5+
* [gobolight](http://github.com/gobolinux/GoboLight)
* `lode-fonts` for a nice-looking mixer pop-up :-)

Using
-----

Require the module:


```
local light = require("gobo.awesome.light")
```

Create the widget with `light.new()`:

```
local light_widget = light.new()
```

Then add it to your layout.
In a typical `rc.lua` this will look like this:


```
right_layout:add(light.new())
```

Additionally, add keybindings for your multimedia keys:

```
   awful.key({ }, "XF86MonBrightnessUp", function() light_widget:inc_brightness(5) end,
      {description = "Raise screen brightness", group = "multimedia"}
   ),
   awful.key({ }, "XF86MonBrightnessDown", function() light_widget:dec_brightness(5) end,
      {description = "Lower screen brightness", group = "multimedia"}
   ),
```

