
--
-- lua-Silva : <https://fperrad.frama.io/lua-Silva/>
--

local modname = string.gsub(..., '%.%w+$', '')
local matcher = require(modname).array_matcher

return matcher(string.match)
--
-- Copyright (c) 2017-2019 Francois Perrad
--
-- This library is licensed under the terms of the MIT/X11 license,
-- like Lua itself.
--
