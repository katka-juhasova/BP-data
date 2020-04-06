local lua_utf8 = require 'lua-utf8'

local arabify = {}

 arabify.numhash =  {
   ['፩'] = 1, ['፪'] = 2, ['፫'] = 3, ['፬'] = 4,
   ['፭'] = 5, ['፮'] = 6, ['፯'] = 7, ['፰'] = 8,
   ['፱'] = 9, ['፲'] = 10, ['፳'] = 20, ['፴'] = 30,
   ['፵'] = 40, ['፶'] = 50, ['፷'] = 60, ['፸'] = 70,
   ['፹'] = 80, ['፺'] = 90, [' '] = 0 }

function arabify.arabify(str)
   local splitted = arabify.split('፼',arabify.rollback(str))
   local sum = 0
   for i,v in ipairs(splitted) do
      if v=='' then
	 sum = sum + (0* 10000^(#splitted - i))
      else
	 sum = sum + (arabify.convert_upto10000(v)* 10000^(#splitted - i))
      end
   end
   return math.floor(sum)
end

function arabify.rollback(str)
   return  lua_utf8.gsub(lua_utf8.gsub(lua_utf8.gsub(str,'^፼', '፩፼'),'^፻', '፩፻'),'፼፻', '፼፩፻')
end

function arabify.convert_2digit(str)
   return (arabify.numhash[lua_utf8.sub(str,1,1)] or 0) + (arabify.numhash[lua_utf8.sub(str,2,2)] or 0)
end


function arabify.convert_upto10000(str)
   if type(str) == 'string' and utf8.len(str) <= 5 and nil == lua_utf8.match(str, '፼') then
      local pos_of_100 = lua_utf8.find(str, '፻') or 0

      if pos_of_100 == 0 then
	 return  arabify.convert_2digit(str)
      elseif pos_of_100 == 1 then
	 return 100 + arabify.convert_2digit(lua_utf8.sub(str, pos_of_100+1, lua_utf8.len(str))) or 0
      else
	 return (arabify.convert_2digit(lua_utf8.sub(str, 1, pos_of_100-1)) or 1) * 100 +
	    (arabify.convert_2digit(lua_utf8.sub(str, pos_of_100+1, lua_utf8.len(str))) or 0)
      end
   end
end

function arabify.split(delimiter, text)
   local list = {}
   local pos = 1
   if lua_utf8.find("", delimiter, 1) then
      error("delimiter matches empty string!")
   end
   while 1 do
      local first, last = lua_utf8.find(text, delimiter, pos)
      if first then
         table.insert(list, lua_utf8.sub(text, pos, first-1))
         pos = last+1
      else
         table.insert(list, lua_utf8.sub(text, pos))
         break
      end
   end
   return list
end


return arabify
