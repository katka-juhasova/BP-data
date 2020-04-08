local path = require('path')

return {
	dest = function (folder)
		path.mkdir(folder)
		return function (file)
			local f = io.open(folder .. '/' .. path.basename(file.path), 'w')
			f:write(file.contents)
			f:close()
		end
	end
}
