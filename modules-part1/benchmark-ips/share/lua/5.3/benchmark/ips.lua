local function to_i(str) return tonumber(str:gsub('[^%d]', ''), 10) end

local NANOSECONDS_PER_SECOND = to_i('1 000 000 000')
local NANOSECONDS_PER_100MS = to_i('100 000 000')
local Timing = { }


local ffi = require 'ffi'
local tab_new = require "table.new"

ffi.cdef [[
typedef int clockid_t;
typedef long time_t;

struct timespec {
  time_t tv_sec;
  long tv_nsec;
};

int clock_gettime(clockid_t clk_id, struct timespec *tp);
char *strerror(int errnum);
]]

local C = ffi.C

local CLOCK = {
  REALTIME                  = 0,
  MONOTONIC                 = 1,
  PROCESS_CPUTIME_ID        = 2,
  THREAD_CPUTIME_ID         = 3,
  MONOTONIC_RAW             = 4,
  REALTIME_COARSE           = 5,
  MONOTONIC_COARSE          = 6,
}

local ts = ffi.new("struct timespec[1]")

local function ffi_error()
  return C.strerror(ffi.errno())
end

-- Get an object that represents now in nanoseconds
function Timing.now()
  if C.clock_gettime(CLOCK.MONOTONIC_RAW, ts) ~= 0 then
    return nil, ffi_error()
  end

  return tonumber(ts[0].tv_sec * 1e9 + ts[0].tv_nsec)
end

-- Recycle used objects by starting Garbage Collector.
function Timing.clean_env()
  collectgarbage('collect')
end

-- Return the number of microseconds between the 2 moments
function Timing.time_ns(before, after)
  return after - before
end

-- Add number of seconds second to the time represenetation
function Timing.add_second(t, s)
  return t + (s * NANOSECONDS_PER_SECOND)
end


local Report = {}
local ReportEntry = {}
local Entry = {}
local Stats = {}

local function _just(str, width, char)
  local delta = width - #str

  if delta > 0 then
    return (char or ' '):rep(delta)
  else
    return ''
  end
end

local function rjust(str, width, char)
  return _just(str, width, char) .. str
end

local function ljust(str, width, char)
  return str .. _just(str, width, char)
end

-- Add padding to label's right if label's length < 20, Otherwise add a new line and 20 whitespaces.
local function rjust_label(label)
  local delta = 20 - #label

  if delta > 0 then
    return rjust(label, 20)
  else
    return label .. "\n" .. rjust('', 20)
  end
end

local IPS = {
  time = 5,
  warmup = 2,
  iterations = 1,
  hooks = {
    start_warming = {
      function() print('Warming up --------------------------------------') end,
    },
    warming = {
      function(label) print(rjust_label(label)) end,
    },
    warmup_stats = {
      function(_, timing) print(("%10d i/100ms\n"):format(timing)) end,
    },

    start_running = {
      function() print('Calculating -------------------------------------') end,
    },
    running = {},
    report_entry = {
      function(report) print(" ", report:body()) end,
    },

    done = {},
  },
}


local IPS_mt = {
  __index = IPS,
  __newindex = function(_, k) error("unknown property: " .. k) end,
}

function IPS:call(f)
  local ips = self:new()

  f(ips)
  ips:run()

  return
end

function IPS:new()
  local m = {
    time = self.time,
    warmup = self.warmup,
    iterations = self.iterations,
    full_report = Report:new(),
    items = {}, timing = {},
    hooks = self.hooks,
  }

  return setmetatable(m, IPS_mt)
end

function IPS:notify(name, ...)
  for _, fun in ipairs(self.hooks[name]) do
    fun(...)
  end
end

function IPS:report(label, fun)
  table.insert(self.items, Entry:new(label, fun))
end

function IPS:compare()
  if #self.items < 1 then
    error("no items to test")
  end
end


local floor = math.floor

-- Calculate the cycles needed to run for approx 100ms,
-- given the number of iterations to run the given time.
-- @tparam Float time_nsec Each iteration's time in ns.
-- @tparam Integer iters Iterations.
-- @treturn Integer Cycles per 100ms.

local function cycles_per_100ms(time_nsec, iters)
  local cycles = floor((NANOSECONDS_PER_100MS / time_nsec) * iters)
  if cycles <= 0 then return 1 else return cycles end
end

-- Calculate the interations per second given the number
-- of cycles run and the time in microseconds that elapsed.
-- @tparam Integer cycles Cycles.
-- @tparam Integer time_ns Time in microsecond.
-- @treturn Float Iteration per second.
local function iterations_per_sec(cycles, time_ns)
  return NANOSECONDS_PER_SECOND * (cycles / time_ns)
