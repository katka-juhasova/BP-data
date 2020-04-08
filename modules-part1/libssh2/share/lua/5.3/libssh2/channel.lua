local ffi = require "ffi"
local prototype = require "libssh2.prototype"
local session = require "libssh2.session"
local libssh2 = require "libssh2.libssh2"

ffi.cdef[[
	typedef enum {
		LIBSSH2_CHANNEL_WINDOW_DEFAULT  = (2*1024*1024),
		LIBSSH2_CHANNEL_PACKET_DEFAULT  = 32768,
		LIBSSH2_CHANNEL_MINADJUST       = 1024,
	};

	unsigned long libssh2_channel_window_read_ex(LIBSSH2_CHANNEL *channel, unsigned long *read_avail, unsigned long *window_size_initial);
	int libssh2_channel_x11_req_ex(LIBSSH2_CHANNEL *channel, int single_connection, const char *auth_proto, const char *auth_cookie, int screen_number);
	int libssh2_channel_process_startup(LIBSSH2_CHANNEL *channel, const char *request, unsigned int request_len, const char *message, unsigned int message_len);
	int libssh2_channel_request_pty_ex(LIBSSH2_CHANNEL *channel, const char *term, unsigned int term_len, const char *modes, unsigned int modes_len, int width, int height, int width_px, int height_px);
	int libssh2_channel_send_eof(LIBSSH2_CHANNEL *channel);
	int libssh2_poll_channel_read(LIBSSH2_CHANNEL *channel, int extended);
	void libssh2_channel_handle_extended_data(LIBSSH2_CHANNEL *channel, int ignore_mode);
	LIBSSH2_CHANNEL * libssh2_channel_forward_accept(LIBSSH2_LISTENER *listener);
	LIBSSH2_LISTENER * libssh2_channel_forward_listen_ex(LIBSSH2_SESSION *session, char *host, int port, int *bound_port, int queue_maxsize);
	ssize_t libssh2_channel_read_ex(LIBSSH2_CHANNEL *channel, int stream_id, char *buf, size_t buflen);
	unsigned long libssh2_channel_receive_window_adjust(LIBSSH2_CHANNEL * channel, unsigned long adjustment, unsigned char force);
	int libssh2_channel_setenv_ex(LIBSSH2_CHANNEL *channel, char *varname, unsigned int varname_len, const char *value, unsigned int value_len);
	int libssh2_channel_handle_extended_data2(LIBSSH2_CHANNEL *channel, int ignore_mode);
	int libssh2_channel_request_pty_size_ex(LIBSSH2_CHANNEL *channel, int width, int height, int width_px, int height_px);
	int libssh2_channel_forward_cancel(LIBSSH2_LISTENER *listener);
	int libssh2_channel_close(LIBSSH2_CHANNEL *channel);
	LIBSSH2_CHANNEL * libssh2_channel_open_ex(LIBSSH2_SESSION *session, const char *channel_type, unsigned int channel_type_len, unsigned int window_size, unsigned int packet_size, const char *message, unsigned int message_len);
	void libssh2_channel_set_blocking(LIBSSH2_CHANNEL *channel, int blocking);
	int libssh2_channel_eof(LIBSSH2_CHANNEL *channel);
	unsigned long libssh2_channel_window_write_ex(LIBSSH2_CHANNEL *channel, unsigned long *window_size_initial);
	int libssh2_channel_get_exit_signal(LIBSSH2_CHANNEL *channel, char **exitsignal, size_t *exitsignal_len, char **errmsg, size_t *errmsg_len, char **langtag, size_t *langtag_len);
	ssize_t libssh2_channel_write_ex(LIBSSH2_CHANNEL *channel, int stream_id, char *buf, size_t buflen);
	int libssh2_channel_wait_eof(LIBSSH2_CHANNEL *channel);
	int libssh2_channel_get_exit_status(LIBSSH2_CHANNEL* channel);
	LIBSSH2_CHANNEL * libssh2_channel_direct_tcpip_ex(LIBSSH2_SESSION *session, const char *host, int port, const char *shost, int sport);
	int libssh2_channel_flush_ex(LIBSSH2_CHANNEL *channel, int streamid);
	int libssh2_channel_wait_closed(LIBSSH2_CHANNEL *channel);
	int libssh2_channel_receive_window_adjust2(LIBSSH2_CHANNEL * channel, unsigned long adjustment, unsigned char force, unsigned int *window);
	int libssh2_channel_free(LIBSSH2_CHANNEL *channel);
]]

local _M = {}
_M.__index = _M

--[[
url: https://www.libssh2.org/libssh2_channel_flush_stderr.html
name: libssh2_channel_flush_stderr - convenience macro for libssh2_channel_flush_ex calls
description: This is a macro defined in a public libssh2 header file that is using the underlying function libssh2_channel_flush_ex.
RETURN VALUE
See libssh2_channel_flush_ex
ERRORS
See libssh2_channel_flush_ex
SEE ALSO
libssh2_channel_flush_ex,
This HTML page was made with roffit.
]]

function _M:flush_stderr()
	return self:flush_ex(ffi.C.SSH_EXTENDED_DATA_STDERR)
end

--[[
url: https://www.libssh2.org/libssh2_channel_window_read_ex.html
name: libssh2_channel_window_read_ex - Check the status of the read window
description: Check the status of the read window. Returns the number of bytes which the remote end may send without overflowing the window limit read_avail (if passed) will be populated with the number of bytes actually available to be read window_size_initial (if passed) will be populated with the window_size_initial as defined by the channel_open request
RETURN VALUE
The number of bytes which the remote end may send without overflowing the window limit
ERRORS
SEE ALSO
libssh2_channel_receive_window_adjust, libssh2_channel_window_write_ex,
This HTML page was made with roffit.
]]

function _M:window_read_ex(read_avail, window_size_initial)
	return prototype.libssh2_channel_window_read_ex(self.channel, read_avail, window_size_initial)
end

