local ffi = require "ffi"
local prototype = require "libssh2.prototype"

ffi.cdef[[
	int libssh2_session_handshake(LIBSSH2_SESSION *session, libssh2_socket_t socket);
	int libssh2_banner_set(LIBSSH2_SESSION *session, const char *banner);
	void libssh2_session_set_timeout(LIBSSH2_SESSION *session, long timeout);

	typedef void (*LIBSSH2_ALLOC_FUNC)(size_t count, void **abstract);
	typedef void (*LIBSSH2_REALLOC_FUNC)(void *ptr, size_t count, void **abstract);
	typedef void (*LIBSSH2_FREE_FUNC)(void *ptr, void **abstract);
	LIBSSH2_SESSION * libssh2_session_init_ex(LIBSSH2_ALLOC_FUNC myalloc, LIBSSH2_FREE_FUNC myfree, LIBSSH2_REALLOC_FUNC myrealloc, void *abstract);

	void **libssh2_session_abstract(LIBSSH2_SESSION *session);
	int libssh2_session_method_pref(LIBSSH2_SESSION *session, int method_type, const char *prefs);
	int libssh2_session_get_blocking(LIBSSH2_SESSION *session);
	int libssh2_session_last_errno(LIBSSH2_SESSION *session);
	int libssh2_session_set_last_error(LIBSSH2_SESSION *session, int errcode, const char *errmsg);
	int libssh2_session_block_directions(LIBSSH2_SESSION *session);
	void  libssh2_session_set_blocking(LIBSSH2_SESSION *session, int blocking);
	int  libssh2_session_startup(LIBSSH2_SESSION *session, int socket);
	const char *libssh2_session_banner_get(LIBSSH2_SESSION *session);
	int libssh2_session_disconnect_ex(LIBSSH2_SESSION *session, int reason, const char *description, const char *lang);

	typedef void (*LIBSSH2_CALLBACKSET_FUNC)();
	void *libssh2_session_callback_set(LIBSSH2_SESSION *session, int cbtype, LIBSSH2_CALLBACKSET_FUNC callback);

	int  libssh2_session_banner_set(LIBSSH2_SESSION *session, const char *banner);
	int libssh2_session_last_error(LIBSSH2_SESSION *session, char **errmsg, int *errmsg_len, int want_buf);
	LIBSSH2_SESSION * libssh2_session_init(void);
	int libssh2_session_flag(LIBSSH2_SESSION *session, int flag, int value);
	const char * libssh2_session_methods(LIBSSH2_SESSION *session, int method_type);
	int libssh2_session_supported_algs(LIBSSH2_SESSION* session, int method_type, const char*** algs);
	long libssh2_session_get_timeout(LIBSSH2_SESSION *session);
	int libssh2_session_free(LIBSSH2_SESSION *session);
	const char *libssh2_session_hostkey(LIBSSH2_SESSION *session, size_t *len, int *type);
]]

local _M = {}
_M.__index = _M


--[[
url: https://www.libssh2.org/libssh2_session_handshake.html
name: libssh2_session_handshake - perform the SSH handshake
description: session - Session instance as returned by libssh2_session_init_ex,
socket - Connected socket descriptor. Typically a TCP connection though the protocol allows for any reliable transport and the library will attempt to use any berkeley socket.
Begin transport layer protocol negotiation with the connected host.
RETURN VALUE
Returns 0 on success, negative on failure.
ERRORS
LIBSSH2_ERROR_SOCKET_NONE - The socket is invalid.
LIBSSH2_ERROR_BANNER_SEND - Unable to send banner to remote host.
LIBSSH2_ERROR_KEX_FAILURE - >Encryption key exchange with the remote host failed.
LIBSSH2_ERROR_SOCKET_SEND - Unable to send data on socket.
LIBSSH2_ERROR_SOCKET_DISCONNECT - The socket was disconnected.
LIBSSH2_ERROR_PROTO - An invalid SSH protocol response was received on the socket.
LIBSSH2_ERROR_EAGAIN - Marked for non-blocking I/O but the call would block.
AVAILABILITY
Added in 1.2.8
SEE ALSO
libssh2_session_free, libssh2_session_init_ex,
This HTML page was made with roffit.
]]