end

function IPS:run_warmup()
  for _,item in ipairs(self.items) do

    self:notify('warming', item.label, self.warmup)

    Timing:clean_env()

    local before = Timing.now()
    local target = Timing.add_second(before, self.warmup)

    local warmup_iter = 0

    while Timing.now() < target do
      item:call_times(1)
      warmup_iter = warmup_iter + 1
    end

    local after = Timing.now()
    local warmup_time_ns = Timing.time_ns(before, after)

    self.timing[item] = cycles_per_100ms(warmup_time_ns, warmup_iter)

    self:notify('warmup_stats', warmup_time_ns, self.timing[item])
  end
end

local insert = table.insert

local sum = function(t)
  local total = 0
  for _, n in ipairs(t) do
    total = total + n
  end
  return total
end

local function stats_samples(measurements_ns, cycles)
  local samples = tab_new(#measurements_ns, 0)

  for i, time_ns in ipairs(measurements_ns) do
    samples[i] = iterations_per_sec(cycles, time_ns)
  end

  return samples
end

function IPS:run_benchmark()
  for _,item in ipairs(self.items) do
    self:notify('running', item.label, self.time)

    Timing:clean_env()


    local iter = 0
    local measurements_ns = {}

    -- Running this number of cycles should take around 100ms.
    local cycles = self.timing[item]

    local after
    local before = Timing.now()
    local target = Timing.add_second(before, self.time)

    while before < target do
      item:call_times(cycles)
      after = Timing.now()

      -- If for some reason the timing said this took no time (O_o)
      -- then error out.
      local iter_ns = Timing.time_ns(before, after)

      if iter_ns <= 0 then
        error('impossible happened')
      end

      before = after

      iter = iter + cycles
      insert(measurements_ns, iter_ns)
    end

    local measured_ns = sum(measurements_ns)
    local samples = stats_samples(measurements_ns, cycles)
    local rep = self.full_report:add_entry(item.label, measured_ns, iter, Stats:new(samples), cycles)

    self:notify('report_entry', rep)
  end
end

function IPS:run()
  if self.warmup and self.warmup > 0 then
    for _=1, self.iterations do
      self:notify('start_warming')
      self:run_warmup()
    end
  end

  self:notify('start_running')

  for _=1, self.iterations do
    self:run_benchmark()
  end

  self:notify('done')
end

function Entry:new(label, action)
  local entry = { label = label, action = action }
  return setmetatable(entry, { __index = self })
end

function Entry:call_times(n)
  local action = self.action

  for _=1, n do
    action()
  end
end

function Report:new()
  return setmetatable({
    entries = {},
  }, { __index = self })
end

function Report:add_entry(label, nanoseconds, iters, stats, measurement_cycle)
  local entry = ReportEntry:new(label, nanoseconds, iters, stats, measurement_cycle)

  table.insert(self.entries, entry)

  return entry
end

function Report.body(_)
end

function ReportEntry:new(label, nanoseconds, iterations, stats, measurement_cycle)
  return setmetatable({
    label = label,
    nanoseconds = nanoseconds,
    iterations = iterations,
    stats = stats,
    measurement_cycle = measurement_cycle,
  }, { __index = self })
end

function ReportEntry:error_percentage()
  return 100.0 * (self.stats.error / self.stats.central_tendency)
end

function ReportEntry:body()
  local left = ("%10.1f (±%.1f%%) i/s"):format(self.stats.central_tendency, self:error_percentage())

  return ljust(left, 20) .. (" - %10d in %10.6fs"):format(self.iterations, self:runtime())
end

function ReportEntry:runtime()
  return self.nanoseconds / NANOSECONDS_PER_SECOND
end

local function stat_mean(samples)
  local total = sum(samples)
  return total / #samples
end

local function stat_variance(samples, m)
  local mean = m or stat_mean(samples)
  local total = 0
  for _,n in ipairs(samples) do
    total = total + math.pow(n - mean, 2)
  end

  return total / #samples
end

local function stat_stddev(samples, m)
  return math.sqrt(stat_variance(samples, m))
end

function Stats:new(samples)
  local mean = stat_mean(samples)
  local error = stat_stddev(samples, mean)

  return setmetatable({
    central_tendency = mean,
    error = error,
  }, { __index = self })
end


return setmetatable(IPS, {
  __call = function(_, f) return IPS:call(f) end,
  __newindex = IPS_mt.__newindex,
})

