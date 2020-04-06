local fs = aurora.fs


--- Write contents to a file
-- @name filePutContent
-- @param filename string
-- @return boolean if ok
return function (f, c, append)
	if not fs.isDir(fs.dirname(f)) then
		fs.mkdir(fs.dirname(f))
	end
	local f = io.open(f, append and 'a' or 'w')
	if f then
		f:write(c)
		f:flush()
		f:close()
		return true
	else
		return false
	end
end


