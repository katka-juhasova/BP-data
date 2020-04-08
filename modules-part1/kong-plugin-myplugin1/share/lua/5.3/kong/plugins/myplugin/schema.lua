local function validation(config)
	if #config.content < 10 then
		return nil, "length of content can not less 10"
	else
		return true
	end
end

return {
	no_consumer = true,
	fields = {
		content = {type = 'string', required = true, default = 'this is my custom content', func = validation}
	}
}
