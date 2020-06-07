local DE = require('de')
math.randomseed( os.time() )

local n = 5 -- number of dimensions

local solver = DE.new(n, 40)
for i = 1, n do solver.limits[i] = {-500, 500} end
solver.cr = 0.5
solver.f  = 0.8

function solver.fitness(v) -- Schwefel's function
    local sum = 0
    
    for i = 1, n do
        sum = sum - v[i] * math.sin(math.abs(v[i])^0.5)
    end
    
    return -sum
end

solver:init()
local it, fit, best = solver:run(1000+n*500, 1e-6, 100+n*100)
for i = 1, n do best[i] = string.format("%.3f", best[i]) end
local should = 418.9829 * n

print( string.format([[
-------------------------------------------
| Iterations = %d
| fitness    = %.3f (should be %.3f)
| best       = (%s)
-------------------------------------------]], 
 it, fit, should, table.concat(best, ', ')))
