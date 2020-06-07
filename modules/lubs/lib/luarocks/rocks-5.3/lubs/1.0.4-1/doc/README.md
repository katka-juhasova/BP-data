### Lua Build System - lubs

lubs is an automation toolkit, similar to gulp. It helps make repetitive tasks simpler by providing an easy to use api.

Example `lubsfile.lua`
```lua
local lubs = require('lubs')

lubs.task('lint', function ()
	print('Linting js files')
	lubs.src('./static/js/*.js')
		:pipe(function(file)
			-- run a linter here
			-- file.path = string, absolute path to file
			-- file.contents = string, contents of the file
		end)
end)
```

Example `lubsfile.lua` getting the size and line count of all the files in this repo
```lua
local lubs = require('lubs')
local path = require('path')

lubs.task('size', function ()
	local size, lines = 0, 0
	lubs.src('./*')
		:pipe(function(file)
			local _, count = file.contents:gsub("\n", "\n")
			size, lines = size + path.size(file.path), lines + count
		end)
	print("Total bytes: " .. size .. "\n" .. "Total lines: " .. lines)
end)
```

Example `lubsfile.lua` for compiling .scss files using SassC
```lua
local lubs = require('lubs')
local path = require('path')

function sass (file)
	-- have sassc place result in temporary file (clumsy but works)
	local tmpFilePath = os.tmpname()
	os.execute('sassc ' .. file.path .. ' ' .. tmpFilePath)
	-- read the result of sassc in
	local tmpFile = io.open(tmpFilePath, 'r')
	file.contents = tmpFile:read('*all')
	-- close and delete the file
	tmpFile:close()
	os.remove(tmpFilePath)
	-- replace file extension
	local fileName = path.basename(file.path)
	file.path = fileName:sub(1, fileName:find('%.') - 1) .. '.css'
end

lubs.task('minify', function ()
	print('Minifying scss files')
	lubs.src('./static/styles/*.scss')
		:pipe(sass)
		:pipe(lubs.dest('./static/styles/compiled'))
end)

lubs.task('watch', function()
	lubs.watch('./static/styles/*.scss', {'minify'})
end)
```
