local zlib = require "zlib"

local function out32(f, u)
   f:write(string.char(bit32.band(u,255),
           bit32.band(bit32.rshift(u,8),255),
           bit32.band(bit32.rshift(u,16),255),
           bit32.rshift(u,24)))
end

local function out16(f, u)
   f:write(string.char(bit32.band(u,255),
                       bit32.rshift(u,8)))
end

local function out_header(f, ent)
   -- version needed to extract
   out16(f, 20)
   if ent.method == 8 then
      -- general purpose bit flag
      out16(f, 2) -- maximum compression was used
   else
      out16(f, 0) -- bits not used
   end
   -- compression method
   out16(f, ent.method)
   -- file mod time, date
   out16(f, 0)
   out16(f, 0)
   -- crc32
   out32(f, ent.crc)
   -- compressed size
   out32(f, ent.compressed_size)
   -- uncompressed size
   out32(f, ent.uncompressed_size)
   -- file name length
   out16(f, #ent.filename)
   -- extra field length
   out16(f, 0)
end

local flyzip_mt = {__index={}}

function flyzip_mt.__index:add_data(filename, data)
   local f = self.outf
   local ent = {
      offset=assert(f:seek("cur",0)),
      filename=filename,
      uncompressed_size=#data,
      crc=zlib.crc32(0, data),
   }
   -- strip the ZLIB header and footer
   local compressed = zlib.compress(data, 9):sub(3,-5)
   if #compressed >= #data then
      compressed = nil
      ent.method = 0 -- stored
      ent.compressed_size = #data
   else
      ent.method = 8 -- deflated
      ent.compressed_size = #compressed
   end
   self.entries[#self.entries+1] = ent
   -- signature
   out32(f, 0x04034b50)
   -- (common header)
   out_header(f, ent)
   -- filename
   f:write(filename)
   -- data
   f:write(compressed or data)
end

function flyzip_mt.__index:add_file(filename, src)
   if src == nil then src = filename end
   if type(src) == "string" then src = assert(io.open(src,"rb")) end
   self:add_data(filename, assert(src:read("*a")))
   src:close()
end

function flyzip_mt.__index:close()
   local f = self.outf
   local start = assert(f:seek("cur",0))
   for n=1,#self.entries do
      local ent = self.entries[n]
      -- signature
      out32(f, 0x02014b50)
      -- version made by
      out16(f, 20)
      -- (common header)
      out_header(f, ent)
      -- file comment length
      out16(f, 0)
      -- disk number start
      out16(f, 0)
      -- internal file attributes
      out16(f, 0)
      -- external file attributes
      out32(f, 0)
      -- relative offset of local header
      out32(f, ent.offset)
      -- filename!
      f:write(ent.filename)
   end
   local endut = assert(f:seek("cur",0))
   -- signature
   out32(f, 0x06054b50)
   -- disk number (this, start)
   out16(f, 0)
   out16(f, 0)
   -- entry count (this disk, all disks)
   out16(f, #self.entries)
   out16(f, #self.entries)
   -- size of central directory
   out32(f, endut-start)
   -- start of central directory
   out32(f, start)
   -- comment length
   out16(f, 0)
   f:close()
end

local function flyzip(outf)
   local ret = {outf=outf, entries={}}
   setmetatable(ret, flyzip_mt)
   return ret
end

return flyzip
