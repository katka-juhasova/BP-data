local ffi = require "ffi"
local prototype = require "libssh2.prototype"

ffi.cdef[[
	int libssh2_knownhost_writeline(LIBSSH2_KNOWNHOSTS *hosts, struct libssh2_knownhost *known, char *buffer, size_t buflen, size_t *outlen, int type);
	void libssh2_knownhost_free(LIBSSH2_KNOWNHOSTS *hosts);
	int libssh2_knownhost_readline(LIBSSH2_KNOWNHOSTS *hosts, const char *line, size_t len, int type);
	int libssh2_knownhost_check(LIBSSH2_KNOWNHOSTS *hosts, const char *host, const char *key, size_t keylen, int typemask, struct libssh2_knownhost **knownhost);
	int libssh2_knownhost_del(LIBSSH2_KNOWNHOSTS *hosts, struct libssh2_knownhost *entry);
	int libssh2_knownhost_writefile(LIBSSH2_KNOWNHOSTS *hosts, const char *filename, int type);
	int libssh2_knownhost_add(LIBSSH2_KNOWNHOSTS *hosts, char *host, char *salt, char *key, size_t keylen, int typemask, struct libssh2_knownhost **store);
	LIBSSH2_KNOWNHOSTS *libssh2_knownhost_init(LIBSSH2_SESSION *session);
	int libssh2_knownhost_addc(LIBSSH2_KNOWNHOSTS *hosts,   char *host, char *salt,   char *key, size_t keylen,   const char *comment, size_t commentlen,   int typemask,   struct libssh2_knownhost **store);
	int libssh2_knownhost_get(LIBSSH2_KNOWNHOSTS *hosts, struct libssh2_knownhost **store, struct libssh2_knownhost *prev);
	int libssh2_knownhost_checkp(LIBSSH2_KNOWNHOSTS *hosts,  const char *host, int port,  const char *key, size_t keylen,  int typemask,  struct libssh2_knownhost **knownhost);
	int libssh2_knownhost_readfile(LIBSSH2_KNOWNHOSTS *hosts,    const char *filename, int type);
]]

local _M = {}
_M.__index = _M

--[[
url: https://www.libssh2.org/libssh2_knownhost_writeline.html
name: libssh2_knownhost_writeline - convert a known host to a line for storage
description: Converts a single known host to a single line of output for storage, using the 'type' output format.
known identifies which particular known host
buffer points to an allocated buffer
buflen is the size of the buffer. See RETURN VALUE about the size.
outlen must be a pointer to a size_t variable that will get the output length of the stored data chunk. The number does not included the trailing zero!
type specifies what file type it is, and LIBSSH2_KNOWNHOST_FILE_OPENSSH is the only currently supported format.
RETURN VALUE
Returns a regular libssh2 error code, where negative values are error codes and 0 indicates success.
If the provided buffer is deemed too small to fit the data libssh2 wants to store in it, LIBSSH2_ERROR_BUFFER_TOO_SMALL will be returned. The application is then advised to call the function again with a larger buffer. The outlen size will then hold the requested size.
AVAILABILITY
Added in libssh2 1.2
SEE ALSO
libssh2_knownhost_get, libssh2_knownhost_readline, libssh2_knownhost_writefile,
This HTML page was made with roffit.
]]

function _M:writeline(known, buffer, buflen, outlen, type)
	return prototype.libssh2_knownhost_writeline(self.knownhost, known, buffer, buflen, outlen, type)
end

--[[
url: https://www.libssh2.org/libssh2_knownhost_free.html
name: libssh2_knownhost_free - free a collection of known hosts
description: Free a collection of known hosts.
RETURN VALUE
None.
AVAILABILITY
Added in libssh2 1.2
SEE ALSO
libssh2_knownhost_init, libssh2_knownhost_add, libssh2_knownhost_check,
This HTML page was made with roffit.
]]

--void libssh2_knownhost_free(LIBSSH2_KNOWNHOSTS *hosts)

