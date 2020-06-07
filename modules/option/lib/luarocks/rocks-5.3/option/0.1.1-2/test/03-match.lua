local Option = require("option")
local obj
local result


obj = Option("hello world")
result = obj:match(
  function(value)
    assert(value == "hello world")
    return 100
  end,
  function()
    error("Uh-oh!")
  end
)
assert(result == 100)

result = obj:match()
assert(result == nil)

result = obj:match(
  nil,
  function()
    error("Uh-oh!")
  end
)
assert(result == nil)


obj = Option()
result = obj:match(
  function(value)
    error("Oh dear... How did ".. value .." get in here?")
  end,
  function()
    return 99
  end
)
assert(result == 99)

result = obj:match(
  function(value)
    error("Oh dear... How did ".. value .." get in here?")
  end
)
assert(result == nil)
