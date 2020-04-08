local path = require('path')
local defaultOptions = { param = 'fm', recurse = true }

return {
	src = function (blob, options)

		if options == nil then
			options = defaultOptions
		end

		local processor = { files = {} }

		function processor:pipe (func)
			for i, file in ipairs(self.files) do
				func(file)
			end
			return self
		end

		path.each(blob, function (p, mode)
			if mode ~= 'directory' then
				local file = io.open(p, 'r')
				table.insert(processor.files, { path = p, contents = file:read('*all') })
				file:close()
			end
		end, options)

		return processor
	end
}