--[[
url: https://www.libssh2.org/libssh2_channel_subsystem.html
name: libssh2_channel_subsystem - convenience macro for libssh2_channel_process_startup calls
description: This is a macro defined in a public libssh2 header file that is using the underlying function libssh2_channel_process_startup.
RETURN VALUE
See libssh2_channel_process_startup
ERRORS
See libssh2_channel_process_startup
SEE ALSO
libssh2_channel_process_startup,
This HTML page was made with roffit.
]]

function _M:subsystem(subsystem)
	return prototype.libssh2_channel_process_startup(self.channel, "subsystem", libssh2.c_strlen("subsystem"), substream, libssh2.c_strlen(subsystem))
end

--[[
url: https://www.libssh2.org/libssh2_channel_x11_req_ex.html
name: libssh2_channel_x11_req_ex - request an X11 forwarding channel
description: channel - Previously opened channel instance such as returned by libssh2_channel_open_ex,
single_connection - non-zero to only forward a single connection.
auth_proto - X11 authentication protocol to use
auth_cookie - the cookie (hexadecimal encoded).
screen_number - the XLL screen to forward
Request an X11 forwarding on channel. To use X11 forwarding,  libssh2_session_callback_set, must first be called to set LIBSSH2_CALLBACK_X11. This callback will be invoked when the remote host accepts the X11 forwarding.
RETURN VALUE
Return 0 on success or negative on failure.  It returns LIBSSH2_ERROR_EAGAIN when it would otherwise block. While LIBSSH2_ERROR_EAGAIN is a negative number, it isn't really a failure per se.
ERRORS
LIBSSH2_ERROR_ALLOC -  An internal memory allocation call failed.
LIBSSH2_ERROR_SOCKET_SEND - Unable to send data on socket.
LIBSSH2_ERROR_CHANNEL_REQUEST_DENIED -
SEE ALSO
libssh2_channel_open_ex, libssh2_session_callback_set,
This HTML page was made with roffit.
]]

function _M:x11_req_ex(single_connection, auth_proto, auth_cookie, screen_number)
	return prototype.libssh2_channel_x11_req_ex(self.channel, single_connection, auth_proto, auth_cookie, screen_number)
end

--[[
url: https://www.libssh2.org/libssh2_channel_process_startup.html
name: libssh2_channel_process_startup - request a shell on a channel
description: channel - Active session channel instance.
request - Type of process to startup. The SSH2 protocol currently  defines shell, exec, and subsystem as standard process services.
request_len - Length of request parameter.
message - Request specific message data to include.
message_len - Length of message parameter.
Initiate a request on a session type channel such as returned by  libssh2_channel_open_ex,
RETURN VALUE
Return 0 on success or negative on failure.  It returns LIBSSH2_ERROR_EAGAIN when it would otherwise block. While LIBSSH2_ERROR_EAGAIN is a negative number, it isn't really a failure per se.
ERRORS
LIBSSH2_ERROR_ALLOC -  An internal memory allocation call failed.
LIBSSH2_ERROR_SOCKET_SEND - Unable to send data on socket.
LIBSSH2_ERROR_CHANNEL_REQUEST_DENIED -
SEE ALSO
libssh2_channel_open_ex,
This HTML page was made with roffit.
]]

function _M:process_startup(request, request_len, message, message_len)
	return prototype.libssh2_channel_process_startup(self.channel, request, request_len, message, message_len)
end

--[[
url: https://www.libssh2.org/libssh2_channel_shell.html
name: libssh2_channel_shell - convenience macro for libssh2_channel_process_startup calls
description: This is a macro defined in a public libssh2 header file that is using the underlying function libssh2_channel_process_startup.
RETURN VALUE
See libssh2_channel_process_startup
ERRORS
See libssh2_channel_process_startup
SEE ALSO
libssh2_channel_process_startup,
This HTML page was made with roffit.
]]

function _M:shell()
	return self:process_startup(libssh2.c_string("shell"), libssh2.c_strlen("shell"), nil, 0)
end

--[[
url: https://www.libssh2.org/libssh2_channel_request_pty_ex.html
name: libssh2_channel_request_pty_ex - short function description
description: channel - Previously opened channel instance such as returned by  libssh2_channel_open_ex,
term - Terminal emulation (e.g. vt102, ansi, etc...)
term_len - Length of term parameter
modes - Terminal mode modifier values
modes_len - Length of modes parameter.
width - Width of pty in characters
height - Height of pty in characters
width_px - Width of pty in pixels
height_px - Height of pty in pixels
Request a PTY on an established channel. Note that this does not make sense  for all channel types and may be ignored by the server despite returning  success.
RETURN VALUE
Return 0 on success or negative on failure.  It returns LIBSSH2_ERROR_EAGAIN when it would otherwise block. While LIBSSH2_ERROR_EAGAIN is a negative number, it isn't really a failure per se.
ERRORS
LIBSSH2_ERROR_ALLOC -  An internal memory allocation call failed.
LIBSSH2_ERROR_SOCKET_SEND - Unable to send data on socket.
LIBSSH2_ERROR_CHANNEL_REQUEST_DENIED -
SEE ALSO
libssh2_channel_open_ex,
This HTML page was made with roffit.
]]

function _M:request_pty_ex(term, term_len, modes, modes_len, width, height, width_px, height_px)
	return prototype.libssh2_channel_request_pty_ex(self.channel, term, term_len, modes, modes_len, width, height, width_px, height_px)
end

--[[
url: https://www.libssh2.org/libssh2_channel_send_eof.html
name: libssh2_channel_send_eof - send EOF to remote server
description: Tell the remote host that no further data will be sent on the specified  channel. Processes typically interpret this as a closed stdin descriptor.
RETURN VALUE
Return 0 on success or negative on failure.  It returns LIBSSH2_ERROR_EAGAIN when it would otherwise block. While LIBSSH2_ERROR_EAGAIN is a negative number, it isn't really a failure per se.
ERRORS
LIBSSH2_ERROR_SOCKET_SEND - Unable to send data on socket.
SEE ALSO
libssh2_channel_wait_eof, libssh2_channel_eof,
This HTML page was made with roffit.
]]