--[[
url: https://www.libssh2.org/libssh2_knownhost_readline.html
name: libssh2_knownhost_readline - read a known host line
description: Tell libssh2 to read a buffer as it if is a line from a known hosts file.
line points to the start of the line
len is the length of the line in bytes
type specifies what file type it is, and LIBSSH2_KNOWNHOST_FILE_OPENSSH is the only currently supported format. This file is normally found named ~/.ssh/known_hosts
RETURN VALUE
Returns a regular libssh2 error code, where negative values are error codes and 0 indicates success.
AVAILABILITY
Added in libssh2 1.2
SEE ALSO
libssh2_knownhost_get, libssh2_knownhost_writeline, libssh2_knownhost_readfile,
This HTML page was made with roffit.
]]

function _M:readline(line, line, len, type)
	return prototype.libssh2_knownhost_readline(self.knownhost, line, len, type)
end

--[[
url: https://www.libssh2.org/libssh2_knownhost_check.html
name: libssh2_knownhost_check - check a host+key against the list of known hosts
description: Checks a host and its associated key against the collection of known hosts, and returns info back about the (partially) matched entry.
host is a pointer the host name in plain text. The host name can be the IP numerical address of the host or the full name.
key is a pointer to the key for the given host.
keylen is the total size in bytes of the key pointed to by the key argument
typemask is a bitmask that specifies format and info about the data passed to this function. Specifically, it details what format the host name is, what format the key is and what key type it is.
The host name is given as one of the following types: LIBSSH2_KNOWNHOST_TYPE_PLAIN or LIBSSH2_KNOWNHOST_TYPE_CUSTOM.
The key is encoded using one of the following encodings: LIBSSH2_KNOWNHOST_KEYENC_RAW or LIBSSH2_KNOWNHOST_KEYENC_BASE64.
knownhost if set to non-NULL, it must be a pointer to a 'struct libssh2_knownhost' pointer that gets filled in to point to info about a known host that matches or partially matches.
RETURN VALUE
libssh2_knownhost_check returns info about how well the provided host + key pair matched one of the entries in the list of known hosts.
LIBSSH2_KNOWNHOST_CHECK_FAILURE - something prevented the check to be made
LIBSSH2_KNOWNHOST_CHECK_NOTFOUND - no host match was found
LIBSSH2_KNOWNHOST_CHECK_MATCH - hosts and keys match.
LIBSSH2_KNOWNHOST_CHECK_MISMATCH - host was found, but the keys didn't match!
AVAILABILITY
Added in libssh2 1.2
EXAMPLE
See the ssh2_exec.c example as provided in the tarball.
SEE ALSO
libssh2_knownhost_init, libssh2_knownhost_free, libssh2_knownhost_add,
This HTML page was made with roffit.
]]

function _M:check(host, key, keylen, typemask, knownhost)
	return prototype.libssh2_knownhost_check(self.knownhost, host, key, keylen, typemask, knownhost)
end

--[[
url: https://www.libssh2.org/libssh2_knownhost_del.html
name: libssh2_knownhost_del - delete a known host entry
description: Delete a known host entry from the collection of known hosts.
entry is a pointer to a struct that you can extract with libssh2_knownhost_check or libssh2_knownhost_get.
RETURN VALUE
Returns a regular libssh2 error code, where negative values are error codes and 0 indicates success.
AVAILABILITY
Added in libssh2 1.2
SEE ALSO
libssh2_knownhost_init, libssh2_knownhost_free, libssh2_knownhost_add, libssh2_knownhost_check,
This HTML page was made with roffit.
]]

function _M:del(entry)
	return prototype.libssh2_knownhost_del(self.knownhost, entry)
end

--[[
url: https://www.libssh2.org/libssh2_knownhost_writefile.html
name: libssh2_knownhost_writefile - write a collection of known hosts to a file
description: Writes all the known hosts to the specified file using the specified file format.
filename specifies what filename to create
type specifies what file type it is, and LIBSSH2_KNOWNHOST_FILE_OPENSSH is the only currently supported format.
RETURN VALUE
Returns a regular libssh2 error code, where negative values are error codes and 0 indicates success.
AVAILABILITY
Added in libssh2 1.2
SEE ALSO
libssh2_knownhost_readfile, libssh2_knownhost_add,
This HTML page was made with roffit.
]]

function _M:writefile(filename, type)
	return prototype.libssh2_knownhost_writefile(self.knownhost, filename, type)
end

