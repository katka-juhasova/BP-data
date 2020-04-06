local ffi = require "ffi"
local prototype = require "libssh2.prototype"
local channel = require "libssh2.channel"
local libssh2 = require "libssh2.libssh2"

ffi.cdef[[
	typedef struct _LIBSSH2_USERAUTH_KBDINT_PROMPT
	{
		char* text;
		unsigned int length;
		unsigned char echo;
	} LIBSSH2_USERAUTH_KBDINT_PROMPT;

	typedef struct _LIBSSH2_USERAUTH_KBDINT_RESPONSE
	{
		char* text;
		unsigned int length;
	} LIBSSH2_USERAUTH_KBDINT_RESPONSE;

	typedef void (*LIBSSH2_USERAUTH_KBDINT_RESPONSE_FUNC)(const char* name, int name_len, const char* instruction, int instruction_len, int num_prompts, const LIBSSH2_USERAUTH_KBDINT_PROMPT* prompts, LIBSSH2_USERAUTH_KBDINT_RESPONSE* responses, void **abstract);

	char * libssh2_userauth_list(LIBSSH2_SESSION *session, const char *username, unsigned int username_len);

	typedef void (*LIBSSH2_USERAUTH_PUBLICKEY_SIGN_FUNC)(LIBSSH2_SESSION *session, unsigned char **sig, size_t *sig_len, const unsigned char *data, size_t data_len, void **abstract);

	int libssh2_userauth_publickey(LIBSSH2_SESSION *session, const char *user, const unsigned char *pubkeydata, size_t pubkeydata_len, LIBSSH2_USERAUTH_PUBLICKEY_SIGN_FUNC sign_callback, void **abstract);
	int libssh2_userauth_publickey_fromfile_ex(LIBSSH2_SESSION *session, const char *username, unsigned int ousername_len, const char *publickey, const char *privatekey, const char *passphrase);
	int libssh2_userauth_keyboard_interactive_ex(LIBSSH2_SESSION *session, const char *username, unsigned int username_len, LIBSSH2_USERAUTH_KBDINT_RESPONSE_FUNC response_callback);

	typedef void (*LIBSSH2_PASSWD_CHANGEREQ_FUNC)(LIBSSH2_SESSION *session, char **newpw, int *newpw_len, void **abstract);

	int libssh2_userauth_password_ex(LIBSSH2_SESSION *session, const char *username, unsigned int username_len, const char *password, unsigned int password_len, LIBSSH2_PASSWD_CHANGEREQ_FUNC passwd_change_cb);
	int libssh2_userauth_authenticated(LIBSSH2_SESSION *session);
	int libssh2_userauth_publickey_frommemory(LIBSSH2_SESSION *session, const char *username, size_t username_len, const char *publickeydata, size_t publickeydata_len, const char *privatekeydata, size_t privatekeydata_len, const char *passphrase);
	int libssh2_userauth_hostbased_fromfile_ex(LIBSSH2_SESSION *session, const char *username, unsigned int username_len, const char *publickey, const char *privatekey, const char *passphrase, const char *hostname, unsigned int hostname_len, const char *local_username, unsigned int local_username_len);
]]

local _M = {}
_M.__index = _M

--[[
url: https://www.libssh2.org/libssh2_userauth_keyboard_interactive.html
name: libssh2_userauth_keyboard_interactive - convenience macro for libssh2_userauth_keyboard_interactive_ex calls
description: This is a macro defined in a public libssh2 header file that is using the underlying function libssh2_userauth_keyboard_interactive_ex.
RETURN VALUE
See libssh2_userauth_keyboard_interactive_ex
ERRORS
See libssh2_userauth_keyboard_interactive_ex
SEE ALSO
libssh2_userauth_keyboard_interactive_ex,
This HTML page was made with roffit.
]]

function _M.keyboard_interactive(session, username, response_callback)
	local len = ffi.C.strlen(ffi.cast("char*", username))
	return _M.keyboard_interactive_ex(session, username, len, response_callback)
end

 --[[
url: https://www.libssh2.org/libssh2_userauth_password.html
name: libssh2_userauth_password - convenience macro for libssh2_userauth_password_ex calls
description: This is a macro defined in a public libssh2 header file that is using the underlying function libssh2_userauth_password_ex.
RETURN VALUE
See libssh2_userauth_password_ex
ERRORS
See libssh2_userauth_password_ex
SEE ALSO
libssh2_userauth_password_ex,
This HTML page was made with roffit.
]]

