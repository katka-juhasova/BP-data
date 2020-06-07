--[[
The MIT License (MIT)
Copyright (c) 2016 olueiro <github.com/olueiro>
Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
]]

return function(source, ...)

  local conditions = { ... }

  if type(source) ~= "table" then
    return false
  end

  -- Local functions

  local function str(s1, s2)
    local s = string.match(s1, "^.(.*)$")
    if string.find(s1, "^%!") then
      -- ignore case comparison
      if string.lower(s) == string.lower(s2) then
        return true
      end
    elseif string.find(s1, "^%~") then
      -- negation comparison
      if s ~= s2 then
        return true
      end
    elseif string.find(s1, "^%?") then
      -- contains
      if string.find(s2, s) then
        return true
      end
    elseif string.find(s1, "^%=") then
      -- compare
      if s == s2 then
        return true
      end
    else
      -- compare
      if s1 == s2 then
        return true
      end
    end
    return false
  end

  local function num(n1, n2)
    local s1 = tostring(n1)
    n1 = tonumber(string.match(s1, "^%D?%D?(.*)$"))
    if not n1 then
      return false
    end
    if string.find(s1, "^<=") then
      -- lower or equal
      -- coercion
      n2 = tonumber(n2)
      if n2 <= n1 then
        return true
      end
    elseif string.find(s1, "^<") then
      -- lower
      -- coercion
      n2 = tonumber(n2)
      if n2 < n1 then
        return true
      end
    elseif string.find(s1, "^>=") then
      -- greater or equal
      -- coercion
      n2 = tonumber(n2)
      if n2 >= n1 then
        return true
      end
    elseif string.find(s1, "^>") then
      -- greater
      -- coercion
      n2 = tonumber(n2)
      if n2 > n1 then
        return true
      end
    elseif string.find(s1, "^~") then
      -- not
      if n1 ~= n2 then
        return true
      end
    elseif string.find(s1, "^=") then
      -- compare
      if n1 == n2 then
        return true
      end
    else
      -- compare
      if tonumber(s1) == n2 then
        return true
      end
    end
    return false
  end

  local function search_by_key(t, key, results, recursive)
    for k, v in pairs(t) do
      if str(key, k) then
        results[#results+1] = v
      end
      if recursive and type(v) == "table" then
        search_by_key(v, key, results, recursive)
      end
    end
  end

  local function search_partials(t, f)
    for k, v in pairs(t) do
      local results = {}
      search_by_key(f, k, results, false)
      if #results == 1 then
        if type(v) == "table" and type(results[1]) == "table" then
          return search_partials(v, results[1])
        elseif results[1] ~= v then
          return false
        end
      else
        return false
      end
    end
    return true
  end

  local continue = true

  for _, condition in ipairs(conditions) do
    if not continue then
      break
    end

    if type(condition) == nil then
      return true
    elseif type(condition) ~= "table" then
      condition = {condition}
    end

    -- Array search

    for _, value in ipairs(condition) do
      if not continue then
        break
      end
      if type(value) == "table" then
        -- If table: search following source structure
        if not search_partials(value, source) then
          continue = false
        end
      elseif type(value) == "string" then
        -- If string: search key in all source
        local results = {}
        search_by_key(source, value, results, true)
        if #results == 0 then
          continue = false
        end
      end
    end

    -- Associative array search

    for key, value in pairs(condition) do
      if type(key) == "string" then
        if not continue then
          break
        end
        if type(value) ~= "table" then
          value = {value}
        end
        local continue2 = false
        for _, value2 in ipairs(value) do
          if type(value2) == "number" then
            -- If number: search key and value in all source
            local results = {}
            search_by_key(source, key, results, true)
            for _, value3 in ipairs(results) do
              if value3 == value2 then
                continue2 = true
                break
              end
            end
          elseif type(value2) == "string" then
            -- If string: search key and value in all source
            -- if source value is a number do a number comparison
            -- if source value is a string do a string comparison
            local results = {}
            search_by_key(source, key, results, true)
            for _, value3 in ipairs(results) do
              if type(value3) == "number" or tonumber(value3) then
                if num(value2, value3) then
                  continue2 = true
                  break
                end
              end
              if type(value3) == "string" then
                if str(value2, value3) then
                  continue2 = true
                  break
                end
              end
            end
          elseif type(value2) == "boolean" then
            -- If boolean: compare value and types
            local results = {}
            search_by_key(source, key, results, true)
            for _, value3 in ipairs(results) do
              if type(value3) == "boolean" and value2 == value3 then
                continue2 = true
                break
              end
            end
          elseif type(value2) == "function" then
            -- If function: execute function passing key, value and source, returns true to pass
            local results = {}
            search_by_key(source, key, results, true)
            for _, value3 in ipairs(results) do
              continue2 = value2(key, value3, source) == true
              if continue2 then
                break
              end
            end
            if continue2 then
              break
            end
          end
        end
        continue = continue2
      end
    end

  end

  return continue

end