function _M:send_eof()
	return prototype.libssh2_channel_send_eof(self.channel)
end

--[[
url: https://www.libssh2.org/libssh2_channel_x11_req.html
name: libssh2_channel_x11_req - convenience macro for libssh2_channel_x11_req_ex calls
description: This is a macro defined in a public libssh2 header file that is using the underlying function libssh2_channel_x11_req_ex.
RETURN VALUE
See libssh2_channel_x11_req_ex
ERRORS
See libssh2_channel_x11_req_ex
SEE ALSO
libssh2_channel_x11_req_ex,
This HTML page was made with roffit.
]]

function _M:x11_req(screen_number)
	return prototype.libssh2_channel_x11_req_ex(self.channel, 0, nil, nil, screen_number)
end

--[[
url: https://www.libssh2.org/libssh2_poll_channel_read.html
name: libssh2_poll_channel_read - check if data is available
description: This function is deprecated. Do note use.
libssh2_poll_channel_read checks to see if data is available in the channel's read buffer. No attempt is made with this method to see if packets are available to be processed. For full polling support, use libssh2_poll.
RETURN VALUE
Returns 1 when data is available and 0 otherwise.
SEE ALSO
libssh2_poll,
This HTML page was made with roffit.
]]

function _M:poll_channel_read(extended)
	return prototype.libssh2_poll_channel_read(self.channel, extended)
end

--[[
url: https://www.libssh2.org/libssh2_channel_handle_extended_data.html
name: libssh2_channel_handle_extended_data - set extended data handling mode
description: This function is deprecated. Use the libssh2_channel_handle_extended_data2 function instead!
channel - Active channel stream to change extended data handling on.
ignore_mode - One of the three LIBSSH2_CHANNEL_EXTENDED_DATA_* Constants. LIBSSH2_CHANNEL_EXTENDED_DATA_NORMAL: Queue extended data for eventual  reading LIBSSH2_CHANNEL_EXTENDED_DATA_MERGE: Treat extended data and ordinary data the same. Merge all substreams such that calls to libssh2_channel_read will pull from all substreams on a first-in
Change how a channel deals with extended data packets. By default all extended data is queued until read by libssh2_channel_read_ex
RETURN VALUE
None.
SEE ALSO
libssh2_channel_handle_extended_data2, libssh2_channel_read_ex,
This HTML page was made with roffit.
]]

function _M:handle_extended_data(ignore_mode)
	prototype.libssh2_channel_handle_extended_data(self.channel, ignore_mode)
end

--[[
url: https://www.libssh2.org/libssh2_channel_forward_accept.html
name: libssh2_channel_forward_accept - accept a queued connection
description: listener is a forwarding listener instance as returned by libssh2_channel_forward_listen_ex.
RETURN VALUE
A newly allocated channel instance or NULL on failure.
ERRORS
When this function returns NULL use libssh2_session_last_errno to extract the error code. If that code is LIBSSH2_ERROR_EAGAIN, the session is set to do non-blocking I/O but the call would block.
SEE ALSO
libssh2_channel_forward_listen_ex,
This HTML page was made with roffit.
]]

function _M.forward_accept(listener)
	local self = {}

	self.channel = prototype.libssh2_channel_forward_accept(listener)
	ffi.gc(self.channel, prototype.libssh2_channel_free)

	return setmetatable(self, _M)
end

--[[
url: https://www.libssh2.org/libssh2_channel_forward_listen_ex.html
name: libssh2_channel_forward_listen_ex - listen to inbound connections
description: Instruct the remote SSH server to begin listening for inbound TCP/IP connections. New connections will be queued by the library until accepted by libssh2_channel_forward_accept.
session - instance as returned by libssh2_session_init().
host - specific address to bind to on the remote host. Binding to 0.0.0.0 (default when NULL is passed) will bind to all available addresses.
port - port to bind to on the remote host. When 0 is passed, the remote host will select the first available dynamic port.
bound_port - Populated with the actual port bound on the remote host. Useful when requesting dynamic port numbers.
queue_maxsize - Maximum number of pending connections to queue before rejecting further attempts.
libssh2_channel_forward_listen is a macro.
RETURN VALUE
A newly allocated LIBSSH2_LISTENER instance or NULL on failure.
ERRORS
LIBSSH2_ERROR_ALLOC - An internal memory allocation call failed.
LIBSSH2_ERROR_SOCKET_SEND - Unable to send data on socket.
LIBSSH2_ERROR_PROTO - An invalid SSH protocol response was received on the socket.
LIBSSH2_ERROR_REQUEST_DENIED - The remote server refused the request.
LIBSSH2_ERROR_EAGAIN - Marked for non-blocking I/O but the call would block.
SEE ALSO
libssh2_channel_forward_accept,
This HTML page was made with roffit.
]]

function _M.forward_listen_ex(session, host, port, bound_port, queue_maxsize)
	return prototype.libssh2_channel_forward_listen_ex(session, host, port, bound_port, queue_maxsize)
end

--[[
url: https://www.libssh2.org/libssh2_channel_read_ex.html
name: libssh2_channel_read_ex - read data from a channel stream
description: Attempt to read data from an active channel stream. All channel streams have one standard I/O substream (stream_id == 0), and may have up to 2^32 extended data streams as identified by the selected stream_id. The SSH2 protocol currently defines a stream ID of 1 to be the stderr substream.
channel - active channel stream to read from.
stream_id - substream ID number (e.g. 0 or SSH_EXTENDED_DATA_STDERR)
buf - pointer to storage buffer to read data into
buflen - size of the buf storage
libssh2_channel_read and libssh2_channel_read_stderr are macros.
RETURN VALUE
Actual number of bytes read or negative on failure. It returns LIBSSH2_ERROR_EAGAIN when it would otherwise block. While LIBSSH2_ERROR_EAGAIN is a negative number, it isn't really a failure per se.
Note that a return value of zero (0) can in fact be a legitimate value and only signals that no payload data was read. It is not an error.
ERRORS
LIBSSH2_ERROR_SOCKET_SEND - Unable to send data on socket.
LIBSSH2_ERROR_CHANNEL_CLOSED - The channel has been closed.
SEE ALSO
libssh2_poll_channel_read,
This HTML page was made with roffit.
]]

