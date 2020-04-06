local ffi = require "ffi"
local prototype = require "libssh2.prototype"

ffi.cdef[[

typedef enum {

LIBSSH2_TERM_WIDTH      = 80,
LIBSSH2_TERM_HEIGHT     = 24,
LIBSSH2_TERM_WIDTH_PX   = 0,
LIBSSH2_TERM_HEIGHT_PX  = 0,

LIBSSH2_POLLFD_SOCKET       = 1,
LIBSSH2_POLLFD_CHANNEL      = 2,
LIBSSH2_POLLFD_LISTENER     = 3,

LIBSSH2_POLLFD_POLLIN           = 0x0001, /* Data available to be read or
                                                  connection available --
                                                  All */
LIBSSH2_POLLFD_POLLPRI          = 0x0002, /* Priority data available to
                                                  be read -- Socket only */
LIBSSH2_POLLFD_POLLEXT          = 0x0002, /* Extended data available to
                                                  be read -- Channel only */
LIBSSH2_POLLFD_POLLOUT          = 0x0004, /* Can may be written --
                                                  Socket/Channel */
/* revents only */
LIBSSH2_POLLFD_POLLERR          = 0x0008, /* Error Condition -- Socket */
LIBSSH2_POLLFD_POLLHUP          = 0x0010, /* HangUp/EOF -- Socket */
LIBSSH2_POLLFD_SESSION_CLOSED   = 0x0010, /* Session Disconnect */
LIBSSH2_POLLFD_POLLNVAL         = 0x0020, /* Invalid request -- Socket
                                                  Only */
LIBSSH2_POLLFD_POLLEX           = 0x0040, /* Exception Condition --
                                                  Socket/Win32 */
LIBSSH2_POLLFD_CHANNEL_CLOSED   = 0x0080, /* Channel Disconnect */
LIBSSH2_POLLFD_LISTENER_CLOSED  = 0x0080, /* Listener Disconnect */


/* Block Direction Types */
LIBSSH2_SESSION_BLOCK_INBOUND                  = 0x0001,
LIBSSH2_SESSION_BLOCK_OUTBOUND                 = 0x0002,

/* Hash Types */
LIBSSH2_HOSTKEY_HASH_MD5                            = 1,
LIBSSH2_HOSTKEY_HASH_SHA1                           = 2,

/* Hostkey Types */
LIBSSH2_HOSTKEY_TYPE_UNKNOWN			= 0,
LIBSSH2_HOSTKEY_TYPE_RSA			    = 1,
LIBSSH2_HOSTKEY_TYPE_DSS			    = 2,

/* Disconnect Codes (defined by SSH protocol) */
SSH_DISCONNECT_HOST_NOT_ALLOWED_TO_CONNECT          = 1,
SSH_DISCONNECT_PROTOCOL_ERROR                       = 2,
SSH_DISCONNECT_KEY_EXCHANGE_FAILED                  = 3,
SSH_DISCONNECT_RESERVED                             = 4,
SSH_DISCONNECT_MAC_ERROR                            = 5,
SSH_DISCONNECT_COMPRESSION_ERROR                    = 6,
SSH_DISCONNECT_SERVICE_NOT_AVAILABLE                = 7,
SSH_DISCONNECT_PROTOCOL_VERSION_NOT_SUPPORTED       = 8,
SSH_DISCONNECT_HOST_KEY_NOT_VERIFIABLE              = 9,
SSH_DISCONNECT_CONNECTION_LOST                      = 10,
SSH_DISCONNECT_BY_APPLICATION                       = 11,
SSH_DISCONNECT_TOO_MANY_CONNECTIONS                 = 12,
SSH_DISCONNECT_AUTH_CANCELLED_BY_USER               = 13,
SSH_DISCONNECT_NO_MORE_AUTH_METHODS_AVAILABLE       = 14,
SSH_DISCONNECT_ILLEGAL_USER_NAME                    = 15,

/* libssh2_session_callback_set() constants */
LIBSSH2_CALLBACK_IGNORE             = 0,
LIBSSH2_CALLBACK_DEBUG              = 1,
LIBSSH2_CALLBACK_DISCONNECT         = 2,
LIBSSH2_CALLBACK_MACERROR           = 3,
LIBSSH2_CALLBACK_X11                = 4,
LIBSSH2_CALLBACK_SEND               = 5,
LIBSSH2_CALLBACK_RECV               = 6,

/* libssh2_session_method_pref() constants */
LIBSSH2_METHOD_KEX          = 0,
LIBSSH2_METHOD_HOSTKEY      = 1,
LIBSSH2_METHOD_CRYPT_CS     = 2,
LIBSSH2_METHOD_CRYPT_SC     = 3,
LIBSSH2_METHOD_MAC_CS       = 4,
LIBSSH2_METHOD_MAC_SC       = 5,
LIBSSH2_METHOD_COMP_CS      = 6,
LIBSSH2_METHOD_COMP_SC      = 7,
LIBSSH2_METHOD_LANG_CS      = 8,
LIBSSH2_METHOD_LANG_SC      = 9,

/* flags */
LIBSSH2_FLAG_SIGPIPE        = 1,
LIBSSH2_FLAG_COMPRESS       = 2,

LIBSSH2_CHANNEL_EXTENDED_DATA_NORMAL        = 0,
LIBSSH2_CHANNEL_EXTENDED_DATA_IGNORE        = 1,
LIBSSH2_CHANNEL_EXTENDED_DATA_MERGE         = 2,

SSH_EXTENDED_DATA_STDERR = 1,

};


typedef enum {
/* Error Codes (defined by libssh2) */
LIBSSH2_ERROR_NONE                      = 0,

/* The library once used -1 as a generic error return value on numerous places
   through the code, which subsequently was converted to
   LIBSSH2_ERROR_SOCKET_NONE uses over time. As this is a generic error code,
   the goal is to never ever return this code but instead make sure that a
   more accurate and descriptive error code is used. */
LIBSSH2_ERROR_SOCKET_NONE               = -1,

LIBSSH2_ERROR_BANNER_RECV               = -2,
LIBSSH2_ERROR_BANNER_SEND               = -3,
LIBSSH2_ERROR_INVALID_MAC               = -4,
LIBSSH2_ERROR_KEX_FAILURE               = -5,
LIBSSH2_ERROR_ALLOC                     = -6,
LIBSSH2_ERROR_SOCKET_SEND               = -7,
LIBSSH2_ERROR_KEY_EXCHANGE_FAILURE      = -8,
LIBSSH2_ERROR_TIMEOUT                   = -9,
LIBSSH2_ERROR_HOSTKEY_INIT              = -10,
LIBSSH2_ERROR_HOSTKEY_SIGN              = -11,
LIBSSH2_ERROR_DECRYPT                   = -12,
LIBSSH2_ERROR_SOCKET_DISCONNECT         = -13,
LIBSSH2_ERROR_PROTO                     = -14,
LIBSSH2_ERROR_PASSWORD_EXPIRED          = -15,
LIBSSH2_ERROR_FILE                      = -16,
LIBSSH2_ERROR_METHOD_NONE               = -17,
LIBSSH2_ERROR_AUTHENTICATION_FAILED     = -18,
LIBSSH2_ERROR_PUBLICKEY_UNRECOGNIZED    = LIBSSH2_ERROR_AUTHENTICATION_FAILED,
LIBSSH2_ERROR_PUBLICKEY_UNVERIFIED      = -19,
LIBSSH2_ERROR_CHANNEL_OUTOFORDER        = -20,
LIBSSH2_ERROR_CHANNEL_FAILURE           = -21,
LIBSSH2_ERROR_CHANNEL_REQUEST_DENIED    = -22,
LIBSSH2_ERROR_CHANNEL_UNKNOWN           = -23,
LIBSSH2_ERROR_CHANNEL_WINDOW_EXCEEDED   = -24,
LIBSSH2_ERROR_CHANNEL_PACKET_EXCEEDED   = -25,
LIBSSH2_ERROR_CHANNEL_CLOSED            = -26,
LIBSSH2_ERROR_CHANNEL_EOF_SENT          = -27,
LIBSSH2_ERROR_SCP_PROTOCOL              = -28,
LIBSSH2_ERROR_ZLIB                      = -29,
LIBSSH2_ERROR_SOCKET_TIMEOUT            = -30,
LIBSSH2_ERROR_SFTP_PROTOCOL             = -31,
LIBSSH2_ERROR_REQUEST_DENIED            = -32,
LIBSSH2_ERROR_METHOD_NOT_SUPPORTED      = -33,
LIBSSH2_ERROR_INVAL                     = -34,
LIBSSH2_ERROR_INVALID_POLL_TYPE         = -35,
LIBSSH2_ERROR_PUBLICKEY_PROTOCOL        = -36,
LIBSSH2_ERROR_EAGAIN                    = -37,
LIBSSH2_ERROR_BUFFER_TOO_SMALL          = -38,
LIBSSH2_ERROR_BAD_USE                   = -39,
LIBSSH2_ERROR_COMPRESS                  = -40,
LIBSSH2_ERROR_OUT_OF_BOUNDARY           = -41,
LIBSSH2_ERROR_AGENT_PROTOCOL            = -42,
LIBSSH2_ERROR_SOCKET_RECV               = -43,
LIBSSH2_ERROR_ENCRYPT                   = -44,
LIBSSH2_ERROR_BAD_SOCKET                = -45,
LIBSSH2_ERROR_KNOWN_HOSTS               = -46,

/* this is a define to provide the old (<= 1.2.7) name */
LIBSSH2_ERROR_BANNER_NONE = LIBSSH2_ERROR_BANNER_RECV,

LIBSSH2_KNOWNHOST_FILE_OPENSSH = 1,

LIBSSH2_TRACE_TRANS = 2,
LIBSSH2_TRACE_KEX   = 4,
LIBSSH2_TRACE_AUTH  = 8,
LIBSSH2_TRACE_CONN  = 16,
LIBSSH2_TRACE_SCP   = 32,
LIBSSH2_TRACE_SFTP  = 64,
LIBSSH2_TRACE_ERROR = 128,
LIBSSH2_TRACE_PUBLICKEY = 256,
LIBSSH2_TRACE_SOCKET = 512,


};

typedef struct _LIBSSH2_SESSION                     LIBSSH2_SESSION;
typedef struct _LIBSSH2_CHANNEL                     LIBSSH2_CHANNEL;
typedef struct _LIBSSH2_LISTENER                    LIBSSH2_LISTENER;
typedef struct _LIBSSH2_KNOWNHOSTS                  LIBSSH2_KNOWNHOSTS;
typedef struct _LIBSSH2_AGENT                       LIBSSH2_AGENT;

typedef int libssh2_socket_t;

typedef unsigned long long libssh2_uint64_t;
typedef long long libssh2_int64_t;


typedef struct _LIBSSH2_POLLFD {
	unsigned char type; /* LIBSSH2_POLLFD_* below */

	union {
		libssh2_socket_t socket; /* File descriptors -- examined with
									system select() call */
		LIBSSH2_CHANNEL *channel; /* Examined by checking internal state */
		LIBSSH2_LISTENER *listener; /* Read polls only -- are inbound
										connections waiting to be accepted? */
	} fd;

	unsigned long events; /* Requested Events */
	unsigned long revents; /* Returned Events */
} LIBSSH2_POLLFD;

struct libssh2_agent_publickey {
    unsigned int magic;              /* magic stored by the library */
    void *node;     /* handle to the internal representation of key */
    unsigned char *blob;           /* public key blob */
    size_t blob_len;               /* length of the public key blob */
    char *comment;                 /* comment in printable format */
};

struct libssh2_knownhost {
    unsigned int magic;  /* magic stored by the library */
    void *node; /* handle to the internal representation of this host */
    char *name; /* this is NULL if no plain text host name exists */
    char *key;  /* key in base64/printable format */
    int typemask;
};

unsigned long strlen(char *p);

char *strdup(const char *string);

]]

