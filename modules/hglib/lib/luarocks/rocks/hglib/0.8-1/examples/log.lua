local cjson_safe = require 'cjson.safe'
local hglib = require 'hglib'

local client = hglib.Client.open()

client:runcommand({'clone', '-U', 'https://bitbucket.org/av6/lua-hglib', '/tmp/testrepo'})
local code, o, e, d = client:runcommand({'log', '-l', '5', '-T', 'json', '-R', '/tmp/testrepo'})
client:close()

if code == 0 then
	local data = cjson_safe.decode(o)
	print('Last 5 commits:')
	for _, changeset in ipairs(data) do
		local firstline = changeset.desc:match('^[^\n]*')
		print(changeset.rev .. '·' .. changeset.node:sub(1, 12) .. ' ' .. firstline)
	end
else
	print("Couldn't get log: " .. e)
end
if #d > 0 then
	print('Debug: ')
end