function _M:read_ex(stream_id, buf, buflen)
	return prototype.libssh2_channel_read_ex(self.channel, stream_id, buf, buflen)
end

--[[
url: https://www.libssh2.org/libssh2_channel_receive_window_adjust.html
name: libssh2_channel_receive_window_adjust - adjust the channel window
description: This function is deprecated in 1.1. Use libssh2_channel_receive_window_adjust2!
Adjust the receive window for a channel by adjustment bytes. If the amount to be adjusted is less than LIBSSH2_CHANNEL_MINADJUST and force is 0 the adjustment amount will be queued for a later packet.
RETURN VALUE
Returns the new size of the receive window (as understood by remote end). Note that the window value sent over the wire is strictly 32bit, but this API is made to return a 'long' which may not be 32 bit on all platforms.
ERRORS
In 1.0 and earlier, this function returns LIBSSH2_ERROR_EAGAIN for non-blocking channels where it would otherwise block. However, that is a negative number and this function only returns an unsigned value and this then leads to a very strange value being returned.
SEE ALSO
libssh2_channel_window_read_ex,
This HTML page was made with roffit.
]]

function _M:receive_window_adjust(adjustment, force)
	return prototype.libssh2_channel_receive_window_adjust(self.channel, adjustment, force)
end

--[[
url: https://www.libssh2.org/libssh2_channel_setenv_ex.html
name: libssh2_channel_setenv_ex - set an environment variable on the channel
description: channel - Previously opened channel instance such as returned by  libssh2_channel_open_ex,
varname - Name of environment variable to set on the remote  channel instance.
varname_len - Length of passed varname parameter.
value - Value to set varname to.
value_len - Length of value parameter.
Set an environment variable in the remote channel's process space. Note that this does not make sense for all channel types and may be ignored by the server despite returning success.
RETURN VALUE
Return 0 on success or negative on failure.  It returns LIBSSH2_ERROR_EAGAIN when it would otherwise block. While LIBSSH2_ERROR_EAGAIN is a negative number, it isn't really a failure per se.
ERRORS
LIBSSH2_ERROR_ALLOC -  An internal memory allocation call failed.
LIBSSH2_ERROR_SOCKET_SEND - Unable to send data on socket.
LIBSSH2_ERROR_CHANNEL_REQUEST_DENIED -
SEE ALSO
libssh2_channel_open_ex,
This HTML page was made with roffit.
]]

function _M:setenv_ex(varname, varname_len, value, value_len)
	return prototype.libssh2_channel_setenv_ex(self.channel, varname, varname_len, value, value_len)
end

--[[
url: https://www.libssh2.org/libssh2_channel_handle_extended_data2.html
name: libssh2_channel_handle_extended_data2 - set extended data handling mode
description: channel - Active channel stream to change extended data handling on.
ignore_mode - One of the three LIBSSH2_CHANNEL_EXTENDED_DATA_* Constants. LIBSSH2_CHANNEL_EXTENDED_DATA_NORMAL: Queue extended data for eventual  reading LIBSSH2_CHANNEL_EXTENDED_DATA_MERGE: Treat extended data and ordinary  data the same. Merge all substreams such that calls to  libssh2_channel_read, will pull from all substreams on a first-in/first-out basis. LIBSSH2_CHANNEL_EXTENDED_DATA_IGNORE: Discard all extended data as it  arrives.
Change how a channel deals with extended data packets. By default all  extended data is queued until read by  libssh2_channel_read_ex,
RETURN VALUE
Return 0 on success or LIBSSH2_ERROR_EAGAIN when it would otherwise block.
SEE ALSO
libssh2_channel_handle_extended_data, libssh2_channel_read_ex,
This HTML page was made with roffit.
]]

function _M:handle_extended_data2(ignore_mode)
	return prototype.libssh2_channel_handle_extended_data2(self.channel, ignore_mode)
end

--[[
url: https://www.libssh2.org/libssh2_channel_request_pty_size_ex.html
name: libssh2_channel_request_pty_size_ex - TODO
description: RETURN VALUE
ERRORS
SEE ALSO
This HTML page was made with roffit.
]]

function _M:request_pty_size_ex(width, height, width_px, height_px)
	return prototype.libssh2_channel_request_pty_size_ex(self.channel, width, height, width_px, height_px)
end

--[[
url: https://www.libssh2.org/libssh2_channel_window_write.html
name: libssh2_channel_window_write - convenience macro for libssh2_channel_window_write_ex calls
description: This is a macro defined in a public libssh2 header file that is using the underlying function libssh2_channel_window_write_ex.
RETURN VALUE
See libssh2_channel_window_write_ex
ERRORS
See libssh2_channel_window_write_ex
SEE ALSO
libssh2_channel_window_write_ex,
This HTML page was made with roffit.
]]

function _M:window_write()
	return prototype.libssh2_channel_window_write_ex(self.channel, nil)
end

--[[
url: https://www.libssh2.org/libssh2_channel_read.html
name: libssh2_channel_read - convenience macro for libssh2_channel_read_ex calls
description: This is a macro defined in a public libssh2 header file that is using the underlying function libssh2_channel_read_ex.
RETURN VALUE
See libssh2_channel_read_ex
ERRORS
See libssh2_channel_read_ex
SEE ALSO
libssh2_channel_read_ex,
This HTML page was made with roffit.
]]

function _M:read(buf, buflen)
	return prototype.libssh2_channel_read_ex(self.channel, 0, buf, buflen)
end


