-------------------------------------------------------------------------------
-- mod11 is a Lua module to calculate and verify modulo11 checksums.
-- Modulo 11 is commonly used to prevent human errors. Common usecases
-- are; bank account numbers, creditcard numbers, social security numbers.
--
-- @author Thijs Schreijer, http://www.thijsschreijer.nl
-- @license mod11 is free software under the MIT license.
-- @copyright 2014 Thijs Schreijer
-- @release Version 1.0, mod11 module to calculate and verify  checksums
local M = {}

-- Returns only the digits in a string
-- str: string to read the digits from, if not a string it will be 'tostring'ed
local clean = function(str)
  str = tostring(str)
  local r = ""
  for w in string.gmatch(str, "%d") do
    r = r .. w
  end
  return r
end

-- returns a set, from a string
-- add_to: existing set to add to
local makeset = function(str, add_to)
  assert(type(str)=="string", "Expected string, got ".. type(str))
  local r = add_to or {}
  assert(type(r)=="table", "Expected tabe, got ".. type(add_to))
  for n = 1, #str do
    r[str:sub(n,n)] = str:sub(n,n)
  end
  return r
end

-- checks verify number being valid.
-- returns verifystring as list, or nil + error
local checkverify = function(v)
  if not (type(v)=="string") then
    return nil, "Expected string, got "..type(v)
  end
  if not (#v == 8) then 
    return nil, "Expected string with length 8, not " .. #v 
  end
  if v:find("%D") then
    return nil, "Bad value, only numbers 2 to 8 in random order, without doubles allowed"
  end
  
  local t = {1,2,3,4,5,6,7,8,9}
  local r = {}
  t[1]=nil
  for w in string.gmatch(v, "%d") do
    if not t[tonumber(w)] then
      return nil, "Bad value "..w.." in "..v..". Only numbers 2 to 8 in random order, without doubles allowed"
    else
      t[tonumber(w)] = nil
      table.insert(r, tonumber(w))
    end
  end
  return r
end

-- returns input str if it is a valid string containing only digits
-- and allowed characters. Or nil and error otherwise
-- allowed: set of allowed characters
local checkvalid = function(str, allowed)
  if not (type(str)=="string") then 
    return nil, "Expected string, got ".. type(str)
  end
  for n = 1, #str do
    if not allowed[str:sub(n,n)] then
      return nil, "Character '"..str:sub(n,n).."' is not an allowed character"
    end
  end
  return str
end

local ct = { [10] = 1, [11] = 0 }  -- 10 and 11 are special cases

-- str: string to calculate, must be clean, digits only
-- verify: list with verify weights, should have been checked to be valid
-- allowed: string with allowed chars between numbers
-- NOTE: does not do any checks
local getmodulo = function(str, verify)
  local total = 0
  local multiplpos = 1
  local result = ""
  for n = #str,1,-1 do    -- calculate right to left
    -- calculate value and add to total
    total = total + tonumber(str:sub(n,n)) * verify[multiplpos]
    -- Update multiplier position for next run
    multiplpos = multiplpos + 1     -- take next position
    if (multiplpos > #verify) or (n == 1) then
      -- reached end of series
      -- now calculate verification from total
      total = 11 - math.fmod(total,11)
      total = ct[total] or total   -- 10 and 11 are special cases
      -- set returned value (convert to string)
      result = total .. result
      -- Reset position
      multiplpos = 1
      total = 0
    end
  end
  return result
end

--- Creates a new object based on the given verify weights and allowed characters.
-- @name new
-- @tparam string verify A string of size 8, containing the digits 2-9, in some random order (no doubles). 
-- @tparam string allowed (optional) A string of characters allowed in between the digits. The digits (0-9) will automatically be added to the allowed set.
-- @return mod11 object that can be used to generate and verify checksums
-- @return Throws an error on invalid input
-- @usage
-- local mod11 = require("mod11")
-- local m = mod11("25834967","-/")               -- mod11() is a shortcut to mod11:new()
-- local invoicenr = "2013-12-23/013-"            -- a date and a sequential nr
-- invoicenr = invoicenr..m:calc(invoicenr)       -- append the checksum
-- print("Invoicenr including check:",invoicenr)
function M:new(verify, allowed)
  if self ~= M then
     -- method was called in '.' notation, so shift params
    allowed, verify = verify, self
  end
  local err
  verify, err = checkverify(verify)
  if not verify then error(err, 2) end
  allowed = allowed or ""
  assert(type(allowed)=="string","Expected string, got "..type(allowed))
  allowed = makeset(allowed)
  allowed = makeset("0123456789", allowed)
  return setmetatable({}, {
      verify = verify,   -- list with weights
      allowed = allowed, -- set (table) with allowed characters (incl. digits)
      __index = {
        --- Returns the string with verify weights as passed to `new`
        -- @param self The mod11 object created by `new`. 
        getverify = function(self)
          self = getmetatable(self)
          return table.concat(self.verify)
        end,
        --- Returns the string with allowed characters as passed to `new`.
        -- The returned string will also contain the digits (0-9), which are also allowed. Hence
        -- the string returned will not be identical to the string passed to `new`.
        -- @param self The mod11 object created by `new`. 
        getallowed = function(self)
          self = getmetatable(self)
          local r = ""
          for k in pairs(self.allowed) do
            r = r .. k
          end
          return r
        end,
        --- Calculates the checksum. See `new` for an example.
        -- @param self The mod11 object created by `new`. 
        -- @tparam string inp The string to calculate the checksum for. The string can only contain 
        -- digits and 'allowed' characters
        -- @return 2 values; 1) input with checksum appended, 2) checksum only
        -- @return Throws an error on invalid input
        calc = function(self, inp)
          self = getmetatable(self)
          local ok, err = checkvalid(inp, self.allowed)
          if not ok then
            error(err, 2)
          end
          local cinp = clean(inp)
          if #cinp == 0 then error("Invalid input, empty string (no digits)", 2) end
          local chk = getmodulo(cinp, self.verify)
          return inp..chk, chk
        end,
        --- Splits a number with checksum into number and checksum.
        -- It will not test validity of the checksum, use `check` for testing validity.
        -- @param self The mod11 object created by `new`.
        -- @param inp The string containing the number sequence to split.
        -- @return 2 strings; number and checksum. Both will be digits only, all other 
        -- characters will be removed
        -- @return Throws an error on invalid input
        split = function(self, inp)
          self = getmetatable(self)
          inp, err = checkvalid(inp, self.allowed)
          if not inp then
            error(err, 2)
          end
          inp = clean(inp)
          if (math.fmod(#inp,9) == 1) or (#inp == 0) then -- always data + check, so minimum 2 characters
            error("The input has an invalid length",2)
          end
          local chk = ""
          while #inp - #chk * 8 >= 0 do
            chk = inp:sub(-1,-1) .. chk
            inp = inp:sub(1,-2)
          end
          return inp, chk
        end,
        --- Checks a number to be a valid one.
        -- The check will only succeed if the `verify` number used is the exact same number 
        -- as the one used to create the checksum.
        -- @param self The mod11 object created by `new`.
        -- @param inp The string containing the number sequence to verify.
        -- @return[1] `true` if the checksum matches
        -- @return[2] `false` if the checksum failed
        -- @return[3] `nil` + error message if bad input was provided
        check = function(self, inp)
          local oself = self
          self = getmetatable(self)
          local ok, err = checkvalid(inp, self.allowed)
          if not ok then
            return nil, err
          end
          inp = clean(inp)
          if (math.fmod(#inp,9) == 1) or (#inp == 0) then -- always data + check, so minimum 2 characters
            return nil, "The input has an invalid length"
          end
          local chk
          inp, chk = oself:split(inp)
          local c = getmodulo(inp, self.verify)
          if c == chk then
            return true  -- verification ok
          else
            return false, "Check nr for "..inp.." is not "..chk.." but should have been "..c
          end
        end,
        --- Iterator factory. Return an iterator, which returns all valid numbers in the provided string.
        -- The optional `minsize` and `maxsize` parameters can be used to minimize the chance of false positives.
        -- @param self The mod11 object created by `new`.
        -- @param text The string to search. If text is not a string it will be 'tostring'ed
        -- @param minsize (optional) The minimum length (in digits, excluding 'allowed' characters)
        -- @param maxsize (optional) The maximum length (in digits, excluding 'allowed' characters)
        -- @return an iterator function that will return 3 values; 1) value (incl chk nr), 2) startpos, 3) endpos
        -- @return Throws an error on invalid input (`minsize < 2`, or `maxsize < minsize`)
        -- @usage-- see the sample directory for an example of the iterator
        foreach = function(self, text, minsize, maxsize)
          local oself = self
          self = getmetatable(self)
          text = tostring(text)
          local spos = 1 -- start pos
          local epos = 0 -- end pos
          local size     -- size so far (counts digits only, so size ~= epos-spos+1)
          minsize = minsize or 2
          assert(type(minsize) == "number", "Expected number got "..type(minsize))
          assert(minsize >= 2, "Minimum size cannot be less than 2. Got "..minsize)
          maxsize = maxsize or #text
          assert(type(maxsize) == "number", "Expected number got "..type(maxsize))
          assert(maxsize >= minsize, "Maximum size cannot be less than minimum size")
          return function()
              while true do
                -- find next sequence of digits
                spos = text:find("%d", spos)
                if not spos then return nil end -- no digits found, so we're done
                epos = spos
                size = 0
                while true do
                  local c = text:sub(epos,epos)
                  if self.allowed[c] then
                    -- it is a valid character
                    if tonumber(c) then
                      -- it's a digit so we must add it
                      size = size + 1                      
                    end
                    epos = epos + 1
                  end
                  if (not self.allowed[c]) or (epos > #text) then
                    -- it is an invalid character, or the end of the text so the current sequence ends here
                    if size < minsize or size > maxsize then
                      spos = text:find("%D", spos) -- first up NON-digit
                      if not spos then return nil end -- nothing found, we're done
                      break
                    end
                    local inp = text:sub(spos, epos-1)
                    local succes, ok = pcall(oself.check, oself, inp)
                    if succes and ok then
                      -- found one!
                      local s, e = spos, epos-1
                      spos = epos
                      return inp, s, e
                    end
                    -- not valid, so move on
                    spos = text:find("%D", spos) -- first up NON-digit
                    if not spos then return nil end -- nothing found, we're done
                    break                    
                  end
                end
              end              
            end
        end
        
      }
      })
end

return setmetatable(M, { __call = function(self, ...) return M.new(...) end })
