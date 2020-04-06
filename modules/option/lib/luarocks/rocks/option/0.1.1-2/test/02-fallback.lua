local Option = require("option")
local opt

opt = Option("hello")
  :fallback(100)
  :fallback(nil)
assert( opt:unwrap() == "hello" )

opt = Option(nil)
  :fallback("hello")
  :fallback(100)
assert( opt:unwrap() == "hello" )

opt = Option(nil)
  :fallback(100)
  :fallback("hello")
assert( opt:unwrap() == 100 )

opt = Option(nil)
  :fallback(nil)
assert( opt:is_none() )