--[[
url: https://www.libssh2.org/libssh2_channel_forward_cancel.html
name: libssh2_channel_forward_cancel - cancel a forwarded TCP port
description: listener - Forwarding listener instance as returned by  libssh2_channel_forward_listen_ex,
Instruct the remote host to stop listening for new connections on a previously requested host/port.
RETURN VALUE
Return 0 on success or negative on failure.  It returns LIBSSH2_ERROR_EAGAIN when it would otherwise block. While LIBSSH2_ERROR_EAGAIN is a negative number, it isn't really a failure per se.
ERRORS
LIBSSH2_ERROR_ALLOC -  An internal memory allocation call failed.
LIBSSH2_ERROR_SOCKET_SEND - Unable to send data on socket.
SEE ALSO
libssh2_channel_forward_listen_ex,
This HTML page was made with roffit.
]]

function _M.forward_cancel(listener)
	return prototype.libssh2_channel_forward_cancel(listener)
end

--[[
url: https://www.libssh2.org/libssh2_channel_close.html
name: libssh2_channel_close - close a channel
description: channel - active channel stream to set closed status on.
Close an active data channel. In practice this means sending an SSH_MSG_CLOSE  packet to the remote host which serves as instruction that no further data  will be sent to it. The remote host may still send data back until it sends  its own close message in response. To wait for the remote end to close its  connection as well, follow this command with  libssh2_channel_wait_closed,
RETURN VALUE
Return 0 on success or negative on failure.  It returns LIBSSH2_ERROR_EAGAIN when it would otherwise block. While LIBSSH2_ERROR_EAGAIN is a negative number, it isn't really a failure per se.
ERRORS
LIBSSH2_ERROR_SOCKET_SEND - Unable to send data on socket.
SEE ALSO
libssh2_channel_open_ex,
This HTML page was made with roffit.
]]

function _M:close()
	return prototype.libssh2_channel_close(self.channel)
end

--[[
url: https://www.libssh2.org/libssh2_channel_direct_tcpip.html
name: libssh2_channel_direct_tcpip - convenience macro for libssh2_channel_direct_tcpip_ex calls
description: This is a macro defined in a public libssh2 header file that is using the underlying function libssh2_channel_direct_tcpip_ex.
RETURN VALUE
See libssh2_channel_direct_tcpip_ex
ERRORS
See libssh2_channel_direct_tcpip_ex
SEE ALSO
libssh2_channel_direct_tcpip_ex,
This HTML page was made with roffit.
]]

function _M.direct_tcpip(session, host, port)
	local self = {}

	self.channel = prototype.libssh2_channel_direct_tcpip_ex(session, host, port, libssh2.c_string("127.0.0.1"), 22)
	ffi.gc(self.channel, prototype.libssh2_channel_free)

	return setmetatable(self, _M)
end

--[[
url: https://www.libssh2.org/libssh2_channel_open_ex.html
name: libssh2_channel_open_ex - establish a generic session channel
description: session - Session instance as returned by  libssh2_session_init_ex,
channel_type - Channel type to open. Typically one of session,  direct-tcpip, or tcpip-forward. The SSH2 protocol allowed for additional  types including local, custom channel types.
channel_type_len - Length of channel_type
window_size - Maximum amount of unacknowledged data remote host is  allowed to send before receiving an SSH_MSG_CHANNEL_WINDOW_ADJUST packet.
packet_size - Maximum number of bytes remote host is allowed to send  in a single SSH_MSG_CHANNEL_DATA or SSG_MSG_CHANNEL_EXTENDED_DATA packet.
message - Additional data as required by the selected channel_type.
message_len - Length of message parameter.
Allocate a new channel for exchanging data with the server. This method is  typically called through its macroized form:  libssh2_channel_open_session, or via  libssh2_channel_direct_tcpip, or libssh2_channel_forward_listen,
RETURN VALUE
Pointer to a newly allocated LIBSSH2_CHANNEL instance, or NULL on errors.
ERRORS
LIBSSH2_ERROR_ALLOC -  An internal memory allocation call failed.
LIBSSH2_ERROR_SOCKET_SEND - Unable to send data on socket.
LIBSSH2_ERROR_CHANNEL_FAILURE -
LIBSSH2_ERROR_EAGAIN - Marked for non-blocking I/O but the call would block.
SEE ALSO
Add related functions
This HTML page was made with roffit.
]]

function _M.open_ex(session, channel_type, channel_type_len, window_size, packet_size, message, message_len)
	local self = {}

	self.channel = prototype.libssh2_channel_open_ex(session, channel_type, channel_type_len, window_size, packet_size, message, message_len)
	ffi.gc(self.channel, prototype.libssh2_channel_free)

	return setmetatable(self, _M)
end

--[[
url: https://www.libssh2.org/libssh2_channel_flush.html
name: libssh2_channel_flush - convenience macro for libssh2_channel_flush_ex calls
description: This is a macro defined in a public libssh2 header file that is using the underlying function libssh2_channel_flush_ex.
RETURN VALUE
See libssh2_channel_flush_ex
ERRORS
See libssh2_channel_flush_ex
SEE ALSO
libssh2_channel_flush_ex,
This HTML page was made with roffit.
]]

function _M:libssh2_channel_flush()
	return prototype.libssh2_channel_flush_ex(self.channel, 0)
end

--[[
url: https://www.libssh2.org/libssh2_channel_set_blocking.html
name: libssh2_channel_set_blocking - set or clear blocking mode on channel
description: channel - channel stream to set or clean blocking status on.
blocking - Set to a non-zero value to make the channel block, or zero to make it non-blocking.
Currently this is just a short cut call to  libssh2_session_set_blocking, and therefore will affect the session and all channels.
RETURN VALUE
None
SEE ALSO
libssh2_session_set_blocking, libssh2_channel_read_ex, libssh2_channel_write_ex,
This HTML page was made with roffit.
]]

function _M:set_blocking(blocking)
	return prototype.libssh2_channel_set_blocking(self.channel, blocking)
