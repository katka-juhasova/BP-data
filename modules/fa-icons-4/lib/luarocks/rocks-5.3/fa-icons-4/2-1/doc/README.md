# lua-fa-icons-4

Font Awesome 4 Icons + Font for Lua

## Usage
```lua
local faicons = require 'fa-icons'

local famin, famax = faicons.min_range,  faicons.max_range
local apple = faicons 'apple'
local music = faicons(0xf001)
local globe = faicons.ICON_GLOBE

local font_data = faicons.get_font_data_base85()
```