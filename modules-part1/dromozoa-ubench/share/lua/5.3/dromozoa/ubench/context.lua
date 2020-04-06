-- Copyright (C) 2017,2018 Tomoyuki Fujimori <moyu@dromozoa.com>
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

local unix = require "dromozoa.unix"

local scaling_governor_filename = "/sys/devices/system/cpu/cpufreq/policy0/scaling_governor"

local class = {}

function class:initialize()
  local pid = assert(unix.getpid())

  local scaling_governor
  local handle = io.open(scaling_governor_filename)
  if handle then
    scaling_governor = handle:read "*l"
    handle:close()
  else
    io.stderr:write "scaling_governor not supported\n"
  end
  if scaling_governor and scaling_governor ~= "performance" then
    local out, message = io.open(scaling_governor_filename, "w")
    if out then
      out:write "performance"
      out:close()
      self.scaling_governor = scaling_governor
    else
      io.stderr:write("io.open failed: ", message, "\n")
    end
  end

  if unix.sched_setaffinity then
    local affinity = assert(unix.sched_getaffinity(pid))
    local result, message = unix.sched_setaffinity(pid, { 3 })
    if result then
      self.affinity = affinity
    else
      io.stderr:write("sched_setaffinity failed: ", message, "\n")
    end
  else
    io.stderr:write "sched_setaffinity not supported\n"
  end

  if unix.sched_setscheduler then
    local scheduler = assert(unix.sched_getscheduler(pid))
    local param = assert(unix.sched_getparam(pid))
    local result, message = unix.sched_setscheduler(pid, unix.SCHED_FIFO, {
      sched_priority = assert(unix.sched_get_priority_max(unix.SCHED_FIFO)) - 1;
    })
    if result then
      self.scheduler = scheduler
      self.param = param
    else
      io.stderr:write("sched_setscheduler failed: ", message, "\n")
    end
  else
    io.stderr:write "sched_setscheduler not supported\n"
  end

  local result, message = unix.mlockall(unix.bor(unix.MCL_CURRENT, unix.MCL_FUTURE))
  if result then
    self.mlockall = true
  else
    io.stderr:write("mlockall failed: ", message, "\n")
  end

  return self
end

function class:terminate()
  local pid = assert(unix.getpid())

  local scaling_governor = self.scaling_governor
  if scaling_governor then
    local out = assert(io.open(scaling_governor_filename, "w"))
    out:write(scaling_governor)
    out:close()
    self.scaling_governor = nil
  end

  if self.affinity then
    assert(unix.sched_setaffinity(pid, self.affinity))
    self.affinity = nil
  end

  if self.scheduler then
    assert(unix.sched_setscheduler(pid, self.scheduler, self.param))
    self.scheduler = nil
    self.param = nil
  end

  if self.mlockall then
    assert(unix.munlockall())
    self.mlockall = nil
  end

  return self
end

class.metatable = {
  __index = class;
}

return setmetatable(class, {
  __call = function ()
    return setmetatable({}, class.metatable)
  end;
})