end

--[[
url: https://www.libssh2.org/libssh2_channel_ignore_extended_data.html
name: libssh2_channel_ignore_extended_data - convenience macro for libssh2_channel_handle_extended_data calls
description: This function is deprecated. Use the libssh2_channel_handle_extended_data2 function instead!
This is a macro defined in a public libssh2 header file that is using the underlying function libssh2_channel_handle_extended_data.
RETURN VALUE
See libssh2_channel_handle_extended_data
ERRORS
See libssh2_channel_handle_extended_data
SEE ALSO
libssh2_channel_handle_extended_data,
This HTML page was made with roffit.
]]

--libssh2_channel_ignore_extended_data(arguments)

--[[
url: https://www.libssh2.org/libssh2_channel_window_read.html
name: libssh2_channel_window_read - convenience macro for libssh2_channel_window_read_ex calls
description: This is a macro defined in a public libssh2 header file that is using the underlying function libssh2_channel_window_read_ex.
RETURN VALUE
See libssh2_channel_window_read_ex
ERRORS
See libssh2_channel_window_read_ex
SEE ALSO
libssh2_channel_window_read_ex,
This HTML page was made with roffit.
]]

function _M:window_read()
	return prototype.libssh2_channel_window_read_ex(self.channel, nil, nil)
end

--[[
url: https://www.libssh2.org/libssh2_channel_eof.html
name: libssh2_channel_eof - check a channel's EOF status
description: channel - active channel stream to set closed status on.
Check if the remote host has sent an EOF status for the selected stream.
RETURN VALUE
Returns 1 if the remote host has sent EOF, otherwise 0. Negative on failure.
SEE ALSO
libssh2_channel_close,
This HTML page was made with roffit.
]]

function _M:eof()
	return prototype.libssh2_channel_eof(self.channel)
end

--[[
url: https://www.libssh2.org/libssh2_channel_write_stderr.html
name: libssh2_channel_write_stderr - convenience macro for libssh2_channel_write_ex
description: This is a macro defined in a public libssh2 header file that is using the underlying function libssh2_channel_write_ex.
RETURN VALUE
See libssh2_channel_write_ex
ERRORS
See libssh2_channel_write_ex
SEE ALSO
libssh2_channel_write_ex,
This HTML page was made with roffit.
]]

function _M:write_stderr(buf, buflen)
	return prototype.libssh2_channel_write_ex(self.channel, ffi.C.SSH_EXTENDED_DATA_STDERR, buf, buflen)
end

--[[
url: https://www.libssh2.org/libssh2_channel_read_stderr.html
name: libssh2_channel_read_stderr - convenience macro for libssh2_channel_read_ex calls
description: This is a macro defined in a public libssh2 header file that is using the underlying function libssh2_channel_read_ex.
RETURN VALUE
See libssh2_channel_read_ex
ERRORS
See libssh2_channel_read_ex
SEE ALSO
libssh2_channel_read_ex,
This HTML page was made with roffit.
]]

function _M:read_stderr(buf, buflen)
	return prototype.libssh2_channel_read_ex(self.channel, ffi.C.SSH_EXTENDED_DATA_STDERR, buf, buflen)
end

--[[
url: https://www.libssh2.org/libssh2_channel_setenv.html
name: libssh2_channel_setenv - convenience macro for libssh2_channel_setenv_ex calls
description: This is a macro defined in a public libssh2 header file that is using the underlying function libssh2_channel_setenv_ex.
RETURN VALUE
See libssh2_channel_setenv_ex
ERRORS
See libssh2_channel_setenv_ex
SEE ALSO
libssh2_channel_setenv_ex,
This HTML page was made with roffit.
]]

function _M:setenv(varname, value)
	return self:setenv_ex(varname, libssh2.c_strlen(varname), value, libssh2.c_strlen(value))
end

--[[
url: https://www.libssh2.org/libssh2_channel_window_write_ex.html
name: libssh2_channel_window_write_ex - Check the status of the write window
description: Check the status of the write window Returns the number of bytes which may be safely written on the channel without blocking. 'window_size_initial' (if passed) will be populated with the size of the initial window as defined by the channel_open request
RETURN VALUE
Number of bytes which may be safely written on the channel without blocking.
ERRORS
SEE ALSO
libssh2_channel_window_read_ex, libssh2_channel_receive_window_adjust,
This HTML page was made with roffit.
]]

function _M:window_write_ex(window_size_initial)
	return prototype.libssh2_channel_window_write_ex(self.channel, window_size_initial)
end

--[[
url: https://www.libssh2.org/libssh2_channel_exec.html
name: libssh2_channel_exec - convenience macro for libssh2_channel_process_startup calls
description: This is a macro defined in a public libssh2 header file that is using the underlying function libssh2_channel_process_startup.
RETURN VALUE
See libssh2_channel_process_startup
ERRORS
See libssh2_channel_process_startup
SEE ALSO
libssh2_channel_process_startup,
This HTML page was made with roffit.
]]

function _M:exec(command)
	return prototype.libssh2_channel_process_startup(self.channel, libssh2.c_string("exec"), libssh2.c_strlen("exec"), command, libssh2.c_strlen(command))
end

--[[
url: https://www.libssh2.org/libssh2_channel_open_session.html
name: libssh2_channel_open_session - convenience macro for libssh2_channel_open_ex calls
description: This is a macro defined in a public libssh2 header file that is using the underlying function libssh2_channel_open_ex.
RETURN VALUE
See libssh2_channel_open_ex
ERRORS
See libssh2_channel_open_ex
SEE ALSO
libssh2_channel_open_ex,
This HTML page was made with roffit.
]]

function _M.open_session(session)
	return _M.open_ex(session, libssh2.c_string("session"), libssh2.c_strlen("session"), ffi.C.LIBSSH2_CHANNEL_WINDOW_DEFAULT, ffi.C.LIBSSH2_CHANNEL_PACKET_DEFAULT, nil, 0)