function _M.password(session, username, password)
	return prototype.libssh2_userauth_password_ex(session, username, libssh2.c_strlen(username), password, libssh2.c_strlen(password), nil)
end

--[[
url: https://www.libssh2.org/libssh2_userauth_publickey_fromfile.html
name: libssh2_userauth_publickey_fromfile - convenience macro for libssh2_userauth_publickey_fromfile_ex calls
description: This is a macro defined in a public libssh2 header file that is using the underlying function libssh2_userauth_publickey_fromfile_ex.
RETURN VALUE
See libssh2_userauth_publickey_fromfile_ex
ERRORS
See libssh2_userauth_publickey_fromfile_ex
SEE ALSO
libssh2_userauth_publickey_fromfile_ex,
This HTML page was made with roffit.
]]

function _M.publickey_fromfile(session, username, publickey, privatekey, passphrase)
	return prototype.libssh2_userauth_publickey_fromfile_ex(session, username, libssh2.c_strlen(username), publickey, privatekey, passphrase)
end

--[[
url: https://www.libssh2.org/libssh2_userauth_list.html
name: libssh2_userauth_list - list supported authentication methods
description: session - Session instance as returned by  libssh2_session_init_ex,
username - Username which will be used while authenticating. Note that most server implementations do not permit attempting authentication with different usernames between requests. Therefore this must be the same username you will use on later userauth calls.
username_len - Length of username parameter.
Send a SSH_USERAUTH_NONE request to the remote host. Unless the remote host is configured to accept none as a viable authentication scheme (unlikely), it will return SSH_USERAUTH_FAILURE along with a listing of what authentication schemes it does support. In the unlikely event that none authentication succeeds, this method with return NULL. This case may be distinguished from a failing case by examining libssh2_userauth_authenticated.
RETURN VALUE
On success a comma delimited list of supported authentication schemes.  This list is internally managed by libssh2.  On failure returns NULL.
ERRORS
LIBSSH2_ERROR_ALLOC -  An internal memory allocation call failed.
LIBSSH2_ERROR_SOCKET_SEND - Unable to send data on socket.
LIBSSH2_ERROR_EAGAIN - Marked for non-blocking I/O but the call
SEE ALSO
libssh2_session_init_ex,
This HTML page was made with roffit.
]]

function _M.list(session, username, username_len)
	return prototype.libssh2_userauth_list(session, username, username_len)
end

 --[[
url: https://www.libssh2.org/libssh2_userauth_hostbased_fromfile_ex.html
name: libssh2_userauth_hostbased_fromfile_ex - TODO
description: RETURN VALUE
ERRORS
SEE ALSO
This HTML page was made with roffit.
]]
function _M.hostbased_fromfile_ex(session, username, username_len, publickey, privatekey, passphrase, hostname, hostname_len, local_username, local_username_len)
	return prototype.libssh2_userauth_hostbased_fromfile_ex(session, username, username_len, publickey, privatekey, passphrase, hostname, hostname_len, local_username, local_username_len)
end

--[[
url: https://www.libssh2.org/libssh2_userauth_publickey.html
name: libssh2_userauth_publickey - authenticate using a callback function
description: Authenticate with the sign_callback callback that matches the prototype below
CALLBACK
int name(LIBSSH2_SESSION *session, unsigned char **sig, size_t *sig_len,
   const unsigned char *data, size_t data_len, void **abstract);
This function gets called...
RETURN VALUE
Return 0 on success or negative on failure.
SEE ALSO
libssh2_userauth_publickey_fromfile_ex,
This HTML page was made with roffit.
]]

function _M.publickey(session, user, pubkeydata, pubkeydata_len, sign_callback, abstract)
	return prototype.libssh2_userauth_publickey(session, user, pubkeydata, pubkeydata_len, sign_callback, abstract)
