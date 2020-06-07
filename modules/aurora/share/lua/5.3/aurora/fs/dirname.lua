--- Get directory name including path
-- @name dirname
-- @param path full path, including or not the filename
-- @return string or false
return function (p)
	return p:gsub('[^\\/]+[\\/]?$', '')
end