end

--[[
url: https://www.libssh2.org/libssh2_channel_get_exit_signal.html
name: libssh2_channel_get_exit_signal - get the remote exit signal
description: channel - Closed channel stream to retrieve exit signal from.
exitsignal - If not NULL, is populated by reference with the exit signal (without leading "SIG"). Note that the string is stored in a newly allocated buffer. If the remote program exited cleanly, the referenced string pointer will be set to NULL.
exitsignal_len - If not NULL, is populated by reference with the length of exitsignal.
errmsg - If not NULL, is populated by reference with the error message (if provided by remote server, if not it will be set to NULL). Note that the string is stored in a newly allocated buffer.
errmsg_len - If not NULL, is populated by reference with the length of errmsg.
langtag - If not NULL, is populated by reference with the language tag  (if provided by remote server, if not it will be set to NULL). Note that the string is stored in a newly allocated buffer.
langtag_len - If not NULL, is populated by reference with the length of langtag.
RETURN VALUE
Numeric error code corresponding to the the Error Code constants.
This HTML page was made with roffit.
]]

function _M:get_exit_signal(exitsignal, exitsignal_len, errmsg, errmsg_len, langtag, langtag_len)
	return prototype.libssh2_channel_get_exit_signal(self.channel, exitsignal, exitsignal_len, errmsg, errmsg_len, langtag, langtag_len)
end

--[[
url: https://www.libssh2.org/libssh2_channel_write_ex.html
name: libssh2_channel_write_ex - write data to a channel stream blocking
description: Write data to a channel stream. All channel streams have one standard I/O substream (stream_id == 0), and may have up to 2^32 extended data streams as identified by the selected stream_id. The SSH2 protocol currently defines a stream ID of 1 to be the stderr substream.
channel - active channel stream to write to.
stream_id - substream ID number (e.g. 0 or SSH_EXTENDED_DATA_STDERR)
buf - pointer to buffer to write
buflen - size of the data to write
libssh2_channel_write and libssh2_channel_write_stderr are convenience macros for this function.
libssh2_channel_write_ex will use as much as possible of the buffer and put it into a single SSH protocol packet. This means that to get maximum performance when sending larger files, you should try to always pass in at least 32K of data to this function.
RETURN VALUE
Actual number of bytes written or negative on failure. LIBSSH2_ERROR_EAGAIN when it would otherwise block. While LIBSSH2_ERROR_EAGAIN is a negative number, it isn't really a failure per se.
ERRORS
LIBSSH2_ERROR_ALLOC - An internal memory allocation call failed.
LIBSSH2_ERROR_SOCKET_SEND - Unable to send data on socket.
LIBSSH2_ERROR_CHANNEL_CLOSED - The channel has been closed.
LIBSSH2_ERROR_CHANNEL_EOF_SENT - The channel has been requested to be closed.
SEE ALSO
libssh2_channel_open_ex, libssh2_channel_read_ex,
This HTML page was made with roffit.
]]

function _M:write_ex(stream_id, buf, buflen)
	return prototype.libssh2_channel_write_ex(self.channel, stream_id, buf, buflen)
end

 --[[
url: https://www.libssh2.org/libssh2_channel_wait_eof.html
name: libssh2_channel_wait_eof - wait for the remote to reply to an EOF request
description: Wait for the remote end to send EOF.
RETURN VALUE
Return 0 on success or negative on failure. It returns LIBSSH2_ERROR_EAGAIN when it would otherwise block. While LIBSSH2_ERROR_EAGAIN is a negative number, it isn't really a failure per se.
SEE ALSO
libssh2_channel_send_eof, libssh2_channel_eof
This HTML page was made with roffit.
]]

function _M:wait_eof()
	return prototype.libssh2_channel_wait_eof(self.channel)
end

--[[
url: https://www.libssh2.org/libssh2_channel_request_pty.html
name: libssh2_channel_request_pty - convenience macro for libssh2_channel_request_pty_ex calls
description: This is a macro defined in a public libssh2 header file that is using the underlying function libssh2_channel_request_pty_ex.
RETURN VALUE
See libssh2_channel_request_pty_ex
ERRORS
See libssh2_channel_request_pty_ex
SEE ALSO
libssh2_channel_request_pty_ex,
This HTML page was made with roffit.
]]

function _M:request_pty(term)
	return self:request_pty_ex(ffi.cast("char*", term), ffi.C.strlen(ffi.cast("char*", term)), nil, 0, ffi.C.LIBSSH2_TERM_WIDTH, ffi.C.LIBSSH2_TERM_HEIGHT, ffi.C.LIBSSH2_TERM_WIDTH_PX, ffi.C.LIBSSH2_TERM_HEIGHT_PX)
end

--[[
url: https://www.libssh2.org/libssh2_channel_get_exit_status.html
name: libssh2_channel_get_exit_status - get the remote exit code
description: channel - Closed channel stream to retrieve exit status from.
Returns the exit code raised by the process running on the remote host at  the other end of the named channel. Note that the exit status may not be  available if the remote end has not yet set its status to closed.
RETURN VALUE
Returns 0 on failure, otherwise the Exit Status reported by remote host
This HTML page was made with roffit.
]]

function _M:get_exit_status()
	return prototype.libssh2_channel_get_exit_status(self.channel)
end

--[[
url: https://www.libssh2.org/libssh2_channel_direct_tcpip_ex.html
name: libssh2_channel_direct_tcpip_ex - Tunnel a TCP connection through an SSH session
description: session - Session instance as returned by  libssh2_session_init_ex,
host - Third party host to connect to using the SSH host as a proxy.
port - Port on third party host to connect to.
shost - Host to tell the SSH server the connection originated on.
sport - Port to tell the SSH server the connection originated from.
Tunnel a TCP/IP connection through the SSH transport via the remote host to  a third party. Communication from the client to the SSH server remains  encrypted, communication from the server to the 3rd party host travels  in cleartext.
RETURN VALUE
Pointer to a newly allocated LIBSSH2_CHANNEL instance, or NULL on errors.
ERRORS
LIBSSH2_ERROR_ALLOC -  An internal memory allocation call failed.
SEE ALSO
libssh2_session_init_ex,
This HTML page was made with roffit.
]]

