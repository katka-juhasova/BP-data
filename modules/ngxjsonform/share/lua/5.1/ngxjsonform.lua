ngxjsonform = {}

ngxjsonform.parse = function()
	local safeDecode = function(str)
		local cjson = require "cjson"
		local success, decodedJson = pcall(cjson.decode, str)
		if success then
			return decodedJson
		else
			return nil
		end
	end

	ngx.req.read_body()
	local rawData = ngx.req.get_body_data()
	if rawData then
		return safeDecode(rawData)
	else
		return nil
	end
end

return ngxjsonform
