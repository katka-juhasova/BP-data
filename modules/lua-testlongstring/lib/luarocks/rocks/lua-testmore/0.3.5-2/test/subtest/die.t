#! /usr/bin/lua

-- What happens when a subtest dies?

require 'Test.More'

local tb = require 'Test.Builder.NoOutput'.create()

tb:ok(true)

local r, msg = pcall(function ()
                tb:subtest('death', function ()
                                        error "Death in the subtest"
                                    end)
end)

nok(r)
like(msg, "die.t:13: Death in the subtest")
nok(tb.parent, "the parent object is restored after a die")

done_testing()