function _M:direct_tcpip_ex(session, host, port, shost, sport)
	local self = {}

	self.channel = prototype.libssh2_channel_direct_tcpip_ex(session, host, port, shost, sport)
	ffi.gc(self.channel, prototype.libssh2_channel_free)

	return setmetatable(self, _M)
end

--[[
url: https://www.libssh2.org/libssh2_channel_forward_listen.html
name: libssh2_channel_forward_listen - convenience macro for libssh2_channel_forward_listen_ex calls
description: This is a macro defined in a public libssh2 header file that is using the underlying function libssh2_channel_forward_listen_ex.
RETURN VALUE
See libssh2_channel_forward_listen_ex
ERRORS
See libssh2_channel_forward_listen_ex
SEE ALSO
libssh2_channel_forward_listen_ex,
This HTML page was made with roffit.
]]

function _M:forward_listen(session, port)
	return prototype.libssh2_channel_forward_listen_ex(session, nil, port, nil, 16)
end

--[[
url: https://www.libssh2.org/libssh2_channel_flush_ex.html
name: libssh2_channel_flush_ex - flush a channel
description: channel - Active channel stream to flush.
streamid - Specific substream number to flush. Groups of substreams may  be flushed by passing on of the following Constants. LIBSSH2_CHANNEL_FLUSH_EXTENDED_DATA: Flush all extended data substreams LIBSSH2_CHANNEL_FLUSH_ALL: Flush all substreams
Flush the read buffer for a given channel instance. Individual substreams may  be flushed by number or using one of the provided macros.
RETURN VALUE
Return 0 on success or negative on failure.  It returns LIBSSH2_ERROR_EAGAIN when it would otherwise block. While LIBSSH2_ERROR_EAGAIN is a negative number, it isn't really a failure per se.
This HTML page was made with roffit.
]]

function _M:flush_ex(streamid)
	return prototype.libssh2_channel_flush_ex(self.channel, streamid)
end

--[[
url: https://www.libssh2.org/libssh2_channel_request_pty_size.html
name: libssh2_channel_request_pty_size - convenience macro for libssh2_channel_request_pty_size_ex calls
description: This is a macro defined in a public libssh2 header file that is using the underlying function libssh2_channel_request_pty_size_ex.
RETURN VALUE
See libssh2_channel_request_pty_size_ex
ERRORS
See libssh2_channel_request_pty_size_ex
SEE ALSO
libssh2_channel_request_pty_size_ex,
This HTML page was made with roffit.
]]

function _M:request_pty_size(width, height)
	return prototype.libssh2_channel_request_pty_size_ex(self.channel, width, height, 0, 0)
end

--[[
url: https://www.libssh2.org/libssh2_channel_wait_closed.html
name: libssh2_channel_wait_closed - wait for the remote to close the channel
description: Enter a temporary blocking state until the remote host closes the named channel. Typically sent after libssh2_channel_close in order to examine the exit status.
RETURN VALUE
Return 0 on success or negative on failure. It returns LIBSSH2_ERROR_EAGAIN when it would otherwise block. While LIBSSH2_ERROR_EAGAIN is a negative number, it isn't really a failure per se.
SEE ALSO
libssh2_channel_send_eof, libssh2_channel_eof, libssh2_channel_wait_eof,
This HTML page was made with roffit.
]]

function _M:wait_closed()
	return prototype.libssh2_channel_wait_closed(self.channel)
end

--[[
url: https://www.libssh2.org/libssh2_channel_receive_window_adjust2.html
name: libssh2_channel_receive_window_adjust2 - adjust the channel window
description: Adjust the receive window for a channel by adjustment bytes. If the amount to be adjusted is less than LIBSSH2_CHANNEL_MINADJUST and force is 0 the adjustment amount will be queued for a later packet.
This function stores the new size of the receive window (as understood by remote end) in the variable 'window' points to.
RETURN VALUE
Return 0 on success and a negative value on error. If used in non-blocking mode it will return LIBSSH2_ERROR_EAGAIN when it would otherwise block.
ERRORS
AVAILABILITY
Added in libssh2 1.1 since the previous API has deficiencies.
SEE ALSO
libssh2_channel_window_read_ex,
This HTML page was made with roffit.
]]

function _M:receive_window_adjust2(adjustment, force, window)
	return prototype.libssh2_channel_receive_window_adjust2(self.channel, adjustment, force, window)
end

--[[
url: https://www.libssh2.org/libssh2_channel_write.html
name: libssh2_channel_write - convenience macro for libssh2_channel_write_ex
description: This is a macro defined in a public libssh2 header file that is using the underlying function libssh2_channel_write_ex.
RETURN VALUE
See libssh2_channel_write_ex
ERRORS
See libssh2_channel_write_ex
SEE ALSO
libssh2_channel_write_ex,
This HTML page was made with roffit.
]]

function _M:write(buf, buflen)
	return prototype.libssh2_channel_write_ex(self.channel, 0, buf, buflen)
end

 --[[
url: https://www.libssh2.org/libssh2_channel_free.html
name: libssh2_channel_free - free all resources associated with a channel
description: channel - Channel stream to free.
Release all resources associated with a channel stream. If the channel has  not yet been closed with  libssh2_channel_close, , it will be called automatically so that the remote end may know that it  can safely free its own resources.
RETURN VALUE
Return 0 on success or negative on failure.  It returns LIBSSH2_ERROR_EAGAIN when it would otherwise block. While LIBSSH2_ERROR_EAGAIN is a negative number, it isn't really a failure per se.
SEE ALSO
libssh2_channel_close,
This HTML page was made with roffit.
]]

--int libssh2_channel_free(LIBSSH2_CHANNEL *channel)

return _M