local ffi = require "ffi"
local prototype = require "libssh2.prototype"

ffi.cdef[[
	int libssh2_base64_decode(LIBSSH2_SESSION *session, char **dest, unsigned int *dest_len, const char *src, unsigned int src_len);
]]

local _M = {}
_M.__index = _M

--[[
url: https://www.libssh2.org/libssh2_base64_decode.html
name: libssh2_base64_decode - decode a base64 encoded string
description: This function is deemed DEPRECATED and will be removed from libssh2 in a future version. Don't use it!
Decode a base64 chunk and store it into a newly allocated buffer. 'dest_len' will be set to hold the length of the returned buffer that '*dest' will point to.
The returned buffer is allocated by this function, but it is not clear how to free that memory!
BUGS
The memory that *dest points to is allocated by the malloc function libssh2 uses, but there's no way for an application to free this data in a safe and reliable way!
RETURN VALUE
0 if successful, -1 if any error occurred.
This HTML page was made with roffit.
]]

function _M.decode(session, dest, dest_len, src, src_len)
	return prototype.libssh2_base64_decode(session, dest, dest_len, src, src_len)
end

return _M