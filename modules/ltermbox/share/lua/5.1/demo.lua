local l = require 'ltermbox'
local d = require "debug"


--ltermbox.new_buffer
local W, H = 143, 112
local function buf() return l.new_buffer(W, H) end

assert(type(buf()) == 'userdata', 'new_buffer failed')
assert(d.getmetatable(buf()) and d.getmetatable(buf()) == d.getregistry().LT_BUFFER_METATABLE_NAME, 'wrong metatable on buffer')

--buffer.size
assert(buf():size() == W , 'wrong buf width')
assert(select(2, buf():size()) == H, 'wrong buf height')

--buffer.change_cell
--buffer.get_cell
--buffer.blit
do
   local b = l.new_buffer(3,5)
   local ch, fg, bg ={ ('9'):byte(), ('A'):byte(), ('*'):byte() },
                     {
                        l.attr.green, 
                        (l.attr.black+l.attr.underline), 
                        (l.attr.magenta+l.attr.bold)
                     }, 
                     { l.attr.white, l.attr.green, l.attr.yellow }
   for x = 1,3 do
      for y = 1,5 do
         b:change_cell(x, y, ch[x], fg[x], bg[x])
         local _ch, _fg, _bg = b:get_cell(x, y)
         assert(ch[x]==_ch and fg[x]==_fg and bg[x]==_bg, 'got wrong cell from buffer')
      end
   end
   l.init()
   b:blit(10, 3)
   l.sync_buffer()
   os.execute('sleep 3')
   l.shutdown()
   l.init()
   b:blit(20,6, 3, 4)
   l.sync_buffer()
   os.execute('sleep 1')
   b:blit(30,16, 1, 4)
   l.sync_buffer()
   os.execute('sleep 1')
   b:blit(2,22, 4)
   l.sync_buffer()
   os.execute('sleep 3')
   l.shutdown()
end

--ltermbox.change_cell
do
   l.init()
   local s = 'hello world'
   for i = 1, #s do
      l.change_cell(i, 3, (s):byte(i), l.attr.yellow, l.attr.cyan) 
   end
   l.sync_buffer()
   os.execute('sleep 3')
   l.shutdown()
end

--buffer.shift_[up|down]
do
   local b = l.new_buffer(2,4)
   for x = 1,2 do 
      for y = 1,4 do
         b:change_cell(x, y, ('#'):byte(), l.attr.white, l.attr.black)
      end 
   end
   b:change_cell(1,1, ('@'):byte(), l.attr.magenta, l.attr.green)
   b:change_cell(2,2, ('$'):byte(), l.attr.yellow, l.attr.red)
   l.init()
   b:blit(1,1)
   l.sync_buffer()
   os.execute('sleep 2')
   b:shift_down()
   b:blit(3,1)
   l.sync_buffer()
   os.execute('sleep 2')
   b:shift_up(2)
   b:blit(5,1)
   l.sync_buffer()
   os.execute('sleep 3')
   l.shutdown()
end


