require"mininum"

local sin, cos, log, sqrt = math.sin, math.cos, math.log, math.sqrt
local eval

print("\nroot test\n")
local function f (x)
   eval = eval+1
   return x*(3+x*(-4+2*x))-- difficult for classical regula falsi
end

local errx = 1.0e-8
eval = 0
local x = mininum.root(f, -1, 1, errx)

print("calculated solution = ", x)
print("actual solution     = ", 0)
print("intended error      = ", errx)
print("actual absol. error = ", x)
print("function evaluations= ", eval)

--------------------------------------------------
print("\nderivative test\n")
local function g (x)
   eval = eval+1
   return sin(x)
end

eval = 0
local err = 1.0e-6
local d1 = mininum.derivative(g, 2, err)
local e1 = cos(2)

print("first derivative")
print("calculated solution = ", d1)
print("actual solution     = ", e1)
print("intended error      = ", err)
print("actual absol. error = ", d1-e1)
print("function evaluations= ", eval)

--------------------------------------------------
print("\nquadrature test\n")
local function s (x)
   eval = eval+1
   -- a difficult case for Romberg quadrature
   return 1/sqrt(x)
end

local rerr = 1.0e-5
eval = 0
local q = mininum.quadrature(s, 0, 0.5, rerr)
local e = 2*sqrt(0.5)

print("calculated solution = ", q)
print("actual solution     = ", e)
print("intended error      = ", rerr)
print("actual relat. error = ", (q-e)/e)
print("function evaluations= ", eval)
