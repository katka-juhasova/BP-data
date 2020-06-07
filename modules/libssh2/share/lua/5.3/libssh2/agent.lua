local ffi = require "ffi"
local prototype = require "libssh2.prototype"

ffi.cdef[[
	int libssh2_agent_userauth(LIBSSH2_AGENT *agent, const char *username, struct libssh2_agent_publickey *identity);
	int libssh2_agent_list_identities(LIBSSH2_AGENT *agent);
	LIBSSH2_AGENT *libssh2_agent_init(LIBSSH2_SESSION *session);
	int libssh2_agent_get_identity(LIBSSH2_AGENT *agent, struct libssh2_agent_publickey **store, struct libssh2_agent_publickey *prev);
	int libssh2_agent_connect(LIBSSH2_AGENT *agent);
	void libssh2_agent_free(LIBSSH2_AGENT *agent);
	int libssh2_agent_disconnect(LIBSSH2_AGENT *agent);
]]

local _M = {}
_M.__index = _M

--[[
url: https://www.libssh2.org/libssh2_agent_userauth.html
name: libssh2_agent_userauth - authenticate a session with a public key, with the help of ssh-agent
description: agent - ssh-agent handle as returned by  libssh2_agent_init,
username - Remote user name to authenticate as.
identity - Public key to authenticate with, as returned by  libssh2_agent_get_identity,
Attempt public key authentication with the help of ssh-agent.
RETURN VALUE
Returns 0 if succeeded, or a negative value for error.
AVAILABILITY
Added in libssh2 1.2
SEE ALSO
libssh2_agent_init, libssh2_agent_get_identity,
This HTML page was made with roffit.
]]

function _M:userauth(username, identity)
	return prototype.libssh2_agent_userauth(self.agent, username, identity)
end

--[[
url: https://www.libssh2.org/libssh2_agent_list_identities.html
name: libssh2_agent_list_identities - request an ssh-agent to list of public keys.
description: Request an ssh-agent to list of public keys, and stores them in the internal collection of the handle.  Call libssh2_agent_get_identity to get a public key off the collection.
RETURN VALUE
Returns 0 if succeeded, or a negative value for error.
AVAILABILITY
Added in libssh2 1.2
SEE ALSO
libssh2_agent_connect, libssh2_agent_get_identity,
This HTML page was made with roffit.
]]

function _M:list_identities()
	return prototype.libssh2_agent_list_identities(self.agent)
end

--[[
url: https://www.libssh2.org/libssh2_agent_init.html
name: libssh2_agent_init - init an ssh-agent handle
description: Init an ssh-agent handle. Returns the handle to an internal representation of an ssh-agent connection.  After the successful initialization, an application can call libssh2_agent_connect to connect to a running ssh-agent.
Call libssh2_agent_free to free the handle again after you're doing using it.
RETURN VALUE
Returns a handle pointer or NULL if something went wrong. The returned handle is used as input to all other ssh-agent related functions libssh2 provides.
AVAILABILITY
Added in libssh2 1.2
SEE ALSO
libssh2_agent_connect, libssh2_agent_free,
This HTML page was made with roffit.
]]

function _M.init(session)
	local self = {}

	self.agent = prototype.libssh2_agent_init(session)
	ffi.gc(self.agent, prototype.libssh2_agent_free)

	return setmetatable(self, _M)
end

--[[
url: https://www.libssh2.org/libssh2_agent_get_identity.html
name: libssh2_agent_get_identity - get a public key off the collection of public keys managed by ssh-agent
description: libssh2_agent_get_identity allows an application to iterate over all public keys in the collection managed by ssh-agent.
store should point to a pointer that gets filled in to point to the public key data.
prev is a pointer to a previous 'struct libssh2_agent_publickey' as returned by a previous invoke of this function, or NULL to get the first entry in the internal collection.
RETURN VALUE
Returns 0 if everything is fine and information about a host was stored in the store struct.
Returns 1 if it reached the end of public keys.
Returns negative values for error
AVAILABILITY
Added in libssh2 1.2
SEE ALSO
libssh2_agent_list_identities, libssh2_agent_userauth,
This HTML page was made with roffit.
]]

function _M:get_identity(store, prev)
	return prototype.libssh2_agent_get_identity(self.agent, store, prev)
end

--[[
url: https://www.libssh2.org/libssh2_agent_connect.html
name: libssh2_agent_connect - connect to an ssh-agent
description: Connect to an ssh-agent running on the system.
Call libssh2_agent_disconnect to close the connection after you're doing using it.
RETURN VALUE
Returns 0 if succeeded, or a negative value for error.
AVAILABILITY
Added in libssh2 1.2
SEE ALSO
libssh2_agent_init, libssh2_agent_disconnect,
This HTML page was made with roffit.
]]

function _M:connect()
	return prototype.libssh2_agent_connect(self.agent)
end

--[[
url: https://www.libssh2.org/libssh2_agent_free.html
name: libssh2_agent_free - free an ssh-agent handle
description: Free an ssh-agent handle.  This function also frees the internal collection of public keys.
RETURN VALUE
None.
AVAILABILITY
Added in libssh2 1.2
SEE ALSO
libssh2_agent_init, libssh2_agent_disconnect,
This HTML page was made with roffit.
]]

--void libssh2_agent_free(LIBSSH2_AGENT *agent);

--[[
url: https://www.libssh2.org/libssh2_agent_disconnect.html
name: libssh2_agent_disconnect - close a connection to an ssh-agent
description: Close a connection to an ssh-agent.
RETURN VALUE
Returns 0 if succeeded, or a negative value for error.
AVAILABILITY
Added in libssh2 1.2
SEE ALSO
libssh2_agent_connect, libssh2_agent_free,
This HTML page was made with roffit.
]]

function _M:disconnect()
	return prototype.libssh2_agent_disconnect(self.agent)
end

return _M