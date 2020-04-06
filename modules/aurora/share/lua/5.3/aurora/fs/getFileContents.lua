--- Get contents of a file
-- @name fileGetContent
-- @param filename string
-- @return string if ok
-- @return nil if error
return function (file)
	local f,c = io.open(file), false
	if f then
		c = f:read('a')
		f:close()
	end
	return c
end