--[[
url: https://www.libssh2.org/libssh2_knownhost_add.html
name: libssh2_knownhost_add - add a known host
description:We discourage use of this function as of libssh2 1.2.5. Instead we strongly urge users to use libssh2_knownhost_addc instead, which as a more complete API. libssh2_knownhost_add is subject for removal in a future release.
Adds a known host to the collection of known hosts identified by the 'hosts' handle.
host is a pointer the host name in plain text or hashed. If hashed, it must be provided base64 encoded. The host name can be the IP numerical address of the host or the full name.
saltP is a pointer to the salt used for the host hashing, if the host is provided hashed. If the host is provided in plain text, salt has no meaning. The salt has to be provided base64 encoded with a trailing zero byte.
key is a pointer to the key for the given host.
keylen is the total size in bytes of the key pointed to by the key argument
typemask is a bitmask that specifies format and info about the data passed to this function. Specifically, it details what format the host name is, what format the key is and what key type it is.
The host name is given as one of the following types: LIBSSH2_KNOWNHOST_TYPE_PLAIN, LIBSSH2_KNOWNHOST_TYPE_SHA1 or LIBSSH2_KNOWNHOST_TYPE_CUSTOM.
The key is encoded using one of the following encodings: LIBSSH2_KNOWNHOST_KEYENC_RAW or LIBSSH2_KNOWNHOST_KEYENC_BASE64.
The key is using one of these algorithms: LIBSSH2_KNOWNHOST_KEY_RSA1, LIBSSH2_KNOWNHOST_KEY_SSHRSA or LIBSSH2_KNOWNHOST_KEY_SSHDSS.
store should point to a pointer that gets filled in to point to the known host data after the addition. NULL can be passed if you don't care about this pointer.
]]
function _M:add(host, salt, key, keylen, typemask, store)
	return prototype.libssh2_knownhost_add(self.knownhost, host, salt, key, keylen, typemask, store)
end

--[[
url: https://www.libssh2.org/libssh2_knownhost_init.html
name: libssh2_knownhost_init - init a collection of known hosts
description: Init a collection of known hosts for this session. Returns the handle to an internal representation of a known host collection.
Call libssh2_knownhost_free to free the collection again after you're doing using it.
RETURN VALUE
Returns a handle pointer or NULL if something went wrong. The returned handle is used as input to all other known host related functions libssh2 provides.
AVAILABILITY
Added in libssh2 1.2
SEE ALSO
libssh2_knownhost_free, libssh2_knownhost_add, libssh2_knownhost_check,
This HTML page was made with roffit.
]]

function _M.init(session)
	local self = {}

	self.knownhost = prototype.libssh2_knownhost_init(session)
	ffi.gc(self.knownhost, prototype.libssh2_knownhost_free)

	return setmetatable(self, _M)
end

--[[
url: https://www.libssh2.org/libssh2_knownhost_addc.html
name: libssh2_knownhost_add - add a known host
description:Adds a known host to the collection of known hosts identified by the 'hosts' handle.
host is a pointer the host name in plain text or hashed. If hashed, it must be provided base64 encoded. The host name can be the IP numerical address of the host or the full name.
If you want to add a key for a specific port number for the given host, you must provide the host name like '[host]:port' with the actual characters '[' and ']' enclosing the host name and a colon separating the host part from the port number. For example: "[host.example.com]:222".
salt is a pointer to the salt used for the host hashing, if the host is provided hashed. If the host is provided in plain text, salt has no meaning. The salt has to be provided base64 encoded with a trailing zero byte.
key is a pointer to the key for the given host.
keylen is the total size in bytes of the key pointed to by the key argument
comment is a pointer to a comment for the key.
commentlen is the total size in bytes of the comment pointed to by the comment argument
typemask is a bitmask that specifies format and info about the data passed to this function. Specifically, it details what format the host name is, what format the key is and what key type it is.
The host name is given as one of the following types: LIBSSH2_KNOWNHOST_TYPE_PLAIN, LIBSSH2_KNOWNHOST_TYPE_SHA1 or LIBSSH2_KNOWNHOST_TYPE_CUSTOM.
The key is encoded using one of the following encodings: LIBSSH2_KNOWNHOST_KEYENC_RAW or LIBSSH2_KNOWNHOST_KEYENC_BASE64.
The key is using one of these algorithms: LIBSSH2_KNOWNHOST_KEY_RSA1, LIBSSH2_KNOWNHOST_KEY_SSHRSA or LIBSSH2_KNOWNHOST_KEY_SSHDSS.
store should point to a pointer that gets filled in to point to the known host data after the addition. NULL can be passed if you don't care about this pointer.
]]
function _M:addc(host, salt, key, keylen, comment, commentlen, typemask, store)
	return prototype.libssh2_knownhost_addc(self.knownhost, host, salt, key, keylen, comment, commentlen, typemask, store)