end

 --[[
url: https://www.libssh2.org/libssh2_userauth_hostbased_fromfile.html
name: libssh2_userauth_hostbased_fromfile - convenience macro for libssh2_userauth_hostbased_fromfile_ex calls
description: This is a macro defined in a public libssh2 header file that is using the underlying function libssh2_userauth_hostbased_fromfile_ex.
RETURN VALUE
See libssh2_userauth_hostbased_fromfile_ex
ERRORS
See libssh2_userauth_hostbased_fromfile_ex
SEE ALSO
libssh2_userauth_hostbased_fromfile_ex,
This HTML page was made with roffit.
]]

function _M.hostbased_fromfile(session, username, publickey, privatekey, passphrase, hostname)
	return prototype.libssh2_userauth_hostbased_fromfile_ex(session, username, libssh2.c_strlen(username), publickey, privatekey, passphrase, hostname, libssh2.c_strlen(hostname), username, libssh2.c_strlen(username))
end

--[[
url: https://www.libssh2.org/libssh2_userauth_publickey_fromfile_ex.html
name: libssh2_userauth_publickey_fromfile - authenticate a session with a public key, read from a file
description: session - Session instance as returned by libssh2_session_init_ex
username - Pointer to user name to authenticate as.
username_len - Length of username.
publickey - Path name of the public key file. (e.g. /etc/ssh/hostkey.pub). If libssh2 is built against OpenSSL, this option can be set to NULL.
privatekey - Path name of the private key file. (e.g. /etc/ssh/hostkey)
passphrase - Passphrase to use when decoding privatekey.
Attempt public key authentication using a PEM encoded private key file stored on disk
RETURN VALUE
Return 0 on success or negative on failure.  It returns LIBSSH2_ERROR_EAGAIN when it would otherwise block. While LIBSSH2_ERROR_EAGAIN is a negative number, it isn't really a failure per se.
ERRORS
LIBSSH2_ERROR_ALLOC -  An internal memory allocation call failed.
LIBSSH2_ERROR_SOCKET_SEND - Unable to send data on socket.
LIBSSH2_ERROR_SOCKET_TIMEOUT -
LIBSSH2_ERROR_PUBLICKEY_UNVERIFIED - The username/public key combination was invalid.
LIBSSH2_ERROR_AUTHENTICATION_FAILED - Authentication using the supplied public key was not accepted.
SEE ALSO
libssh2_session_init_ex,
This HTML page was made with roffit.
]]

function _M.publickey_fromfile_ex(session, username,  ousername_len, publickey, privatekey, passphrase)
	return prototype.libssh2_userauth_publickey_fromfile_ex(session, username,  ousername_len, publickey, privatekey, passphrase)
end

 --[[
url: https://www.libssh2.org/libssh2_userauth_keyboard_interactive_ex.html
name: libssh2_userauth_keyboard_interactive_ex - authenticate a session using keyboard-interactive authentication
description: session - Session instance as returned by libssh2_session_init_ex.
username - Name of user to attempt keyboard-interactive authentication for.
username_len - Length of username parameter.
response_callback - As authentication proceeds, the host issues several (1 or more) challenges and requires responses. This callback will be called at this moment. The callback is responsible to obtain responses for the challenges, fill the provided data structure and then return control. Responses will be sent to the host. String values will be free(3)ed by the library. The callback prototype must match this:
 void response(const char *name,
  int name_len, const char *instruction,
  int instruction_len,
  int num_prompts,
  const LIBSSH2_USERAUTH_KBDINT_PROMPT *prompts,
  LIBSSH2_USERAUTH_KBDINT_RESPONSE *responses,
  void **abstract);
Attempts keyboard-interactive (challenge/response) authentication.
Note that many SSH servers will always issue a single "password" challenge, requesting actual password as response, but it is not required by the protocol, and various authentication schemes, such as smartcard authentication may use keyboard-interactive authentication type too.
RETURN VALUE
Return 0 on success or negative on failure.  It returns LIBSSH2_ERROR_EAGAIN when it would otherwise block. While LIBSSH2_ERROR_EAGAIN is a negative number, it isn't really a failure per se.
ERRORS
LIBSSH2_ERROR_ALLOC -  An internal memory allocation call failed.
LIBSSH2_ERROR_SOCKET_SEND - Unable to send data on socket.
fLIBSSH2_ERROR_AUTHENTICATION_FAILED - failed, invalid username/password or public/private key.
SEE ALSO
libssh2_session_init_ex,
This HTML page was made with roffit.
]]

