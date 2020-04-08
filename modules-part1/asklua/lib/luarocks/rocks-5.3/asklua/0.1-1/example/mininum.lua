--[[
  A simple numerical library
  (only for describing the use of help module "ask")

  Author: Julio Manuel Fernandez-Diaz
  Date:   Feb 10, 2010
  (For Lua 5.1)

  Error messages are displayed in stderr
--]]

-- PACKAGE: mininum

-- change this line if help system has other name
local HELPNAME = "ask"

module(..., package.seeall)

-- help information

_H = {_Name = ...,
_CHARSET =  "iso-8859-15", -- modify this for other cases, v.g., "utf-8"
_basic = [[`mininum` is a **mini**mal **num**erical library (with only three
functions), developed for accompanying the `]]..HELPNAME..[[` helping system. The
purpose is only to serve as an example.

`mininum` displays error messages in stderr.

Note: this library is very simple, and it is not intended
for heavy calculation (but it is usable).

Call `]]..HELPNAME..[["<function>"` for information on `<function>`.]],
_version = [[by Julio M. Fernández-Díaz, Dept. of Physics,
University of Oviedo, Spain, Version 0.1, February 2010

julio a t uniovi d o t es]],
_notes = [[THIS CODE IS HEREBY PLACED IN PUBLIC DOMAIN.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR
OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.]]
}

-- some private functions and data

local max, abs, floor = math.max, math.abs, math.floor

