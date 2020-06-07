local ffi = require "ffi"
local prototype = require "libssh2.prototype"

ffi.cdef[[
typedef void (*libssh2_trace_handler_func)(LIBSSH2_SESSION *session, void* context, const char *data, size_t length);

int libssh2_trace_sethandler(LIBSSH2_SESSION *session, void* context, libssh2_trace_handler_func callback);
void libssh2_trace(LIBSSH2_SESSION *session, int bitmask);
]]

local _M = {}
_M.__index = _M


--[[
url: https://www.libssh2.org/libssh2_trace_sethandler.html
name: libssh2_trace_sethandler - set a trace output handler
description: libssh2_trace_sethandler installs a trace output handler for your application. By default, when tracing has been switched on via a call to libssh2_trace(), all output is written to stderr.  By calling this method and passing a function pointer that matches the libssh2_trace_handler_func prototype, libssh2 will call back as it generates trace output.  This can be used to capture the trace output and put it into a log file or diagnostic window. This function has no effect unless libssh2 was built to support this option, and a typical "release build" might not.
context can be used to pass arbitrary user defined data back into the callback when invoked.
AVAILABILITY
Added in libssh2 version 1.2.3
This HTML page was made with roffit.
]]

function _M.sethandler(session, context, callback)
	return prototype.libssh2_trace_sethandler(session, context, callback)
end

--[[
url: https://www.libssh2.org/libssh2_trace.html
name: libssh2_trace - enable debug info from inside libssh2
description: This is a function present in the library that can be used to get debug info from within libssh2 when it is running. Helpful when trying to trace or debug behaviors. Note that this function has no effect unless libssh2 was built to support tracing! It is usually disabled in release builds.
bitmask can be set to the logical OR of none, one or more of these:
LIBSSH2_TRACE_SOCKET
Socket low-level debugging
LIBSSH2_TRACE_TRANS
Transport layer debugging
LIBSSH2_TRACE_KEX
Key exchange debugging
LIBSSH2_TRACE_AUTH
Authentication debugging
LIBSSH2_TRACE_CONN
Connection layer debugging
LIBSSH2_TRACE_SCP
SCP debugging
LIBSSH2_TRACE_SFTP
SFTP debugging
LIBSSH2_TRACE_ERROR
Error debugging
LIBSSH2_TRACE_PUBLICKEY
Public Key debugging
This HTML page was made with roffit.
]]

function _M.trace(session, bitmask)
	return prototype.libssh2_trace(session, bitmask)
end


return _M