function _M:handshake(socket)
	return prototype.libssh2_session_handshake(self.session, socket)
end

--[[
url: https://www.libssh2.org/libssh2_banner_set.html
name: libssh2_banner_set - set the SSH protocol banner for the local client
description: This function is DEPRECATED. Use libssh2_session_banner_set instead!
session - Session instance as returned by  libssh2_session_init_ex,
banner - A pointer to a user defined banner
Set the banner that will be sent to the remote host when the SSH session is  started with  libssh2_session_handshake,   This is optional; a banner corresponding to the protocol and libssh2 version will be sent by default.
RETURN VALUE
Return 0 on success or negative on failure.  It returns LIBSSH2_ERROR_EAGAIN when it would otherwise block. While LIBSSH2_ERROR_EAGAIN is a negative number, it isn't really a failure per se.
AVAILABILITY
Marked as deprecated since 1.4.0
ERRORS
LIBSSH2_ERROR_ALLOC -  An internal memory allocation call failed.
SEE ALSO
libssh2_session_handshake,
This HTML page was made with roffit.
]]

function _M:banner_set(banner)
	return prototype.libssh2_banner_set(self.session, banner)
end

--[[
url: https://www.libssh2.org/libssh2_session_set_timeout.html
name: libssh2_session_set_timeout - set timeout for blocking functions
description: Set the timeout in milliseconds for how long a blocking the libssh2 function calls may wait until they consider the situation an error and return LIBSSH2_ERROR_TIMEOUT.
By default or if you set the timeout to zero, libssh2 has no timeout for blocking functions.
RETURN VALUE
Nothing
AVAILABILITY
Added in 1.2.9
SEE ALSO
libssh2_session_get_timeout,
This HTML page was made with roffit.
]]

function _M:set_timeout(timeout)
	prototype.libssh2_session_set_timeout(self.session, timeout)
end


--[[
url: https://www.libssh2.org/libssh2_session_init_ex.html
name: libssh2_session_init_ex - initializes an SSH session object
description: myalloc - Custom allocator function. Refer to the section on Callbacks  for implementing an allocator callback. Pass a value of NULL to use the  default system allocator.
myfree - Custom de-allocator function. Refer to the section on Callbacks  for implementing a deallocator callback. Pass a value of NULL to use the  default system deallocator.
myrealloc - Custom re-allocator function. Refer to the section on  Callbacks for implementing a reallocator callback. Pass a value of NULL to  use the default system reallocator.
abstract - Arbitrary pointer to application specific callback data.  This value will be passed to any callback function associated with the named  session instance.
Initializes an SSH session object. By default system memory allocators (malloc(), free(), realloc()) will be used for any dynamically allocated memory blocks. Alternate memory allocation functions may be specified using the extended version of this API call, and/or optional application specific data may be attached to the session object.
This method must be called first, prior to configuring session options or starting up an SSH session with a remote server.
RETURN VALUE
Pointer to a newly allocated LIBSSH2_SESSION instance, or NULL on errors.
SEE ALSO
libssh2_session_free, libssh2_session_handshake,
This HTML page was made with roffit.
]]

function _M.init_ex(myalloc, myfree, myrealloc, abstract)
	local self = {}

	self.session = prototype.libssh2_session_init_ex(myalloc, myfree, myrealloc, abstract)
	ffi.gc(self.session, prototype.libssh2_session_free)

	return setmetatable(self, _M)
end

--[[
url: https://www.libssh2.org/libssh2_session_abstract.html
name: libssh2_session_abstract - return a pointer to a session's abstract pointer
description: session - Session instance as returned by  libssh2_session_init_ex,
Return a pointer to where the abstract pointer provided to libssh2_session_init_ex is stored. By providing a doubly de-referenced pointer, the internal storage of the session instance may be modified in place.
RETURN VALUE
A pointer to session internal storage who's contents point to previously provided abstract data.
SEE ALSO
libssh2_session_init_ex,
This HTML page was made with roffit.
]]

