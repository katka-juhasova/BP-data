local geezify={}

function geezify.geezify_2digit(num)
   local oneth_array = {'', '፩', '፪', '፫', '፬', '፭', '፮', '፯', '፰', '፱'}
   local tenth_array = {'', '፲', '፳', '፴', '፵', '፶', '፷', '፸', '፹', '፺'}

   local tenth_index = math.floor(num / 10)
   local oneth_index = num % 10

   return tenth_array[tenth_index+1] .. oneth_array[oneth_index+1]
end

function geezify.geezify_4digit(num)
   local first2 = math.floor(num/100)
   local second2 = num%100

   if first2==0 then
      return geezify.geezify_2digit(second2)
   else
      return geezify.geezify_2digit(first2) ..'፻'.. geezify.geezify_2digit(second2)
   end
end

function geezify.split_every_4_digit(num)

   local a={}

   table.insert(a, string.sub(num,1, string.len(num)%4))

   for digits in string.gmatch(string.sub(num,(string.len(num)%4)+1 ,-1) ,"%d%d%d%d") do
      table.insert(a , digits)
   end

   return a
end


function geezify.geezify(num)

   local digarr = geezify.split_every_4_digit(num)
   local converted= ""

   for i,v in ipairs(digarr) do
      if i==1 and v=='' then
	 converted = converted
      else
	 if converted==nil or converted == '' then
	    converted = (converted or '') .. geezify.geezify_4digit(v)
	 else
	    converted = (converted or "") ..'፼'.. geezify.geezify_4digit(v)
	 end
      end
   end

  local  geez_no =
     string.gsub(
	string.gsub(
	   string.gsub(converted,'፼፩፻', '፼፻')
	   ,'^፩፼', '፼')
	,'^(፩፻)', '፻')
   return geez_no
end

return geezify
