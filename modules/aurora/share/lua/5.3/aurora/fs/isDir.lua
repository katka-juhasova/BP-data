local lfs = require('lfs')


--- Check if path is directory
-- @name isDir
-- @param path string containing path analyzed
-- @return bool
return function (path)
	return lfs.attributes(path,'mode') == 'directory'
end