function _M:abstract()
	return prototype.libssh2_session_abstract(self.session)
end

--[[
url: https://www.libssh2.org/libssh2_session_disconnect.html
name: libssh2_session_disconnect - convenience macro for libssh2_session_disconnect_ex calls
description: This is a macro defined in a public libssh2 header file that is using the underlying function libssh2_session_disconnect_ex.
RETURN VALUE
See libssh2_session_disconnect_ex
ERRORS
See libssh2_session_disconnect_ex
SEE ALSO
libssh2_session_disconnect_ex,
This HTML page was made with roffit.
]]

function _M:disconnect(description)
	return self:disconnect_ex(ffi.C.SSH_DISCONNECT_BY_APPLICATION, describing, "")
end

--[[
url: https://www.libssh2.org/libssh2_session_method_pref.html
name: libssh2_session_method_pref - set preferred key exchange method
description: session - Session instance as returned by  libssh2_session_init_ex,
method_type - One of the Method Type constants.
prefs - Coma delimited list of preferred methods to use with  the most preferred listed first and the least preferred listed last.  If a method is listed which is not supported by libssh2 it will be  ignored and not sent to the remote host during protocol negotiation.
Set preferred methods to be negotiated. These  preferences must be set prior to calling libssh2_session_handshake, as they are used during the protocol initiation phase.
RETURN VALUE
Return 0 on success or negative on failure.  It returns LIBSSH2_ERROR_EAGAIN when it would otherwise block. While LIBSSH2_ERROR_EAGAIN is a negative number, it isn't really a failure per se.
ERRORS
LIBSSH2_ERROR_INVAL - The requested method type was invalid.
LIBSSH2_ERROR_ALLOC -  An internal memory allocation call failed.
LIBSSH2_ERROR_METHOD_NOT_SUPPORTED - The requested method is not supported.
SEE ALSO
libssh2_session_init_ex, libssh2_session_handshake,
This HTML page was made with roffit.
]]

function _M:method_pref(method_type, prefs)
	return prototype.libssh2_session_method_pref(self.session, method_type, prefs)
end

--[[
url: https://www.libssh2.org/libssh2_session_get_blocking.html
name: libssh2_session_get_blocking - TODO
description: Returns 0 if the state of the session has previously be set to non-blocking and it returns 1 if the state was set to blocking.
RETURN VALUE
See description.
SEE ALSO
libssh2_session_set_blocking,
This HTML page was made with roffit.
]]

function _M:get_blocking()
	return prototype.libssh2_session_get_blocking(self.session)
end


--[[
url: https://www.libssh2.org/libssh2_session_last_errno.html
name: libssh2_session_last_errno - get the most recent error number
description: session - Session instance as returned by  libssh2_session_init_ex
Determine the most recent error condition.
RETURN VALUE
Numeric error code corresponding to the the Error Code constants.
SEE ALSO
libssh2_session_last_error, libssh2_session_set_last_error
This HTML page was made with roffit.
]]

function _M:last_errno()
	return prototype.libssh2_session_last_errno(self.session)
end

--[[
url: https://www.libssh2.org/libssh2_session_set_last_error.html
name: libssh2_session_set_last_error - sets the internal error state
description: session - Session instance as returned by libssh2_session_init_ex
errcode - One of the error codes as defined in the public libssh2 header file.
errmsg - If not NULL, a copy of the given string is stored inside the session object as the error message.
This function is provided for high level language wrappers (i.e. Python or Perl) and other libraries that may extend libssh2 with additional features while still relying on its error reporting mechanism.
RETURN VALUE
Numeric error code corresponding to the the Error Code constants.
AVAILABILITY
Added in 1.6.1
SEE ALSO
libssh2_session_last_error, libssh2_session_last_errno
This HTML page was made with roffit.
]]

function _M:set_last_error(errcode, errmsg)
	return prototype.libssh2_session_set_last_error(self.session, errcode, errmsg)
end