function _M.keyboard_interactive_ex(session, username, username_len, response_callback)
	return prototype.libssh2_userauth_keyboard_interactive_ex(session, username, username_len, response_callback)
end

--[[
url: https://www.libssh2.org/libssh2_userauth_password_ex.html
name: libssh2_userauth_password_ex - authenticate a session with username and password
description: session - Session instance as returned by  libssh2_session_init_ex,
username - Name of user to attempt plain password authentication for.
username_len - Length of username parameter.
password - Password to use for authenticating username.
password_len - Length of password parameter.
passwd_change_cb - If the host accepts authentication but  requests that the password be changed, this callback will be issued.  If no callback is defined, but server required password change,  authentication will fail.
Attempt basic password authentication. Note that many SSH servers  which appear to support ordinary password authentication actually have  it disabled and use Keyboard Interactive authentication (routed via  PAM or another authentication backed) instead.
RETURN VALUE
Return 0 on success or negative on failure.  It returns LIBSSH2_ERROR_EAGAIN when it would otherwise block. While LIBSSH2_ERROR_EAGAIN is a negative number, it isn't really a failure per se.
ERRORS
Some of the errors this function may return include:
LIBSSH2_ERROR_ALLOC -  An internal memory allocation call failed.
LIBSSH2_ERROR_SOCKET_SEND - Unable to send data on socket.
LIBSSH2_ERROR_PASSWORD_EXPIRED -
fLIBSSH2_ERROR_AUTHENTICATION_FAILED - failed, invalid username/password or public/private key.
SEE ALSO
libssh2_session_init_ex,
This HTML page was made with roffit.
]]

function _M.password_ex(session, username, username_len, password, password_len, passwd_change_cb)
	return prototype.libssh2_userauth_password_ex(session, username, username_len, password, password_len, passwd_change_cb)
end


--[[
url: https://www.libssh2.org/libssh2_userauth_authenticated.html
name: libssh2_userauth_authenticated - return authentication status
description: session - Session instance as returned by  libssh2_session_init_ex,
Indicates whether or not the named session has been successfully authenticated.
RETURN VALUE
Returns 1 if authenticated and 0 if not.
SEE ALSO
libssh2_session_init_ex,
This HTML page was made with roffit.
]]

function _M.authenticated(session)
	return prototype.libssh2_userauth_authenticated(session)
end

--[[
url: https://www.libssh2.org/libssh2_userauth_publickey_frommemory.html
name: libssh2_userauth_publickey_frommemory - authenticate a session with a public key, read from memory
description: This function allows to authenticate a session with a public key read from memory. It's only supported when libssh2 is backed by OpenSSL. session - Session instance as returned by libssh2_session_init_ex,
username - Remote user name to authenticate as.
username_len - Length of username.
publickeydata - Buffer containing the contents of a public key file.
publickeydata_len - Length of public key data.
privatekeydata - Buffer containing the contents of a private key file.
privatekeydata_len - Length of private key data.
passphrase - Passphrase to use when decoding private key file.
Attempt public key authentication using a PEM encoded private key file stored in memory.
RETURN VALUE
Return 0 on success or negative on failure.  It returns LIBSSH2_ERROR_EAGAIN when it would otherwise block. While LIBSSH2_ERROR_EAGAIN is a negative number, it isn't really a failure per se.
ERRORS
LIBSSH2_ERROR_ALLOC -  An internal memory allocation call failed.
LIBSSH2_ERROR_SOCKET_SEND - Unable to send data on socket.
LIBSSH2_ERROR_SOCKET_TIMEOUT -
LIBSSH2_ERROR_PUBLICKEY_UNVERIFIED - The username/public key combination was invalid.
LIBSSH2_ERROR_AUTHENTICATION_FAILED - Authentication using the supplied public key was not accepted.
AVAILABILITY
libssh2_userauth_publickey_frommemory was added in libssh2 1.6.0
SEE ALSO
libssh2_session_init_ex,
This HTML page was made with roffit.
]]

function _M.publickey_frommemory(session, username, username_len, publickeydata, publickeydata_len, privatekeydata, privatekeydata_len, passphrase)
	return prototype.libssh2_userauth_publickey_frommemory(session, username, username_len, publickeydata, publickeydata_len, privatekeydata, privatekeydata_len, passphrase)
end



return _M