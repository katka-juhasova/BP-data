local ffi = require "ffi"
local prototype = require "libssh2.prototype"
local channel = require "libssh2.channel"

ffi.cdef[[
typedef long long off_t;
typedef struct stat libssh2_struct_stat;
typedef off_t libssh2_struct_stat_size;
typedef unsigned long long libssh2_uint64_t;
typedef long long libssh2_int64_t;
typedef long time_t;

LIBSSH2_CHANNEL * libssh2_scp_recv(LIBSSH2_SESSION *session, const char *path, struct stat *sb);
LIBSSH2_CHANNEL * libssh2_scp_send_ex(LIBSSH2_SESSION *session, const char *path, int mode, size_t size, long mtime, long atime);
LIBSSH2_CHANNEL * libssh2_scp_recv2(LIBSSH2_SESSION *session, const char *path, libssh2_struct_stat *sb);
LIBSSH2_CHANNEL * libssh2_scp_send64(LIBSSH2_SESSION *session, const char *path, int mode, libssh2_int64_t size, time_t mtime, time_t atime);
]]

local _M = {}
_M.__index = _M


--[[
url: https://www.libssh2.org/libssh2_scp_recv.html
name: libssh2_scp_recv - request a remote file via SCP
description: This function is DEPRECATED. Use libssh2_scp_recv2 instead!
session - Session instance as returned by  libssh2_session_init_ex
path - Full path and filename of file to transfer. That is the remote file name.
sb - Populated with remote file's size, mode, mtime, and atime
Request a file from the remote host via SCP.
RETURN VALUE
Pointer to a newly allocated LIBSSH2_CHANNEL instance, or NULL on errors.
ERRORS
LIBSSH2_ERROR_ALLOC -  An internal memory allocation call failed.
LIBSSH2_ERROR_SCP_PROTOCOL -
LIBSSH2_ERROR_EAGAIN - Marked for non-blocking I/O but the call would block.
SEE ALSO
libssh2_session_init_ex, libssh2_channel_open_ex
This HTML page was made with roffit.
]]

function _M.recv(session, path, sb)
	return prototype.libssh2_scp_recv(session, path, sb)
end

--[[
url: https://www.libssh2.org/libssh2_scp_send.html
name: libssh2_scp_send - convenience macro for libssh2_scp_send_ex calls
description: This is a macro defined in a public libssh2 header file that is using the underlying function libssh2_scp_send_ex.
RETURN VALUE
See libssh2_scp_send_ex
ERRORS
See libssh2_scp_send_ex
SEE ALSO
libssh2_scp_send_ex,
This HTML page was made with roffit.
]]

function _M.send(session, path, mode, size)
	return prototype.libssh2_scp_send_ex(session, path, mode, size, 0, 0)
end

--[[
url: https://www.libssh2.org/libssh2_scp_send_ex.html
name: libssh2_scp_send_ex - Send a file via SCP
description: This function has been deemed deprecated since libssh2 1.2.6. See libssh2_scp_send64.
session - Session instance as returned by  libssh2_session_init_ex,
path - Full path and filename of file to transfer to. That is the remote file name.
mode - File access mode to create file with
size - Size of file being transmitted (Must be known  ahead of time precisely)
mtime - mtime to assign to file being created
atime - atime to assign to file being created (Set this and  mtime to zero to instruct remote host to use current time).
Send a file to the remote host via SCP.
RETURN VALUE
Pointer to a newly allocated LIBSSH2_CHANNEL instance, or NULL on errors.
ERRORS
LIBSSH2_ERROR_ALLOC -  An internal memory allocation call failed.
LIBSSH2_ERROR_SOCKET_SEND - Unable to send data on socket.
LIBSSH2_ERROR_SCP_PROTOCOL -
LIBSSH2_ERROR_EAGAIN - Marked for non-blocking I/O but the call would block.
AVAILABILITY
This function was marked deprecated in libssh2 1.2.6 as  libssh2_scp_send64 has been introduced to replace this function.
SEE ALSO
libssh2_channel_open_ex,
This HTML page was made with roffit.
]]

function _M.send_ex(session, path, mode, size, mtime, atime)
	return prototype.libssh2_scp_send_ex(session, path, mode, size, mtime, atime)
end


--[[
url: https://www.libssh2.org/libssh2_scp_recv2.html
name: libssh2_scp_recv2 - request a remote file via SCP
description: session - Session instance as returned by  libssh2_session_init_ex
path - Full path and filename of file to transfer. That is the remote file name.
sb - Populated with remote file's size, mode, mtime, and atime
Request a file from the remote host via SCP.
RETURN VALUE
Pointer to a newly allocated LIBSSH2_CHANNEL instance, or NULL on errors.
ERRORS
LIBSSH2_ERROR_ALLOC -  An internal memory allocation call failed.
LIBSSH2_ERROR_SCP_PROTOCOL -
LIBSSH2_ERROR_EAGAIN - Marked for non-blocking I/O but the call would block.
SEE ALSO
libssh2_session_init_ex, libssh2_channel_open_ex
This HTML page was made with roffit.
]]

function _M.recv2(session, path, sb)
	return prototype.libssh2_scp_recv2(session, path, sb)
end

--[[
url: https://www.libssh2.org/libssh2_scp_send64.html
name: libssh2_scp_send64 - Send a file via SCP
description: session - Session instance as returned by  libssh2_session_init_ex,
path - Full path and filename of file to transfer to. That is the remote file name.
mode - File access mode to create file with
size - Size of file being transmitted (Must be known ahead of time). Note that this needs to be passed on as variable type libssh2_uint64_t. This type is 64 bit on modern operating systems and compilers.
mtime - mtime to assign to file being created
atime - atime to assign to file being created (Set this and  mtime to zero to instruct remote host to use current time).
Send a file to the remote host via SCP.
RETURN VALUE
Pointer to a newly allocated LIBSSH2_CHANNEL instance, or NULL on errors.
ERRORS
LIBSSH2_ERROR_ALLOC -  An internal memory allocation call failed.
LIBSSH2_ERROR_SOCKET_SEND - Unable to send data on socket.
LIBSSH2_ERROR_SCP_PROTOCOL -
LIBSSH2_ERROR_EAGAIN - Marked for non-blocking I/O but the call would block.
AVAILABILITY
This function was added in libssh2 1.2.6 and is meant to replace the former libssh2_scp_send_ex function.
SEE ALSO
libssh2_channel_open_ex,
This HTML page was made with roffit.
]]

function _M.send64(session, path, mode, size, mtime, atime)
	return prototype.libssh2_scp_send64(session, path, mode, size, mtime, atime)
end



return _M