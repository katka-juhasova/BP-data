local ffi = require "ffi"
local prototype = require "libssh2.prototype"
local libssh2 = require "libssh2.libssh2"


ffi.cdef[[
typedef struct _LIBSSH2_PUBLICKEY               LIBSSH2_PUBLICKEY;

typedef struct _libssh2_publickey_attribute {
    const char *name;
    unsigned long name_len;
    const char *value;
    unsigned long value_len;
    char mandatory;
} libssh2_publickey_attribute;

typedef struct _libssh2_publickey_list {
    unsigned char *packet; /* For freeing */

    const unsigned char *name;
    unsigned long name_len;
    const unsigned char *blob;
    unsigned long blob_len;
    unsigned long num_attrs;
    libssh2_publickey_attribute *attrs; /* free me */
} libssh2_publickey_list;


int libssh2_publickey_list_fetch(LIBSSH2_PUBLICKEY *pkey, unsigned long *num_keys, libssh2_publickey_list **pkey_list);
void libssh2_publickey_list_free(LIBSSH2_PUBLICKEY *pkey, libssh2_publickey_list *pkey_list);
int libssh2_publickey_add_ex(LIBSSH2_PUBLICKEY *pkey, const unsigned char *name, unsigned long name_len, const unsigned char *blob, unsigned long blob_len, char overwrite, unsigned long num_attrs, const libssh2_publickey_attribute attrs[]);
LIBSSH2_PUBLICKEY *libssh2_publickey_init(LIBSSH2_SESSION *session);
int libssh2_publickey_remove_ex(LIBSSH2_PUBLICKEY *pkey, const unsigned char *name, unsigned long name_len, const unsigned char *blob, unsigned long blob_len);
int libssh2_publickey_shutdown(LIBSSH2_PUBLICKEY *pkey);
]]

local _M = {}
_M.__index = _M

--[[
url: https://www.libssh2.org/libssh2_publickey_list_fetch.html
name: libssh2_publickey_list_fetch - TODO
description:
]]
function _M:list_fetch(num_keys, pkey_list)
	return prototype.libssh2_publickey_list_fetch(self.publickey, num_keys, pkey_list)
end

--[[
url: https://www.libssh2.org/libssh2_publickey_list_free.html
name: libssh2_publickey_list_free - TODO
description:
]]
function _M:list_free(pkey_list)
	prototype.libssh2_publickey_list_free(self.publickey, pkey_list)
end

--[[
url: https://www.libssh2.org/libssh2_publickey_add_ex.html
name: libssh2_publickey_add_ex - Add a public key entry
description: TBD
RETURN VALUE
Returns 0 on success, negative on failure.
ERRORS
LIBSSH2_ERROR_BAD_USE LIBSSH2_ERROR_ALLOC, LIBSSH2_ERROR_EAGAIN LIBSSH2_ERROR_SOCKET_SEND, LIBSSH2_ERROR_SOCKET_TIMEOUT, LIBSSH2_ERROR_PUBLICKEY_PROTOCOL,
SEE ALSO
This HTML page was made with roffit.
]]
function _M:add_ex(name, name_len, blob, blob_len, overwrite, num_attrs, attrs)
	return prototype.libssh2_publickey_add_ex(self.publickey, name, name_len, blob, blob_len, overwrite, num_attrs, attrs)
end

--[[
url: https://www.libssh2.org/libssh2_publickey_init.html
name: libssh2_publickey_init - TODO
description:
]]
function _M.init(session)
	local self = {}

	self.publickey = prototype.libssh2_publickey_init(session)

	return setmetatable(self, _M)
end

--[[
url: https://www.libssh2.org/libssh2_publickey_remove.html
name: libssh2_publickey_remove - convenience macro for libssh2_publickey_remove_ex calls
description: This is a macro defined in a public libssh2 header file that is using the underlying function libssh2_publickey_remove_ex.
RETURN VALUE
See libssh2_publickey_remove_ex
ERRORS
See libssh2_publickey_remove_ex
SEE ALSO
libssh2_publickey_remove_ex,
This HTML page was made with roffit.
]]
function _M:remove(name, name_len, blob, blob_len)
    return prototype.libssh2_publickey_remove_ex(self.publickey, name, name_len, blob, blob_len)
end

--[[
url: https://www.libssh2.org/libssh2_publickey_shutdown.html
name: libssh2_publickey_shutdown - TODO
description: RETURN VALUE
ERRORS
SEE ALSO
This HTML page was made with roffit.
]]
function _M:shutdown()
    return prototype.libssh2_publickey_shutdown(self.publickey)
end

--[[
url: https://www.libssh2.org/libssh2_publickey_add.html
name: libssh2_publickey_add - convenience macro for libssh2_publickey_add_ex calls
description: This is a macro defined in a public libssh2 header file that is using the underlying function libssh2_publickey_add_ex.
RETURN VALUE
See libssh2_publickey_add_ex
ERRORS
See libssh2_publickey_add_ex
SEE ALSO
libssh2_publickey_add_ex,
This HTML page was made with roffit.
]]
function _M:add(name, blob, blob_len, overwrite, num_attrs, attrs)
	return prototype.libssh2_publickey_add_ex(self.publickey, name, libssh2.c_strlen(name), blob, blob_len, overwrite, num_attrs, attrs)
end

return _M