_H.root = {
_basic = [[Determines a root of a function between two abscissas]],
_usage = [[`mininum.root(f, a, b, errx)`

@params:

1. `f`: function of a real variable, of which we want the root,
   _x_ such that _f(x) = 0_.

2. `a`: number.

3. `b`: number. The root is searched between the abscissas `a` and `b`.

4. `errx`: number (optional). The function returns a value when 
   the difference between two successive approximations of the
   root is less than `errx` (in absolute value). 
   If no value is provided for `errx`, then 1.0e-6 is assumed.
   The minimum value of `errx` is 1.0e-15.

@returns: number, an estimation of the root.]],
_more = [[function `mininum.root` uses **regula falsi** method.

The function must be continuous, and the provided
abscissas _a_ and _b_ must accomplish _f(a)*f(b) < 0_.
In this case the method always converge towards a solution.

It is an iterative method, with (somewhat) superlinear convergence.
As much 30 iterations are done.

Here the "Illinois" version of the method is used.]],
_seealso = [[ [Wikipedia](http://en.wikipedia.org/wiki/False_position_method).]],
_example = [[    require"mininum"
    
    local eval = 0
    local function f (x)
       eval = eval+1
       return x*(3+x*(-4+2*x)) -- difficult for classical regula falsi
    end
    
    local errx = 1.0e-8
    local x = mininum.root(f, -1, 1, errx)
    
    print("calculated solution = ", x)     -- 3.9008079929199e-19
    print("actual solution     = ", 0)     -- 0
    print("intended error      = ", errx)  -- 1e-08
    print("actual error        = ", x)     -- 3.9008079929199e-19
    print("function evaluations= ", eval)  -- 14]],
}

function root (f, a, b, errx)
   assert(type(f) == "function", "f must be a function")
   assert(type(a) == "number" and type(b) == "number", "a and b must be numbers")
   errx = errx or 1.0e-6
   assert(type(errx) == "number", "errx must be a number")
   assert(errx >= 1.0e-15, "errx must be greater than 1.0e-15")

   local xa, fa = a, f(a)
   if fa == 0 then return a end
   local xb, fb = b, f(b)
   if fb == 0 then return b end
   assert(fa*fb < 0, "a and b choice does not ensure root finding; try others")

   local side = 0
   if fb < 0 then
      xa, xb = xb, xa
      fa, fb = fb, fa
   end

   local del, x
   for j = 1, 30 do
      x = xa+(xb-xa)*fa/(fa-fb)
      local fx = f(x)
      if fx == 0 then return x end
      if fx < 0 then
         del, xa, fa = abs(xa-x), x, fx
         if side == -1 then fb = fb/2 end
         side = -1
      else
         del, xb, fb = abs(xb-x), x, fx
         if side == 1 then fa = fa/2 end
         side = 1
      end
      if del < errx then return x end
   end
   io.stderr:write("root: warning, maximum number of iterations reached\n")
   io.stderr:write("actual absolute error: "..del.."\n")
   return x
end

_H.derivative = {
_basic = [[Calculates the first derivative of a function]],
_usage = [[`mininum.derivative(f, x, aerr)`

@params:

1. `f`: a function of a real variable.

2. `x`: number, is the abscissa at which _f'(x)_ is calculated.

3. `aerr`: number (optional), is the intended absolute error of the solution
   (1.0e-6 as default). The minimum value of `aerr` is 1.0e-15.

@returns: number, the first derivative of function _f_ at _x_.]],
_more = [[Function `mininum.derivative` uses the central difference formula:

_f'(x0) ~ [f(x0+h)-f(x0-h)]/(2 h)_

with successive decreasing values of _h: h/2, h/4, h/8_, etc.,
and applying the Richardson extrapolation method to improve
the convergence.]],
_seealso = [[Press et al. (1992),
Numerical Recipes in Fortran, p. 180, CUP.]],
_example = [[    require"mininum"
    
    local eval = 0
    local function g (x)
       eval = eval+1
       return sin(x)
    end
    
    local aerr = 1.e-6
    local d1 = mininum.derivative(g, 2, aerr)
    local e1 = cos(2)
    
    print("calculated solution = ", d1)    -- -0.41614683654713
    print("actual solution     = ", e1)    -- -0.41614683654714
    print("intended error      = ", aerr)  -- 1e-06
    print("actual absol. error = ", d1-e1) -- 9.9364960703952e-15
    print("function evaluations= ", eval)  -- 10]]  
}

function derivative (f, x, aerr)
   assert(type(f) == "function", "f must be a function")
   assert(type(x) == "number", "x must be a number")

   aerr = aerr or 1.0e-6
   assert(type(aerr) == "number", "err must be a number")
   assert(aerr >= 1.0e-15, "err must be greater than 1.0e-15")

   local aberr = math.huge
   local h, j, n = 1, 1, 15
   local d = {}
   d[1] = {}
   d[1][1]=(f(x+h)-f(x-h))/(2*h)
   
   while aberr > aerr and j < n do
      h = h/2
      d[j+1] = {}
      d[j+1][1] = (f(x+h)-f(x-h))/(2*h)
      local fac = 1
      for k = 1, j do 
         fac = 4*fac
         d[j+1][k+1] = d[j+1][k]+(d[j+1][k]-d[j][k])/(fac-1)
      end
      aberr = abs(d[j+1][j+1]-d[j][j])
     j = j+1
   end
   if j == n then
      io.stderr:write("derivative: warning, maximum number of iterations reached\n")
      io.stderr:write("estimated absolute error: "..aberr.."\n")
   end
   return d[j][j]
end

_H.quadrature = {
_basic = [[Calculates the definite integral of a function]],
_usage = [[`mininum.quadrature(f, a, b, rerr)`

@params:

1. `f`: a function of a real variable.

2. `a`: number, the lower limit in the integral.

3. `b`: number, the upper limit in the integral.

4. `rerr`: number (optional), the relative intended error in the solution
   (if not given 1.0e-6 is assumed). The minimum value of `rerr` is 1.0e-15.

@returns: number, the definite integral of `f` between abscissas `a` and `b`.]],
_more = [[Function `mininum.quadrature` uses the **midpoint formula**:

_I ~ h*[sum f(xi)]    with i = 1/2, 3/2, ..._

being _n_ the number of intervals, _h = (b-a)/n_, and _xi = a+h*i_.

This formula works even for quadratures when the function at
one or both limits is infinite but the integral exists.

The method is iterative, multiplying _n_ by 3 at each step,
until the relative error is achieved or a maximum of 14 iterations
are reached (1594323 function evaluations).
At least 9 ordinates are calculated.

At each iteration an _Aitken-delta^2_ process is performed.
This normally accelerates very much the convergence.]],
_seealso = [[Press et al. (1992),
Numerical Recipes in Fortran, p. 129 and p. 160, CUP.

For the Aitken acceleration see the
[Wikipedia](http://en.wikipedia.org/wiki/Aitken's_delta-squared_process).]],
_example = [[    require"mininum"
    
    local eval
    local function s (x)
       eval = eval+1
       -- a difficult case for Romberg quadrature
       return 1/sqrt(x)
    end
    
    local rerr = 1.0e-5
    local eval = 0
    local q = mininum.quadrature(s, 0, 0.5, rerr)
    local e = 2*sqrt(0.5)
    
    print("calculated solution = ", q)       -- 1.414213736863
    print("actual solution     = ", e)       -- 1.4142135623731
    print("intended error      = ", rerr)    -- 1e-05
    print("actual relat. error = ", (q-e)/e) -- 1.2338296867489e-07
    print("function evaluations= ", eval)    -- 243]]
}

function quadrature (f, a, b, rerr)
   assert(type(f) == "function", "f must be a function")
   assert(type(a) == "number" and type(b) == "number", "a and b must be numbers")
   rerr = rerr or 1.0e-6
   assert(type(rerr) == "number", "err must be a number")
   assert(rerr >= 1.0e-15, "err must be greater than 1.0e-15")

   local h = b-a
   local sum = f((a+b)/2)   -- partial sums
   local qo, qn, qp, qe, qeo, qep, den = sum*h
   local it, n, nt = 1, 2, 14

   -- because a final extrapolation is done we reduce the intended
   -- error; this does not always work but the final relative error
   -- often has the same magnitud order of rerr
   local err1 = 100*rerr

   while n <= nt do
      h = h/3
      for j = 1, it do
         local x = a+(3*j-2.5)*h
         sum = sum+f(x)+f(x+2*h)
      end
      qn = sum*h
      if qp then   -- Aitken-delta^2 process
         den = qn-2*qo+qp
         qe = den == 0 and qn or qn-(qn-qo)^2/den
         if qeo and abs(qe-qeo) < err1*abs(qe) then break end
      end
      qo, qp, qeo, qep = qn, qo, qe, qeo
      it = 3*it
      n = n+1
   end

   if n > nt then
      io.stderr:write("quadrature: warning, maximum number of iterations reached\n")
      io.stderr:write("estimated absolute error: "..abs((qe-qeo)/qe).."\n")
   end

   -- a final extrapolation over extrapolation if possible
   if qep then
     	den = qe-2*qeo+qep
     	qe = den == 0 and qe or qe-(qe-qeo)^2/den
   end
   return qe
end

-- checks if Lua calling was interactive;
-- it does not work for all cases, but it does
-- in the normal ones
local inter = true
if _G.arg then
   for _, v in pairs(_G.arg) do
     inter = false
     if v == "-i" then
       inter = true
       break
     end
   end
end

if inter then
   inter = pcall(require, HELPNAME)
   if inter then
      io.stderr:write('Module "'.._H._Name..'" loaded.\n')
      io.stderr:write('To obtain help invoke '..HELPNAME..'"'.._H._Name..'".\n')
      io.stderr:write('Documentation occupies memory. For freeing it let execute:\n')
      io.stderr:write('\n    '.._H._Name..'._H = nil\n\n')

      _G[HELPNAME].base(_H._Name)
   else
      io.stderr:write('Module "mininum" loaded.\n')
      io.stderr:write('It has help but module "'..HELPNAME..'" is not accesible.\n')
      io.stderr:write('Help removed.\n')
   end
end

if not inter then
   -- deleting _H
   _H = nil
   _G[HELPNAME] = nil
   collectgarbage()
end