ffi.cdef[[
int libssh2_poll(LIBSSH2_POLLFD *fds, unsigned int nfds, long timeout);
int libssh2_init(int flags);
void libssh2_exit(void);
void libssh2_free(LIBSSH2_SESSION *session, void *ptr);
const char *libssh2_version(int req_version_num);
]]

local _M = {}
_M.__index = _M

--[[
url: https://www.libssh2.org/libssh2_poll.html
name: libssh2_poll - poll for activity on a socket, channel or listener
description: This function is deprecated. Do note use. We encourage users to instead use the poll(3) or select(3) functions to check for socket activity or when specific sockets are ready to get received from or send to.
Poll for activity on a socket, channel, listener, or any combination of these three types. The calling semantics for this function generally match poll(2) however the structure of fds is somewhat more complex in order to accommodate the disparate datatypes, POLLFD constants have been namespaced to avoid platform discrepancies, and revents has additional values defined.
RETURN VALUE
Number of fds with interesting events.
SEE ALSO
libssh2_poll_channel_read,
This HTML page was made with roffit.
]]

function _M.poll(fds, nfds, timeout)
	return prototype.libssh2_poll(fds, nfds, timeout)
end

--[[
url: https://www.libssh2.org/libssh2_init.html
name: libssh2_init - global library initialization
description: Initialize the libssh2 functions.  This typically initialize the crypto library.  It uses a global state, and is not thread safe -- you must make sure this function is not called concurrently.
RETURN VALUE
Returns 0 if succeeded, or a negative value for error.
AVAILABILITY
Added in libssh2 1.2.5
SEE ALSO
libssh2_exit,
This HTML page was made with roffit.
]]

