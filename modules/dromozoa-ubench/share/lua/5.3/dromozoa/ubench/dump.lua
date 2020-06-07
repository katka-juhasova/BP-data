-- Copyright (C) 2018 Tomoyuki Fujimori <moyu@dromozoa.com>
--
-- This file is part of dromozoa-ubench.
--
-- dromozoa-ubench is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- dromozoa-ubench is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with dromozoa-ubench.  If not, see <http://www.gnu.org/licenses/>.

return function (out, results)
  out:write(([[
return function (results)
]]):format(results.version))
  for i = 1, #results do
    local result = results[i]
    out:write(([[
  results[#results + 1] = {
    version = %q;
    name = %q;
    iteration = %d;
]]):format(result.version, result.name, result.iteration))
    for j = 1, #result do
      out:write(("    %.17g;\n"):format(result[j]))
    end
    out:write "  };\n"
  end
  out:write [[
  return results
end
]]
end
