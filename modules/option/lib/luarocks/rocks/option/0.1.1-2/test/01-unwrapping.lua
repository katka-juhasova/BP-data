local Option = require("option")
local opt

opt = Option(15)
assert( opt:unwrap() == 15)
assert( opt:expect() == 15)
assert( opt:unwrap_or(100) == 15)

opt = Option()
assert( opt:unwrap() == nil)
assert( opt:unwrap_or(100) == 100)
assert( opt:unwrap_or_else(function() return 100 end) == 100)