function _M.init(flags)
	return prototype.libssh2_init(flags)
end

--[[
url: https://www.libssh2.org/libssh2_exit.html
name: libssh2_exit - global library deinitialization
description: Exit the libssh2 functions and free's all memory used internal.
AVAILABILITY
Added in libssh2 1.2.5
SEE ALSO
libssh2_init,
This HTML page was made with roffit.
]]

function _M.exit()
	prototype.libssh2_exit()
end

--[[
url: https://www.libssh2.org/libssh2_free.html
name: libssh2_free - deallocate libssh2 memory
description: Deallocate memory allocated by earlier call to libssh2 functions.  It uses the memory allocation callbacks provided by the application, if any.  Otherwise, this will just call free().
This function is mostly useful under Windows when libssh2 is linked to one run-time library and the application to another.
AVAILABILITY
Added in libssh2 1.2.8
SEE ALSO
libssh2_session_init_ex,
This HTML page was made with roffit.
]]

function _M.free(session, ptr)
	prototype.libssh2_free(session, ptr)
end

--[[
url: https://www.libssh2.org/libssh2_version.html
name: libssh2_version - return the libssh2 version number
description: If required_version is lower than or equal to the version number of the libssh2 in use, the version number of libssh2 is returned as a pointer to a zero terminated string.
The required_version should be the version number as constructed by the LIBSSH2_VERSION_NUM define in the libssh2.h public header file, which is a 24 bit number in the 0xMMmmpp format. MM for major, mm for minor and pp for patch number.
RETURN VALUE
The version number of libssh2 is returned as a pointer to a zero terminated string or NULL if the required_version isn't fulfilled.
EXAMPLE
To make sure you run with the correct libssh2 version:
if (!libssh2_version(LIBSSH2_VERSION_NUM)) {
   fprintf (stderr, "Runtime libssh2 version too old!");
   exit(1);
 }
Unconditionally get the version number:
printf("libssh2 version: %s", libssh2_version(0) );
AVAILABILITY
This function was added in libssh2 1.1, in previous versions there way no way to extract this info in run-time.
This HTML page was made with roffit.
]]
function _M.version(required_version)
	return prototype.libssh2_version(required_version)
end


function _M.c_strlen(str)
	return ffi.C.strlen(ffi.cast("char*", str))
end

function _M.c_string(str)
	return ffi.cast("char*", str)
end


return _M