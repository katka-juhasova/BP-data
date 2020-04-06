local hdr = require "hdrhistogram.hdr"

local hdrmeta = getmetatable(hdr.new(1, 1000, 2))

local new = hdr.new

local data = setmetatable({}, {
  __mode="k",
  __index=function(t, k)
    local ret = {multiplier=1, unit=""}
    t[k] = ret
    return ret
  end
})

function hdr.new(lowest, highest, sig, opt)
  
  opt = opt or {}
  local mult = opt.multiplier or 1
  local self = new(lowest/mult, highest/mult, sig)
  
  data[self] = {
    multiplier = mult,
    unit = opt.unit or opt.units or ""
  }
  
  return self
end

local record = hdrmeta.record
function hdrmeta:record(val)
  return record(self, val * 1/data[self].multiplier)
end

local record_corrected = record_corrected
function hdrmeta:record_corrected(val, expected_interval)
  local mult = data[self].multiplier
  return record_corrected(self, val/mult, expected_interval/mult)
end

for i, v in ipairs({"min", "max", "mean", "stddev", "percentile"}) do
  local orig = hdrmeta[v]
  hdrmeta[v] = function(self, ...)
    return orig(self, ...) * data[self].multiplier
  end
end

local numrun = "~!@#$%^&*"
local rnumrun = {}
for i=1,#numrun do
  rnumrun[string.char(numrun:byte(i))]=i-1
end

local serialize = hdrmeta.serialize
function hdrmeta:serialize()
  local raw_serialized = serialize(self)
  local raw_counts = raw_serialized.counts
  local counts = {}
  local num
  
  local i, j = 1, 1
  while i <= #raw_counts do
    local n = 1
    num, j = raw_counts[i],  i
    if num < #numrun then
      while raw_counts[j+1] == num do
        n, j = n+1, j+1
      end
      if n > 1 then
        table.insert(counts, ("%c%d"):format(numrun:byte(num+1), n))
      else
        table.insert(counts, num)
      end
    else
      table.insert(counts, num)
    end
    i=j+1
  end
  
  local vars = ("%d %d %d %d %d %d %d %d %d %d %d %d %f %d %d"):format(
    raw_serialized.lowest_trackable_value,
    raw_serialized.highest_trackable_value,
    raw_serialized.unit_magnitude,
    raw_serialized.significant_figures,
    raw_serialized.sub_bucket_half_count_magnitude,
    raw_serialized.sub_bucket_half_count,
    raw_serialized.sub_bucket_mask,
    raw_serialized.sub_bucket_count,
    raw_serialized.bucket_count,
    raw_serialized.min_value,
    raw_serialized.max_value,
    raw_serialized.normalizing_index_offset,
    raw_serialized.conversion_ratio,
    raw_serialized.counts_len,
    raw_serialized.total_count
  )
  
  if data[self].multiplier ~= 1 or (data[self].unit and #data[self].unit>0) then
    return ("%s [%s ] (%s %s)"):format(vars, table.concat(counts, " "), data[self].unit, tostring(data[self].multiplier))
  else
    return ("%s [%s ]"):format(vars, table.concat(counts, " "))
  end
end

local unserialize = hdr.unserialize
function hdr.unserialize(str)
  
  local m = {str:match("^(%d+) (%d+) (%d+) (%d+) (%d+) (%d+) (%d+) (%d+) (%d+) (%d+) (%d+) (%d+) (%S+) (%d+) (%d+) %[(.+)%] ?(.*)")}
  if not m then
    error("invalid HDRHistogram serialization format")
  end
  local tbl = {
    lowest_trackable_value =            tonumber(m[1]),
    highest_trackable_value =           tonumber(m[2]),
    unit_magnitude =                    tonumber(m[3]),
    significant_figures =               tonumber(m[4]),
    sub_bucket_half_count_magnitude =   tonumber(m[5]),
    sub_bucket_half_count =             tonumber(m[6]),
    sub_bucket_mask =                   tonumber(m[7]),
    sub_bucket_count =                  tonumber(m[8]),
    bucket_count =                      tonumber(m[9]),
    min_value =                         tonumber(m[10]),
    max_value =                         tonumber(m[11]),
    normalizing_index_offset =          tonumber(m[12]),
    conversion_ratio =                  tonumber(m[13]),
    counts_len =                        tonumber(m[14]),
    total_count =                       tonumber(m[15]),
  }
  
  local counts = {}
  local pre, num, n
  for token in string.gmatch(m[16], "[^%s]+") do
    pre, num = token:match("^(%D?)(%d+)")
    if not num then
      error("invalid HDRHistogram serialization format")
    end
    num = tonumber(num)
    if pre and #pre > 0 then
      n, num = num, rnumrun[pre]
      if not n then
        error("invalid HDRHistogram serialization format")
      end
      for i=1, n do
        table.insert(counts, num)
      end
    else
      table.insert(counts, num)
    end
  end
  
  tbl.counts = counts
  
  if m[17] and #m[17] > 0 then
    local unit, multiplier = m[17]:match("^%((.*) (.*)%)$")
    tbl._unit = unit
    multiplier = tonumber(multiplier)
    if not multiplier or multipler == 0 then
      error("invalid HDRHistogram serialization format")
    end
    tbl._multiplier = multiplier
  end
  
  local new_hdr = unserialize(tbl)
  data[new_hdr]={
    multiplier= tbl._multiplier or 1,
    unit= tbl._unit or ""
  }
  return new_hdr
end

local merge = hdrmeta.merge
function hdrmeta:merge(hdr2)
  if data[self].multiplier ~= data[hdr2].multiplier then
    error("HDR Histograms have different multipliers and can't be merged")
  elseif data[self].unit ~= data[hdr2].unit then
    error("HDR Histograms have different units and can't be merged")
  end
  return merge(self, hdr2)
end

function hdrmeta:stats(percentiles)
  percentiles = percentiles or {10,20,30,40,50,60,70,80,90,100}
  local out = {}
  local pctf = (data[self].multiplier or 1) < 1 and  "%12." .. math.ceil(math.abs(math.log10(data[self].multiplier, 10))) .. "f" or "%12u"
  local fstr = "%7.3f%% "..pctf..data[self].unit
  for i,v in ipairs(percentiles) do
    table.insert(out, fstr:format(v, self:percentile(v)))
  end
  return table.concat(out, "\n")
end

function hdrmeta:latency_stats()
  local out = {
    "# Latency stats",
    self:stats { 50, 75, 90, 95, 99, 99.9, 99.999 }
  }
  return table.concat(out, "\n")
end

return hdr
