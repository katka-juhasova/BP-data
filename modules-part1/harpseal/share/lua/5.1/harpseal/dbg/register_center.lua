------------------------------------------------------------------------------------
-- a register center for debug/demo only
------------------------------------------------------------------------------------
local Promise = require('lib.Promise')
local MD5 = require('lib.MD5').sumhexa
local dbg_storage = {};

return {
	download_task = function(taskId)
		return Promise.resolve(dbg_storage[string.gsub(taskId, '^task:', "")]);
	end,
	register_task = function(taskDef)
		local id = MD5(tostring(taskDef));
		dbg_storage[id] = taskDef;
		return Promise.resolve('task:' .. id);
	end,

	-- statistics only
	report = function()
		local JSON = require('lib.JSON')
		local JSON_decode = function(...) return JSON:decode(...) end
		local JSON_encode = function(...) return JSON:encode_pretty(...) end
		print('=============================================')
		print('OUTPUT dbg_storage');
		print('=============================================')
		table.foreach(dbg_storage, function(key, value)
			print('==> ', key)
			print(JSON_encode(JSON_decode(value)))
		end)
	end
}