--[[
url: https://www.libssh2.org/libssh2_session_block_directions.html
name: libssh2_session_block_directions - get directions to wait for
description: session - Session instance as returned by libssh2_session_init_ex
When any of libssh2 functions return LIBSSH2_ERROR_EAGAIN an application should wait for the socket to have data available for reading or writing. Depending on the return value of libssh2_session_block_directions an application should wait for read, write or both.
RETURN VALUE
Returns the set of directions as a binary mask. Can be a combination of:
LIBSSH2_SESSION_BLOCK_INBOUND: Inbound direction blocked.
LIBSSH2_SESSION_BLOCK_OUTBOUND: Outbound direction blocked.
Application should wait for data to be available for socket prior to calling a libssh2 function again. If LIBSSH2_SESSION_BLOCK_INBOUND is set select should contain the session socket in readfds set.  Correspondingly in case of LIBSSH2_SESSION_BLOCK_OUTBOUND writefds set should contain the socket.
AVAILABILITY
Added in 1.0
This HTML page was made with roffit.
]]

function _M:block_directions()
	return prototype.libssh2_session_block_directions(self.session)
end

--[[
url: https://www.libssh2.org/libssh2_session_set_blocking.html
name: libssh2_session_set_blocking - set or clear blocking mode on session
description: session - session instance as returned by  libssh2_session_init_ex,
blocking - Set to a non-zero value to make the channel block, or zero to make it non-blocking.
Set or clear blocking mode on the selected on the session.  This will instantly affect any channels associated with this session. If a read is performed on a session with no data currently available, a blocking session will wait for data to arrive and return what it receives.  A non-blocking session will return immediately with an empty buffer.  If a write is performed on a session with no room for more data, a blocking session will wait for room.  A non-blocking session will return immediately without writing anything.
RETURN VALUE
None
SEE ALSO
libssh2_session_init_ex,
This HTML page was made with roffit.
]]

function _M:set_blocking(blocking)
	return prototype.libssh2_session_set_blocking(self.session, blocking)
end


--[[
url: https://www.libssh2.org/libssh2_session_startup.html
name: libssh2_session_startup - begin transport layer
description: Starting in libssh2 version 1.2.8 this function is considered deprecated. Use libssh2_session_handshake instead.
session - Session instance as returned by  libssh2_session_init_ex,
socket - Connected socket descriptor. Typically a TCP connection  though the protocol allows for any reliable transport and the library will  attempt to use any berkeley socket.
Begin transport layer protocol negotiation with the connected host.
RETURN VALUE
Returns 0 on success, negative on failure.
ERRORS
LIBSSH2_ERROR_SOCKET_NONE - The socket is invalid.
LIBSSH2_ERROR_BANNER_SEND - Unable to send banner to remote host.
LIBSSH2_ERROR_KEX_FAILURE - >Encryption key exchange with the remote  host failed.
LIBSSH2_ERROR_SOCKET_SEND - Unable to send data on socket.
LIBSSH2_ERROR_SOCKET_DISCONNECT - The socket was disconnected.
LIBSSH2_ERROR_PROTO - An invalid SSH protocol response was received on  the socket.
LIBSSH2_ERROR_EAGAIN - Marked for non-blocking I/O but the call would block.
SEE ALSO
libssh2_session_free, libssh2_session_init_ex,
This HTML page was made with roffit.
]]

function _M:startup(socket)
	return prototype.libssh2_session_startup(self.session, socket)
end

--[[
url: https://www.libssh2.org/libssh2_session_banner_get.html
name: libssh2_session_banner_get - get the remote banner
description: Once the session has been setup and libssh2_session_handshake has completed successfully, this function can be used to get the server id from the banner each server presents.
RETURN VALUE
A pointer to a string or NULL if something failed. The data pointed to will be allocated and associated to the session handle and will be freed by libssh2 when libssh2_session_free is used.
AVAILABILITY
Added in 1.4.0
SEE ALSO
libssh2_session_banner_set, libssh2_session_handshake, libssh2_session_free,
This HTML page was made with roffit.
]]

function _M:banner_get()
	return prototype.libssh2_session_banner_get(self.session)
end


