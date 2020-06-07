--[[
=================================================================
*
* Copyright (c) 2013-2014 Lucas Hermann Negri
*
* Permission is hereby granted, free of charge, to any person
* obtaining a copy of this software and associated documentation files
* (the "Software"), to deal in the Software without restriction,
* including without limitation the rights to use, copy, modify,
* merge, publish, distribute, sublicense, and/or sell copies of the
* Software, and to permit persons to whom the Software is furnished
* to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be
* included in all copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
* EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
* MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
* NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
* BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
* ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
* CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*
* ==================================================================
--]]

local DE = {}
local DEmt = {__index = DE}

---
-- Creates a new differential evolution solver state. Parameters can be set by setting the
-- keys 'cr', 'f', 'f_min' and 'f_max'.
--
-- @param ndim Number of dimensions
-- @param npop Population size
-- @return New solver instance
function DE.new(ndim, npop)
    assert(ndim >= 1)
    assert(npop >= 3)

    local self = {}
    setmetatable(self, DEmt)
    
    self.ndim = ndim
    self.npop = npop or ndim * 10
    
    -- initialization limits
    self.limits = {}
    for d = 1, ndim do
        self.limits[d] = {-1, 1}
    end
    
    -- parameters
    self.cr = 0.9
    self.f  = nil -- nil to be random between f_min and f_max; 0.8 is also a good choice
    self.f_min, self.f_max = 0.4, 0.95
    
    return self
end

local function rnd_range(a, b)
    return math.random() * (b - a) + a
end

---
-- Creates a new random individual, respecting the limits
--
-- @return New individual
function DE:random_individual()
    local ind = {}
    
    for d = 1, self.ndim do
        ind[d] = rnd_range(self.limits[d][1], self.limits[d][2])
    end
    
    return ind
end

---
-- Initializes the solver state with a random population
function DE:init()
    self.pop   = {}
    self.fit   = {}
    self.trial = {}
    self.best  = 1
    
    for p = 1, self.npop do
        self.pop[p] = self:random_individual()
        self.fit[p] = self.fitness(self.pop[p], self.ud)
        
        if self.fit[p] > self.fit[self.best] then
            self.best = p
        end
    end
end

---
-- Samples the population to selecte the individual that will generate
-- the offspring.
--
-- @return List with three (distinct) selected individuals
function DE:sample(i)
    local a, b, c
    repeat a = math.random(1, self.npop) until a ~= i
    repeat b = math.random(1, self.npop) until b ~= a
    repeat c = math.random(1, self.npop) until c ~= b
    
    return {self.pop[a], self.pop[b], self.pop[c]}
end

local function limit(v, a, b)
    if v < a then return a end
    if v > b then return b end
    return v;
end

---
-- Creates a new individual by using samples from the population
--
-- @param samples Samples to combine (by default combines 3)
-- @return New trial individual
function DE:mutation(samples)
    local a, b, c = samples[1], samples[2], samples[3]
    local trial   = {}
    local f       = self.f or rnd_range(self.f_min, self.f_max)
    
    for d = 1, self.ndim do
        local l  = self.limits[d]
        trial[d] = limit(a[d] + f * (b[d] - c[d]), l[1], l[2])
    end
    
    return trial
end

---
-- Exchanges components between an old and a trial individual
--
-- @param x     Old individual
-- @param trial Trial individual (will be modified inplace)
-- @return Modified trial individual
function DE:crossover(x, trial)
    for d = 1, self.ndim do
        if math.random() > self.cr then
            local l  = self.limits[d]
            trial[d] = limit(x[d], l[1], l[2])
        end
    end

    return trial
end

---
-- Performs one iteration step.
function DE:step()
    -- generate trial individuals
    for i = 1, self.npop do
        self.trial[i] = self:crossover(
            self.pop[i],
            self:mutation( self:sample(i) )
        )
    end
    
    -- substitute iff the trial is beter than i
    for i = 1, self.npop do
        local trial_fit = self.fitness(self.trial[i], self.ud)
        if trial_fit > self.fit[i] then
            self.fit[i] = trial_fit
            self.pop[i] = self.trial[i]
            
            -- track the best one
            if trial_fit > self.fit[self.best] then self.best = i end
        end
    end
end

---
-- Runs the solver, with a maximum limit of iterations.
--
-- @param niters Maximum number of iterations
-- @return Best solution and its fitness
function DE:run(niters, min_delta, max_stuck)
    local last_fit, it, stuck = -1/0, 0, 0
    
    -- default parameters
    niters    = niters    or 10000
    min_delta = min_delta or 0
    max_stuck = max_stuck or niters / 10
    
    while it < niters do
        self:step()
        
        local delta = self.fit[self.best] - last_fit
        if delta < min_delta then
            stuck = stuck + 1
            if stuck > max_stuck then break end
        else
            stuck = 0
        end
        
        last_fit = self.fit[self.best]
        it       = it + 1
    end
    
    return it, self.fit[self.best], self.pop[self.best] 
end

return DE
