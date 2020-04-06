-- lbuilder | 04.07.2018
-- By daelvn
-- Pattern builder

--# Namespace #--
local lbuilder = {}

--# Public utils #--
function lbuilder.sanitize (union)
  return union:gsub("[%(%)%.%%%+%-%*%?%[%]%^%$]", "%%%0")
end

--# Metatables #--
lbuilder.meta = {}

--# Includes #--
lbuilder.saved = {}
function lbuilder.G (elem) return elem.value end
function lbuilder.I (name) return lbuilder.saved [name].value end
function lbuilder.T (name) return lbuilder.saved [name] end

--# Particles #--
lbuilder.meta.particle = {
  -- p [name]
  __index = function (this, name)
    if name ~= "type" and name ~= "value" and name ~= "name" then
      lbuilder.saved [name] = this
    else
      return this [name]
    end
  end,
  -- p + p
  __add = function (this, p2)
    if not p2.type:match "^lbuilder:particle" then
      error "Invalid parameter to p+p2: p2 is not a lbuilder particle"
    end
    if this.type == "lbuilder:particle:set" and p2.type == "lbuilder:particle:set" then
      this.value = "[" .. this.value:sub (2,-1) .. p2.value:sub(2,-1) .. "]"
    else
      this.value = this.value .. p2.value
    end
    return this
  end,
  -- -s
  __unm = function (this)
    if not this.type == "lbuilder:particle:set" then
      error ("Invalid parameter to -s: Attempt to operate on " .. this.type)
    end
    --
    if this.value:match "^%[%^" then
      this.value = "[" .. this.value:sub (3)
    else
      this.value = "[^" .. this.value:sub (2)
    end
    return this
  end,
  -- p/?
  __div = function (this, op)
    -- p/n
    if type (op) == "number" and op > 0 then
      this.value = this.value:rep (op)
    -- p/-n
    elseif type (op) == "number" and op < 0 then
      this.value = this.value:rep (math.abs (op))
      -- s/-n
      if this.type == "lbuilder:particle:set" then
        if this.value:match "^%[%^" then
          this.value = this.value .. "[" .. this.value:sub (3)
        else
          this.value = this.value .. "[^" .. this.value:sub (2)
        end
      -- p/-n
      else
        this.value = this.value .. "[^" .. this.value .. "]"
      end
    elseif op:match "[+?*-]" then
      if this.type ~= "lbuilder:particle:set"
      and this.type ~= "lbuilder:particle:literal"
      and this.type ~= "lbuilder:particle:normal" then
        error ("Invalid parameter to s/?: Attempt to operate on " .. this.type)
      end
      this.value = this.value .. op
    end
    return this
  end,
  -- #p
  __len = function (this)
    return lbuilder.P (this.value)
  end,
  -- lbuilder.s "builder" (true)
  __call = function (this, negate)
    if not this.type == "lbuilder:particle:set" then
      error ("Invalid parameter to -s: Attempt to operate on " .. this.type)
    end
    --
    if this.value:match "^%[%^" and negate then
      this.value = "[" .. this.value:sub (3)
    elseif negate then
      this.value = "[^" .. this.value:sub (2)
    end
    return this
  end
}
--- Builders
-- Literal
function lbuilder.l (name, builder)
  local particle = setmetatable (
    { name = builder and name or "?", value = lbuilder.sanitize (builder or name), type = "lbuilder:particle:literal" },
    lbuilder.meta.particle
  )
  if builder and name then lbuilder.saved [name] = particle end
  return particle
end
-- Normal
function lbuilder.n (name, builder)
  local particle = setmetatable (
    { name = builder and name or "?", value = builder or name, type = "lbuilder:particle:normal" },
    lbuilder.meta.particle
  )
  if builder and name then lbuilder.saved [name] = particle end
  return particle
end
-- Set
function lbuilder.s (name, builder)
  local particle = setmetatable (
    { name = builder and name or "?", value = "[" .. (builder or name) .. "]", type = "lbuilder:particle:set" },
    lbuilder.meta.particle
  )
  if builder and name then lbuilder.saved [name] = particle end
  return particle
end
-- Capture
function lbuilder.c (name, builder)
  local particle = setmetatable (
    { name = builder and name or "?", value = "(" .. (builder or name) .. ")", type = "lbuilder:particle:capture" },
    lbuilder.meta.particle
  )
  if builder and name then lbuilder.saved [name] = particle end
  return particle
end
-- Capture from particle
function lbuilder.C (name, builder)
  local particle = setmetatable (
    { name = builder and name or "?", value = "(" .. (builder or name) .. ")", type = "lbuilder:particle:capture" },
    lbuilder.meta.particle
  )
  if builder and name then lbuilder.saved [name] = particle end
end

--# Patterns #--
lbuilder.meta.pattern = {
  -- P [name]
  __index = function (this, name)
    if name ~= "type" and name ~= "value" and name ~= "name" then
      lbuilder.saved [name] = this
    else
      return this [name]
    end
  end,
  -- P + P
  __add    = function (this, P2)
    this.value = this.value .. P2.value
    return this
  end,
  -- P .. P
  __concat = function (this, P2)
    this.value = "(" .. this.value .. ")(" .. P2.value .. ")"
    return this
  end,
  -- P % P
  __mod    = function (this, str)
    return str:match (this.value)
  end,
  -- P * str
  __mul     = function (this, str)
    local ct = {}
    for match in str:gmatch (this.value) do table.insert (ct, match) end
    return ct
  end,
  -- P /str/rep/n
  -- P /str/fn/n
  -- P /str/rep/bool
  -- P /str/fn/bool
  __div    = function (this, operand)
    if type (operand) == "string" then
      if not this._repstr then
        this._repstr = operand
      else
        this._reppat = operand
      end
      return this
    elseif type (operand) == "function" then this._repfn  = operand; return this
    elseif type (operand) == "number"   then
      if not this._repstr then error "No string passed to P /str/?/n" end
      return this._repstr:gsub (this.value, this._repfn or this._reppat, operand)
    elseif type (operand) == "boolean"  then
      if not this._repstr then error "No string passed to P /str/?/bool" end
      return operand and this._repstr:gsub (this.value, this._repfn or this._reppat)
    end
  end
}
--- Builders
function lbuilder.P (name, union)
  local Pattern = setmetatable (
    { name = union and name or "?", value = union.value or name.value, type = "lbuilder:pattern" },
    lbuilder.meta.pattern
  )
  if union and name then lbuilder.saved [name] = Pattern end
  return Pattern
end

--# Shorthands #--
function lbuilder.cs (name, builder) return lbuilder.c (lbuilder.s (name, builder).value) end
function lbuilder.cl (name, builder) return lbuilder.c (lbuilder.l (name, builder).value) end

--# Return #--
return lbuilder
