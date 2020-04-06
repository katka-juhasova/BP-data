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

local DeclaredDependency = {}
DeclaredDependency.__index = DeclaredDependency

function DeclaredDependency.create(data)
  local object = {
    name         = assert(data.name),
    gear         = assert(data.gear),
    dependencies = assert(data.dependencies),
    constructor  = assert(data.constructor),
    initializer  = data.initializer,
    provides     = data.provides,
  }
  return setmetatable(object, DeclaredDependency)
end

function DeclaredDependency:construct()
  -- create instance
  local instance = self.constructor()
  assert(instance, "Constructor for " .. self.name .. " should return something")

  -- record the instance to avoid indirect recursion for chicken/egg
  self.gear:set(self.name, instance)

  -- possibly instantiate dependencies
  local dependency_instances = {}
  for _, dependency in ipairs(self.dependencies) do
    local d = self.gear:get(dependency)
    table.insert(dependency_instances, d)
  end

  -- initialize instance
  if (self.initializer) then
    local objects = table.pack(self.initializer(self.gear, instance, table.unpack(dependency_instances)))
    if (#self.provides > 0) then
      assert(#self.provides == #objects, "initializer for " .. self.name .. " should return " .. #self.provides .. " objects")
      for idx, component_name in pairs(self.provides) do
        local object = objects[idx]
        self.gear:set(component_name, object)
      end
    end
  end

  return instance
end

return DeclaredDependency
