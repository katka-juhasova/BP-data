local ffi = require "ffi"
local prototype = require "libssh2.prototype"

ffi.cdef[[
int libssh2_keepalive_send(LIBSSH2_SESSION *session, int *seconds_to_next);
void libssh2_keepalive_config(LIBSSH2_SESSION *session, int want_reply, unsigned interval);
]]

local _M = {}
_M.__index = _M


--[[
url: https://www.libssh2.org/libssh2_keepalive_send.html
name: libssh2_keepalive_send - short function description
description: Send a keepalive message if needed.  seconds_to_next indicates how many seconds you can sleep after this call before you need to call it again.
RETURN VALUE
Returns 0 on success, or LIBSSH2_ERROR_SOCKET_SEND on I/O errors.
AVAILABILITY
Added in libssh2 1.2.5
SEE ALSO
libssh2_keepalive_config,
This HTML page was made with roffit.
]]

function _M.send(session, seconds_to_next)
	return prototype.libssh2_keepalive_send(session, seconds_to_next)
end

--[[
url: https://www.libssh2.org/libssh2_keepalive_config.html
name: libssh2_keepalive_config - short function description
description: Set how often keepalive messages should be sent. want_reply indicates whether the keepalive messages should request a response from the server. interval is number of seconds that can pass without any I/O, use 0 (the default) to disable keepalives.  To avoid some busy-loop corner-cases, if you specify an interval of 1 it will be treated as 2.
Note that non-blocking applications are responsible for sending the keepalive messages using libssh2_keepalive_send.
RETURN VALUE
Nothing
AVAILABILITY
Added in libssh2 1.2.5
SEE ALSO
libssh2_keepalive_send,
This HTML page was made with roffit.
]]

function _M.config(session, want_reply, interval)
	prototype.libssh2_keepalive_config(session, want_reply, interval)
end

return _M