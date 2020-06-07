local split = aurora.string.split
local lfs = require('lfs')
local fs = aurora.fs

--- Recursive directory creation
-- @name mkdir
-- @param p Complete path including desired subdirs
-- @return true if alredy exists
-- @return void
return function (p)
	if fs.isDir(p) then return true end

	print(p)
	local p = split(p,'/')
	local s = ''
	for i,d in ipairs(p) do
		s = s..d..'/'
		local m, me = lfs.mkdir(s)
	end
end
