local Option = require("option")
local opt

opt = Option(10)
assert(opt:is_some())

opt = Option("hello world")
assert(opt:is_some())

opt = Option(false)
assert(opt:is_some())

opt = Option(true)
assert(opt:is_some())

opt = Option( {} )
assert(opt:is_some())


opt = Option()
assert(opt:is_none())

opt = Option(nil)
assert(opt:is_none())

