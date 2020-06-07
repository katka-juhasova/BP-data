local hglib = require 'hglib'

local client = hglib.Client.open()

local code, o, e, d = client:runcommand({'version', '--quiet'})
client:close()

if code == 0 then
	print(o:match('%(version (%S+)%)'))
else
	print("Couldn't get version: " .. e)
end
if #d > 0 then
	print('Debug: ')
end
