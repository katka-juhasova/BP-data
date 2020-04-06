--- Get basename of the path
-- @name basename 
-- @param path full path of the filename
-- @return string
return function (path)
	return path:gsub('^.*[\\/]','')
end