end

--[[
url: https://www.libssh2.org/libssh2_knownhost_get.html
name: libssh2_knownhost_get - get a known host off the collection of known hosts
description: libssh2_knownhost_get allows an application to iterate over all known hosts in the collection.
store should point to a pointer that gets filled in to point to the known host data.
prev is a pointer to a previous 'struct libssh2_knownhost' as returned by a previous invoke of this function, or NULL to get the first entry in the internal collection.
RETURN VALUE
Returns 0 if everything is fine and information about a host was stored in the store struct.
Returns 1 if it reached the end of hosts.
Returns negative values for error
AVAILABILITY
Added in libssh2 1.2
SEE ALSO
libssh2_knownhost_readfile, libssh2_knownhost_writefile, libssh2_knownhost_add,
This HTML page was made with roffit.
]]

function _M:get(store, prev)
	return prototype.libssh2_knownhost_get(self.knownhost, store, prev)
end

--[[
url: https://www.libssh2.org/libssh2_knownhost_checkp.html
name: libssh2_knownhost_checkp - check a host+key against the list of known hosts
description: Checks a host and its associated key against the collection of known hosts, and returns info back about the (partially) matched entry.
host is a pointer the host name in plain text. The host name can be the IP numerical address of the host or the full name.
port is the port number used by the host (or a negative number to check the generic host). If the port number is given, libssh2 will check the key for the specific host + port number combination in addition to the plain host name only check.
key is a pointer to the key for the given host.
keylen is the total size in bytes of the key pointed to by the key argument
typemask is a bitmask that specifies format and info about the data passed to this function. Specifically, it details what format the host name is, what format the key is and what key type it is.
The host name is given as one of the following types: LIBSSH2_KNOWNHOST_TYPE_PLAIN or LIBSSH2_KNOWNHOST_TYPE_CUSTOM.
The key is encoded using one of the following encodings: LIBSSH2_KNOWNHOST_KEYENC_RAW or LIBSSH2_KNOWNHOST_KEYENC_BASE64.
knownhost if set to non-NULL, it must be a pointer to a 'struct libssh2_knownhost' pointer that gets filled in to point to info about a known host that matches or partially matches.
RETURN VALUE
libssh2_knownhost_check returns info about how well the provided host + key pair matched one of the entries in the list of known hosts.
LIBSSH2_KNOWNHOST_CHECK_FAILURE - something prevented the check to be made
LIBSSH2_KNOWNHOST_CHECK_NOTFOUND - no host match was found
LIBSSH2_KNOWNHOST_CHECK_MATCH - hosts and keys match.
LIBSSH2_KNOWNHOST_CHECK_MISMATCH - host was found, but the keys didn't match!
AVAILABILITY
Added in libssh2 1.2.6
EXAMPLE
See the ssh2_exec.c example as provided in the tarball.
SEE ALSO
libssh2_knownhost_init, libssh2_knownhost_free, libssh2_knownhost_add,
This HTML page was made with roffit.
]]

function _M:checkp(host, port, key, keylen, typemask, knownhost)
	return prototype.libssh2_knownhost_checkp(self.knownhost, host, port, key, keylen, typemask, knownhost)
end

--[[
url: https://www.libssh2.org/libssh2_knownhost_readfile.html
name: libssh2_knownhost_readfile - parse a file of known hosts
description: Reads a collection of known hosts from a specified file and adds them to the collection of known hosts.
filename specifies which file to read
type specifies what file type it is, and LIBSSH2_KNOWNHOST_FILE_OPENSSH is the only currently supported format. This file is normally found named ~/.ssh/known_hosts
RETURN VALUE
Returns a negative value, a regular libssh2 error code for errors, or a positive number as number of parsed known hosts in the file.
AVAILABILITY
Added in libssh2 1.2
SEE ALSO
libssh2_knownhost_init, libssh2_knownhost_free, libssh2_knownhost_check,
This HTML page was made with roffit.
]]

function _M:readfile(filename, type)
	return prototype.libssh2_knownhost_readfile(self.knownhost, filename, type)
end


return _M