local ffi = require "ffi"
local prototype = require "libssh2.prototype"

ffi.cdef[[
	const char * libssh2_hostkey_hash(LIBSSH2_SESSION *session, int hash_type);
]]

local _M = {}
_M.__index = _M

--[[
url: https://www.libssh2.org/libssh2_hostkey_hash.html
name: libssh2_hostkey_hash - return a hash of the remote host's key
description: session - Session instance as returned by  libssh2_session_init_ex,
hash_type - One of: LIBSSH2_HOSTKEY_HASH_MD5 or  LIBSSH2_HOSTKEY_HASH_SHA1.
Returns the computed digest of the remote system's hostkey. The length of  the returned string is hash_type specific (e.g. 16 bytes for MD5,  20 bytes for SHA1).
RETURN VALUE
Computed hostkey hash value, or NULL if the information is not available (either the session has not yet been started up, or the requested hash algorithm was not available). The hash consists of raw binary bytes, not hex digits, so it is not directly printable.
SEE ALSO
libssh2_session_init_ex,
This HTML page was made with roffit.
]]

function _M.hash(session, hash_type)
	return prototype.libssh2_hostkey_hash(session, hash_type)
end


return _M