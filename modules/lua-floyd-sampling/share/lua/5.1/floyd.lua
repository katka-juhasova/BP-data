
--[[
   Written by Soojin Nam. Public Domain.
   Programming Pearls: a sample of brilliance
   Communications of the ACM, 
   Volume 30 Issue 9, Sept. 1987,  
   Pages 754-757 
--]]


local OrderedSet = require "rbtree"
local randint = math.random
local co_wrap = coroutine.wrap
local co_yield = coroutine.yield


-- set arguments
local maxn = 1000000000 -- 1,000,000,000

local function _set_args (m, n)
   if not m then
      return nil, "numeric arguments should be given."
   end
   local n = n or m
   if n > maxn then
      return nil, n.." should be less than "..maxn.."."
   elseif m > n then
      return nil, m.." should be less than or equal to "..n.."."
   end
   return m, n
end


local _M = {
    version = '0.0.1'
}


-- Floyd's random sampling
local function _sample (...)
   local m, n = _set_args(...)
   if not m then
      return nil, n
   end

   local set = OrderedSet.new()
   for j = n-m+1, n do
      local t = randint(j)
      if not set(t) then
         set:insert(t)
      else
         set:insert(j)
      end
   end
   return set:iter()
end


-- Floyd's random permutation generator
local function _permgen (...)
   local m, n = _set_args(...)
   if not m then
      return nil, n
   end

   local s = {}
   local head = nil
   for j = n-m+1, n do
      local t = randint(j)
      if not s[t] then
         head = { key = t, next = head }
         s[t] = head
      else
         local curr = { key = j, next = s[t].next }
         s[t].next = curr
         s[j] = curr
      end
   end

   while head do
      co_yield(head.key)
      head = head.next
   end
end


function _M.sample (m, n)
   return _sample(m, n)
end


function _M.shuffle (m, n)
   return co_wrap(function () _permgen(m, n) end)
end


math.randomseed(os.time())


return _M
