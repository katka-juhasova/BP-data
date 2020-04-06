--[[
    Visualization of the evolution process.
    Requires the lua-gnuplot [1] library.
    
    [1]: https://bitbucket.org/lucashnegri/lua-gnuplot
--]]

local de = require('de')
local gp = require('gnuplot')

math.randomseed( os.time() )

local solver = de.new(2, 40)
solver.limits[1] = {-5.12, 5.12}
solver.limits[2] = {-5.12, 5.12}

function solver.fitness(v) -- Banana' function
    local t1  = v[2] - v[1]*v[1]
    local t2  = 1 - v[1]
    return -(100 * t1*t1 + t2*t2)
end

local err_list = {}
local i = 0

function solver:step()
    de.step(self)
    table.insert(err_list, -self.fit[self.best])
    
    if i % 5 == 0 then
        local x, y, z = {}, {}, {}
        for i = 1, self.npop do
            table.insert(x, self.pop[i][1])
            table.insert(y, self.pop[i][2])
            table.insert(z, -self.fit[i])
        end
        
        gp{
            height     = 600,
            width      = 600,
            xlabel     = "x",
            ylabel     = "y",
            key        = "off",
            xrange     = "[-3 to 3]",
            yrange     = "[-3 to 3]",
            zrange     = "[0 to 12000]",
            isosamples = "30",
            
            data = {
                gp.gpfunc {
                    "100 * (y - x*x)*(y - x*x) + (1 - x)*(1 - x)"
                },
                gp.array {
                    {
                        x,
                        y,
                        z,
                    },
                    using = {1, 2, 3},
                    with  = 'points'
                }
            }
        }:splot( string.format('banana-iter%03d.png', i) )
    end
    
    i = i + 1
end

solver:init()
local it, fit, best = solver:run(1000, 1e-6, 50)

--- error plot
gp{
    xlabel   = "Iteration",
    ylabel   = "Mean Squared Error",
    key      = "off",
    
    data = {
        gp.array {
            {err_list},
            using = {1},
            with  = 'lines'
        }
    }
}:plot('banana-error.png')