--[[
url: https://www.libssh2.org/libssh2_session_disconnect_ex.html
name: libssh2_session_disconnect_ex - terminate transport layer
description: session - Session instance as returned by  libssh2_session_init_ex,
reason - One of the Disconnect Reason constants.
description - Human readable reason for disconnection.
lang - Localization string describing the language/encoding of the description provided.
Send a disconnect message to the remote host associated with session,  along with a reason symbol and a verbose description.
As a convenience, the macro  libssh2_session_disconnect, is provided. It calls libssh2_session_disconnect_ex, with reason set to SSH_DISCONNECT_BY_APPLICATION  and lang set to an empty string.
RETURN VALUE
Return 0 on success or negative on failure.  It returns LIBSSH2_ERROR_EAGAIN when it would otherwise block. While LIBSSH2_ERROR_EAGAIN is a negative number, it isn't really a failure per se.
SEE ALSO
libssh2_session_init_ex,
This HTML page was made with roffit.
]]

function _M:disconnect_ex(reason, description, lang)
	return prototype.libssh2_session_disconnect_ex(self.session, reason, description, lang)
end

--[[
url: https://www.libssh2.org/libssh2_session_callback_set.html
name: libssh2_session_callback_set - set a callback function
description: Sets a custom callback handler for a previously initialized session object. Callbacks are triggered by the receipt of special packets at the Transport layer. To disable a callback, set it to NULL.
session - Session instance as returned by  libssh2_session_init_ex,
cbtype - Callback type. One of the types listed in Callback Types.
callback - Pointer to custom callback function. The prototype for  this function must match the associated callback declaration macro.
CALLBACK TYPES
LIBSSH2_CALLBACK_IGNORE
Called when a SSH_MSG_IGNORE message is received
LIBSSH2_CALLBACK_DEBUG
Called when a SSH_MSG_DEBUG message is received
LIBSSH2_CALLBACK_DISCONNECT
Called when a SSH_MSG_DISCONNECT message is received
LIBSSH2_CALLBACK_MACERROR
Called when a mismatched MAC has been detected in the transport layer. If the function returns 0, the packet will be accepted nonetheless.
LIBSSH2_CALLBACK_X11
Called when an X11 connection has been accepted
LIBSSH2_CALLBACK_SEND
Called when libssh2 wants to send some data on the connection. Can be set to a custom function to handle I/O your own way.
LIBSSH2_CALLBACK_RECV
Called when libssh2 wants to receive some data from the connection. Can be set to a custom function to handle I/O your own way.
RETURN VALUE
Pointer to previous callback handler. Returns NULL if no prior callback handler was set or the callback type was unknown.
SEE ALSO
libssh2_session_init_ex,
This HTML page was made with roffit.
]]

function _M:callback_set(cbtype, callback)
	return prototype.libssh2_session_callback_set(self.session, cbtype, callback)
end

 --[[
url: https://www.libssh2.org/libssh2_session_banner_set.html
name: libssh2_session_banner_set - set the SSH protocol banner for the local client
description: session - Session instance as returned by  libssh2_session_init_ex,
banner - A pointer to a zero-terminated string holding the user defined banner
Set the banner that will be sent to the remote host when the SSH session is started with libssh2_session_handshake This is optional; a banner corresponding to the protocol and libssh2 version will be sent by default.
RETURN VALUE
Returns 0 on success or negative on failure.  It returns LIBSSH2_ERROR_EAGAIN when it would otherwise block. While LIBSSH2_ERROR_EAGAIN is a negative number, it isn't really a failure per se.
ERRORS
LIBSSH2_ERROR_ALLOC -  An internal memory allocation call failed.
AVAILABILITY
Added in 1.4.0.
Before 1.4.0 this function was known as libssh2_banner_set(3)
SEE ALSO
libssh2_session_handshake, libssh2_session_banner_get,
This HTML page was made with roffit.
]]

function _M:banner_set(banner)
	return prototype.libssh2_session_banner_set(self.session, banner)
end

