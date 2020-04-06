package = "rpi-gpio"
version = "0.2-1"
source = {
    url = "https://github.com/Tieske/rpi-gpio/archive/lua_version_0.2.tar.gz",
    dir = "rpi-gpio-lua_version_0.2",
}
description = {
   summary = "Lua module to control the GPIO on a Raspberry Pi",
   detailed = [[
      This package provides a Lua module to control the GPIO on a Raspberry Pi.
      The main functionality is provided by the RPi.GPIO Python Module of Ben 
      Croston, and the Lua binding was continued upon the work of Andre Simon.
      Additional modules migrated from Adafruit python code.
   ]],
   homepage = "https://github.com/Tieske/rpi-gpio",
   license = "MIT"
}
dependencies = {
   "lua >= 5.1, < 5.2",
   "bit32",
   "copastimer >= 1.0", -- pulls in copas, luasocket, coxpcall
}
build = {
  type = "builtin",
  modules = {
    -- Main GPIO module
    ["GPIO"] = {
      sources = {
        "lua/RPi_GPIO_Lua_module.c",
        "lua/darksidesync_aux.c",
        "source/c_gpio.c",
        "source/cpuinfo.c",
        "source/event_gpio.c",
        "source/soft_pwm.c",
      },
      libraries = {
        "pthread"
      },
      incdirs = {
        "source",
        "lua",
      },
    },
    -- additional Lua code files
    ["GPIO.lcd-hd44780"] = "lua/module/lcd-hd44780.lua",
  },
}
