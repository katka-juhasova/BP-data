local DE = require('de')
math.randomseed( os.time() )

local solver = DE.new(2, 40)
solver.limits[1] = {-5.12, 5.12}
solver.limits[2] = {-5.12, 5.12}

function solver.fitness(v) -- Banana' function
    local t1  = v[2] - v[1]*v[1]
    local t2  = 1 - v[1]
    return -(100 * t1*t1 + t2*t2)
end

solver:init()
local it, fit, best = solver:run(1000, 1e-6, 50)

print( string.format([[
------------------------------
| Iterations = %d
| fitness    = %.6f
| x, y       = %.3f, %.3f
------------------------------]], it, fit, best[1], best[2]))
