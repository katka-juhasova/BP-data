local loaded = false
local bustedRunner = require "busted.runner"

return function(options)
  if loaded then return function() end else loaded = true end
  _G.DDLT_GLOBAL_ARGS = {
    r = options["recursive"],
    p = options["pattern"],
    d = options["directory"],
    ep = options["exclude-pattern"],
    root = options["ROOT"],
  }
  bustedRunner(options.bustedArgs)
end
