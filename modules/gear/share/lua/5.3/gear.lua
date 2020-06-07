--[[

Copyright (C) 2016 Ivan Baidakou (basiliscos), http://github.com/basiliscos

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

]]--

local DeclaredDependency = require("gear.DeclaredDependency")
local ProvidedDependency = require("gear.ProvidedDependency")

local Gear = {}
Gear.__index = Gear


function Gear.create()
  return setmetatable({
    components = {},
  }, Gear)
end

function Gear:declare(name, description)
  assert(name, "component name is mandatory")
  assert(type(name) == 'string', "component name must be a string")
  assert(not self.components[name], "Component " .. name .. " is already declared")

  assert(description, "component description is mandatory")
  assert(type(description) == 'table', "component description should be a table")

  -- dependencies
  local dependencies = {}
  if (description.dependencies) then
    dependencies = description.dependencies
  elseif (description.resolver) then
    local resolver = description.resolver
    dependencies = resolver(name)
  end
  assert(dependencies, "dependencies must be a table")

  -- constructor
  local constructor = description.constructor
  assert(constructor, "description/constructor is mandatory")
  assert(type(constructor) == 'function', "constructor should be a function")

  -- initializer
  local initializer = description.initializer
  if (initializer) then
    assert(type(initializer) == 'function', "initializer should be a function")
  end

  local provides = description.provides
  if (provides) then
    assert(initializer, "initializer must be defined for " .. name .. ", as it provides some other components")
    assert(type(provides) == 'table', "provides should be a table")
  else
    provides = {}
  end

  -- all seems fine, create primary "root" component
  local root = DeclaredDependency.create({
    name         = name,
    gear         = self,
    dependencies = dependencies,
    constructor  = constructor,
    initializer  = initializer,
    provides     = provides,
  })

  self.components[name] = {
    dependency = root,
    instance   = nil,
  }

  -- create secondary descriptors for provided components
  for _, component_name in pairs(provides) do
    self.components[component_name] = {
      dependency = ProvidedDependency.create({
        name      = component_name,
        gear      = self,
        component = root,
      }),
      instance   = nil,
    }
  end

end

function Gear:set(name, instance)
  assert(name)
  -- print("-- set:" .. name .. " => " .. instance)

  local decl = self.components[name]
  if (not decl) then
    decl = { }
    self.components[name] = decl
  end
  decl.instance = instance
end

function Gear:get(name)
  local decl = assert(self.components[name], "No declaration for " .. name)

  if (decl.instance) then return decl.instance end

  decl.instance = decl.dependency:construct()
  return decl.instance
end

return Gear