--[[
url: https://www.libssh2.org/libssh2_session_last_error.html
name: libssh2_session_last_error - get the most recent error
description: session - Session instance as returned by  libssh2_session_init_ex
errmsg - If not NULL, is populated by reference with the human  readable form of the most recent error message.
errmsg_len - If not NULL, is populated by reference with the length  of errmsg. (The string is NUL-terminated, so the length is only useful as  an optimization, to avoid calling strlen.)
want_buf - If set to a non-zero value, "ownership" of the errmsg  buffer will be given to the calling scope. If necessary, the errmsg buffer  will be duplicated.
Determine the most recent error condition and its cause.
RETURN VALUE
Numeric error code corresponding to the the Error Code constants.
SEE ALSO
libssh2_session_last_errno, libssh2_session_set_last_error
This HTML page was made with roffit.
]]

function _M:last_error(errmsg, errmsg_len, want_buf)
	return prototype.libssh2_session_last_error(self.session, errmsg, errmsg_len, want_buf)
end

--[[
url: https://www.libssh2.org/libssh2_session_init.html
name: libssh2_session_init - convenience macro for libssh2_session_init_ex calls
description: This is a macro defined in a public libssh2 header file that is using the underlying function libssh2_session_init_ex.
RETURN VALUE
See libssh2_session_init_ex
ERRORS
See libssh2_session_init_ex
SEE ALSO
libssh2_session_init_ex,
This HTML page was made with roffit.
]]

function _M.init()
	local self = {}

	self.session = prototype.libssh2_session_init_ex(nil, nil, nil, nil)
	ffi.gc(self.session, prototype.libssh2_session_free)

	return setmetatable(self, _M)
end

--[[
url: https://www.libssh2.org/libssh2_session_flag.html
name: libssh2_session_flag - TODO
description: Set options for the created session. flag is the option to set, while value is typically set to 1 or 0 to enable or disable the option.
FLAGS
LIBSSH2_FLAG_SIGPIPE
If set, libssh2 will not attempt to block SIGPIPEs but will let them trigger from the underlying socket layer.
LIBSSH2_FLAG_COMPRESS
If set - before the connection negotiation is performed - libssh2 will try to negotiate compression enabling for this connection. By default libssh2 will not attempt to use compression.
RETURN VALUE
Returns regular libssh2 error code.
AVAILABILITY
This function has existed since the age of dawn. LIBSSH2_FLAG_COMPRESS was added in version 1.2.8.
SEE ALSO
This HTML page was made with roffit.
]]

function _M:flag(flag, value)
	return prototype.libssh2_session_flag(self.session, flag, value)
end

--[[
url: https://www.libssh2.org/libssh2_session_methods.html
name: libssh2_session_methods - return the currently active algorithms
description: session - Session instance as returned by  libssh2_session_init_ex,
method_type - one of the method type constants: LIBSSH2_METHOD_KEX, LIBSSH2_METHOD_HOSTKEY, LIBSSH2_METHOD_CRYPT_CS, LIBSSH2_METHOD_CRYPT_SC, LIBSSH2_METHOD_MAC_CS, LIBSSH2_METHOD_MAC_SC, LIBSSH2_METHOD_COMP_CS, LIBSSH2_METHOD_COMP_SC, LIBSSH2_METHOD_LANG_CS, LIBSSH2_METHOD_LANG_SC.
Returns the actual method negotiated for a particular transport parameter.
RETURN VALUE
Negotiated method or NULL if the session has not yet been started.
ERRORS
LIBSSH2_ERROR_INVAL - The requested method type was invalid.
LIBSSH2_ERROR_METHOD_NONE - no method has been set
SEE ALSO
libssh2_session_init_ex,
This HTML page was made with roffit.
]]

function _M:methods(method_type)
	return prototype.libssh2_session_methods(self.session, method_type)
end

