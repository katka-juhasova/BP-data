local http = require "luajit-curl-helper.http"
local ftp = require "luajit-curl-helper.ftp"
local sftp = require "luajit-curl-helper.sftp"

return {
	http = http,
	ftp = ftp,
	sftp = sftp,
}