--[[
url: https://www.libssh2.org/libssh2_session_supported_algs.html
name: libssh2_session_supported_algs - get list of supported algorithms
description: session - An instance of initialized LIBSSH2_SESSION (the function will use its pointer to the memory allocation function).  method_type - Method type. See .BR libssh2_session_method_pref.  algs - Address of a pointer that will point to an array of returned algorithms
Get a list of supported algorithms for the given method_type. The method_type parameter is equivalent to method_type in libssh2_session_method_pref. If successful, the function will allocate the appropriate amount of memory. When not needed anymore, it must be deallocated by calling libssh2_free. When this function is unsuccessful, this must not be done.
In order to get a list of all supported compression algorithms, libssh2_session_flag(session, LIBSSH2_FLAG_COMPRESS, 1) must be called before calling this function, otherwise only "none" will be returned.
If successful, the function will allocate and fill the array with supported algorithms (the same names as defined in RFC 4253).  The array is not NULL terminated.
EXAMPLE
#include "libssh2.h"
 const char **algorithms;
 int rc, i;
 LIBSSH2_SESSION *session;
 /* initialize session */
 session = libssh2_session_init();
 rc = libssh2_session_supported_algs(session,
                                     LIBSSH2_METHOD_CRYPT_CS,
                                     &algorithms);
 if (rc>0) {
     /* the call succeeded, do sth. with the list of algorithms
        (e.g. list them)... */
     printf("Supported symmetric algorithms:n");
     for ( i=0; i<rc; i++ )
         printf("t%sn", algorithms[i]);
     /* ... and free the allocated memory when not needed anymore */
     libssh2_free(session, algorithms);
 }
 else {
     /* call failed, error handling */
 }
RETURN VALUE
On success, a number of returned algorithms (i.e a positive number will be returned).  In case of a failure, an error code (a negative number, see below) is returned.  0 should never be returned.
ERRORS
LIBSSH2_ERROR_BAD_USE - Invalid address of algs.
LIBSSH2_ERROR_METHOD_NOT_SUPPORTED -  Unknown method type.
LIBSSH2_ERROR_INVAL - Internal error (normally should not occur).
LIBSSH2_ERROR_ALLOC - Allocation of memory failed.
AVAILABILITY
Added in 1.4.0
SEE ALSO
libssh2_session_methods, libssh2_session_method_pref, libssh2_free,
This HTML page was made with roffit.
]]

function _M:supported_algs(method_type, algs)
	return prototype.libssh2_session_supported_algs(self.session, method_type, algs)
end

 --[[
url: https://www.libssh2.org/libssh2_session_get_timeout.html
name: libssh2_session_get_timeout - get the timeout for blocking functions
description: Returns the timeout (in milliseconds) for how long a blocking the libssh2 function calls may wait until they consider the situation an error and return LIBSSH2_ERROR_TIMEOUT.
By default libssh2 has no timeout (zero) for blocking functions.
RETURN VALUE
The value of the timeout setting.
AVAILABILITY
Added in 1.2.9
SEE ALSO
libssh2_session_set_timeout,
This HTML page was made with roffit.
]]

function _M:timeout()
	return prototype.libssh2_session_get_timeout(self.session)
end

--[[
url: https://www.libssh2.org/libssh2_session_free.html
name: libssh2_session_free - frees resources associated with a session instance
description: Frees all resources associated with a session instance. Typically called after libssh2_session_disconnect_ex,
RETURN VALUE
Return 0 on success or negative on failure.  It returns LIBSSH2_ERROR_EAGAIN when it would otherwise block. While LIBSSH2_ERROR_EAGAIN is a negative number, it isn't really a failure per se.
SEE ALSO
libssh2_session_init_ex, libssh2_session_disconnect_ex,
This HTML page was made with roffit.
]]

--int  libssh2_session_free(LIBSSH2_SESSION *session);


--[[
url: https://www.libssh2.org/libssh2_session_hostkey.html
name: libssh2_session_hostkey - get the remote key
description: Returns a pointer to the current host key, the value len points to will get the length of the key.
The value type points to the type of hostkey which is one of: LIBSSH2_HOSTKEY_TYPE_RSA, LIBSSH2_HOSTKEY_TYPE_DSS, or LIBSSH2_HOSTKEY_TYPE_UNKNOWN.
RETURN VALUE
A pointer, or NULL if something went wrong.
SEE ALSO
libssh2_knownhost_check, libssh2_knownhost_add,
This HTML page was made with roffit.
]]

function _M:hostkey(len, type)
	return prototype.libssh2_session_hostkey(self.session, len, type)
end


return _M