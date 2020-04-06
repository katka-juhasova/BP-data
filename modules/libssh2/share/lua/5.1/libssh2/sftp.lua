local ffi = require "ffi"
local prototype = require "libssh2.prototype"
local libssh2 = require "libssh2.libssh2"
local bit = require "bit"

ffi.cdef[[
	typedef struct _LIBSSH2_SFTP                LIBSSH2_SFTP;
	typedef struct _LIBSSH2_SFTP_HANDLE         LIBSSH2_SFTP_HANDLE;
	typedef struct _LIBSSH2_SFTP_ATTRIBUTES     LIBSSH2_SFTP_ATTRIBUTES;
	typedef struct _LIBSSH2_SFTP_STATVFS        LIBSSH2_SFTP_STATVFS;

	typedef enum {
		/* Flags for open_ex() */
		LIBSSH2_SFTP_OPENFILE           = 0,
		LIBSSH2_SFTP_OPENDIR            = 1,

		/* Flags for rename_ex() */
		LIBSSH2_SFTP_RENAME_OVERWRITE   = 0x00000001,
		LIBSSH2_SFTP_RENAME_ATOMIC      = 0x00000002,
		LIBSSH2_SFTP_RENAME_NATIVE      = 0x00000004,

		/* Flags for stat_ex() */
		LIBSSH2_SFTP_STAT               = 0,
		LIBSSH2_SFTP_LSTAT              = 1,
		LIBSSH2_SFTP_SETSTAT            = 2,

		/* Flags for symlink_ex() */
		LIBSSH2_SFTP_SYMLINK            = 0,
		LIBSSH2_SFTP_READLINK           = 1,
		LIBSSH2_SFTP_REALPATH           = 2,

		/* SFTP attribute flag bits */
		LIBSSH2_SFTP_ATTR_SIZE              = 0x00000001,
		LIBSSH2_SFTP_ATTR_UIDGID            = 0x00000002,
		LIBSSH2_SFTP_ATTR_PERMISSIONS       = 0x00000004,
		LIBSSH2_SFTP_ATTR_ACMODTIME         = 0x00000008,
		LIBSSH2_SFTP_ATTR_EXTENDED          = 0x80000000,

		/* SFTP statvfs flag bits */
		LIBSSH2_SFTP_ST_RDONLY              = 0x00000001,
		LIBSSH2_SFTP_ST_NOSUID              = 0x00000002,


		LIBSSH2_FXF_READ                    = 0x00000001,
		LIBSSH2_FXF_WRITE                   = 0x00000002,
		LIBSSH2_FXF_APPEND                  = 0x00000004,
		LIBSSH2_FXF_CREAT                   = 0x00000008,
		LIBSSH2_FXF_TRUNC                   = 0x00000010,
		LIBSSH2_FXF_EXCL                    = 0x00000020,
	};

	struct _LIBSSH2_SFTP_ATTRIBUTES {
		/* If flags & ATTR_* bit is set, then the value in this struct will be
		 * meaningful Otherwise it should be ignored
		 */
		unsigned long flags;

		libssh2_uint64_t filesize;
		unsigned long uid, gid;
		unsigned long permissions;
		unsigned long atime, mtime;
	};

	struct _LIBSSH2_SFTP_STATVFS {
		libssh2_uint64_t  f_bsize;    /* file system block size */
		libssh2_uint64_t  f_frsize;   /* fragment size */
		libssh2_uint64_t  f_blocks;   /* size of fs in f_frsize units */
		libssh2_uint64_t  f_bfree;    /* # free blocks */
		libssh2_uint64_t  f_bavail;   /* # free blocks for non-root */
		libssh2_uint64_t  f_files;    /* # inodes */
		libssh2_uint64_t  f_ffree;    /* # free inodes */
		libssh2_uint64_t  f_favail;   /* # free inodes for non-root */
		libssh2_uint64_t  f_fsid;     /* file system ID */
		libssh2_uint64_t  f_flag;     /* mount flags */
		libssh2_uint64_t  f_namemax;  /* maximum filename length */
	};


	LIBSSH2_SFTP * libssh2_sftp_init(LIBSSH2_SESSION *session);
	unsigned long  libssh2_sftp_last_error(LIBSSH2_SFTP *sftp);
	int libssh2_sftp_statvfs(LIBSSH2_SFTP *sftp, const char *path, size_t path_len, LIBSSH2_SFTP_STATVFS *st);
	int libssh2_sftp_fstat_ex(LIBSSH2_SFTP_HANDLE *handle, LIBSSH2_SFTP_ATTRIBUTES *attrs, int setstat);
	int libssh2_sftp_unlink_ex(LIBSSH2_SFTP *sftp, const char *filename, unsigned int filename_len);
	int libssh2_sftp_readdir_ex(LIBSSH2_SFTP_HANDLE *handle, char *buffer, size_t buffer_maxlen, char *longentry, size_t longentry_maxlen, LIBSSH2_SFTP_ATTRIBUTES *attrs);
	void libssh2_sftp_seek(LIBSSH2_SFTP_HANDLE *handle, size_t offset);
	LIBSSH2_SFTP_HANDLE * libssh2_sftp_open_ex(LIBSSH2_SFTP *sftp, const char *filename, unsigned int filename_len, unsigned long flags, long mode, int open_type);
	int libssh2_sftp_rename_ex(LIBSSH2_SFTP *sftp, const char *source_filename, unsigned int source_filename_len, const char *dest_filename, unsigned int dest_filename_len, long flags);
	libssh2_uint64_t libssh2_sftp_tell64(LIBSSH2_SFTP_HANDLE *handle);
	int libssh2_sftp_mkdir_ex(LIBSSH2_SFTP *sftp, const char *path, unsigned int path_len, long mode);
	int libssh2_sftp_rmdir_ex(LIBSSH2_SFTP *sftp, const char *path, unsigned int path_len);
	int libssh2_sftp_stat_ex(LIBSSH2_SFTP *sftp, const char *path, unsigned int path_len, int stat_type, LIBSSH2_SFTP_ATTRIBUTES *attrs);
	ssize_t libssh2_sftp_write(LIBSSH2_SFTP_HANDLE *handle, const char *buffer, size_t count);
	int libssh2_sftp_symlink_ex(LIBSSH2_SFTP *sftp, const char *path, unsigned int path_len, char *target, unsigned int target_len, int link_type);
	int libssh2_sftp_close_handle(LIBSSH2_SFTP_HANDLE *handle);
	int libssh2_sftp_shutdown(LIBSSH2_SFTP *sftp);
	size_t libssh2_sftp_tell(LIBSSH2_SFTP_HANDLE *handle);
	ssize_t libssh2_sftp_read(LIBSSH2_SFTP_HANDLE *handle, char *buffer, size_t buffer_maxlen);
	int libssh2_sftp_fstatvfs(LIBSSH2_SFTP_HANDLE *handle, LIBSSH2_SFTP_STATVFS *st);
	void libssh2_sftp_seek64(LIBSSH2_SFTP_HANDLE *handle, libssh2_uint64_t offset);
	int libssh2_sftp_fsync(LIBSSH2_SFTP_HANDLE *handle);
]]

local _M = {}
_M.__index = _M


--[[
url: https://www.libssh2.org/libssh2_sftp_mkdir.html
name: libssh2_sftp_mkdir - convenience macro for libssh2_sftp_mkdir_ex calls
description: This is a macro defined in a public libssh2 header file that is using the underlying function libssh2_sftp_mkdir_ex.
RETURN VALUE
See libssh2_sftp_mkdir_ex
ERRORS
See libssh2_sftp_mkdir_ex
SEE ALSO
libssh2_sftp_mkdir_ex,
This HTML page was made with roffit.
]]

function _M:mkdir(path, mode)
	return self:mkdir_ex(path, libssh2.c_strlen(path), mode)
end


--[[
url: https://www.libssh2.org/libssh2_sftp_rename.html
name: libssh2_sftp_rename - convenience macro for libssh2_sftp_rename_ex calls
description: This is a macro defined in a public libssh2 header file that is using the underlying function libssh2_sftp_rename_ex.
RETURN VALUE
See libssh2_sftp_rename_ex
ERRORS
See libssh2_sftp_rename_ex
SEE ALSO
libssh2_sftp_rename_ex,
This HTML page was made with roffit.
]]

function _M:rename(source_filename, destination_filename)
	local flag = 0
	flag = bit.bor(flag, ffi.C.LIBSSH2_SFTP_RENAME_OVERWRITE)
	flag = bit.bor(flag, ffi.C.LIBSSH2_SFTP_RENAME_ATOMIC)
	flag = bit.bor(flag, ffi.C.LIBSSH2_SFTP_RENAME_NATIVE)
	return self:rename_ex(source_filename, libssh2.c_strlen(source_filename), destination_filename, libssh2.c_strlen(destination_filename), flag)
end


--[[
url: https://www.libssh2.org/libssh2_sftp_init.html
name: libssh2_sftp_init - open SFTP channel for the given SSH session.
description: session - Session instance as returned by  libssh2_session_init_ex,
Open a channel and initialize the SFTP subsystem. Although the SFTP subsystem operates over the same type of channel as those exported by the Channel API, the protocol itself implements its own unique binary packet protocol which must be managed with the libssh2_sftp_*() family of functions. When an SFTP session is complete, it must be destroyed using the libssh2_sftp_shutdown, function.
RETURN VALUE
A pointer to the newly allocated SFTP instance or NULL on failure.
ERRORS
LIBSSH2_ERROR_ALLOC -  An internal memory allocation call failed.
LIBSSH2_ERROR_SOCKET_SEND - Unable to send data on socket.
LIBSSH2_ERROR_SOCKET_TIMEOUT -
LIBSSH2_ERROR_SFTP_PROTOCOL - An invalid SFTP protocol response was  received on the socket, or an SFTP operation caused an errorcode to be  returned by the server.
LIBSSH2_ERROR_EAGAIN - Marked for non-blocking I/O but the call would block.
SEE ALSO
libssh2_sftp_shutdown, libssh2_sftp_open_ex,
This HTML page was made with roffit.
]]

function _M.init(session)
	local self = {}

	self.sftp = prototype.libssh2_sftp_init(session)
	ffi.gc(self.sftp, prototype.libssh2_sftp_shutdown)

	return setmetatable(self, _M)
end


--[[
url: https://www.libssh2.org/libssh2_sftp_last_error.html
name: libssh2_sftp_last_error - return the last SFTP-specific error code
description: sftp - SFTP instance as returned by  libssh2_sftp_init,
Returns the last error code produced by the SFTP layer. Note that this only returns a sensible error code if libssh2 returned LIBSSH2_ERROR_SFTP_PROTOCOL in a previous call. Using libssh2_sftp_last_error without a preceding SFTP protocol error, it will return an unspecified value.
RETURN VALUE
Current error code state of the SFTP instance.
SEE ALSO
libssh2_sftp_init,
This HTML page was made with roffit.
]]

function _M:last_error()
	return prototype.libssh2_sftp_last_error(self.sftp)
end


--[[
url: https://www.libssh2.org/libssh2_sftp_stat.html
name: libssh2_sftp_stat - convenience macro for libssh2_sftp_fstat_ex calls
description: This is a macro defined in a public libssh2 header file that is using the underlying function libssh2_sftp_fstat_ex.
RETURN VALUE
See libssh2_sftp_fstat_ex
ERRORS
See libssh2_sftp_fstat_ex
SEE ALSO
libssh2_sftp_fstat_ex,
This HTML page was made with roffit.
]]

function _M:stat(path, attrs)
	return self:stat_ex(path, libssh2.c_strlen(path), ffi.C.LIBSSH2_SFTP_STAT, attrs)
end


--[[
url: https://www.libssh2.org/libssh2_sftp_statvfs.html
name: libssh2_sftp_statvfs, libssh2_sftp_fstatvfs - get file system statistics
description: These functions provide statvfs(2)-like operations and require statvfs@openssh.com and fstatvfs@openssh.com extension support on the server.
sftp - SFTP instance as returned by libssh2_sftp_init,
handle - SFTP File Handle as returned by libssh2_sftp_open_ex,
path - full path of any file within the mounted file system.
path_len - length of the full path.
st - Pointer to a LIBSSH2_SFTP_STATVFS structure to place file system statistics into.
DATA TYPES
LIBSSH2_SFTP_STATVFS is a typedefed struct that is defined as below
struct _LIBSSH2_SFTP_STATVFS {
     libssh2_uint64_t  f_bsize;    /* file system block size */
     libssh2_uint64_t  f_frsize;   /* fragment size */
     libssh2_uint64_t  f_blocks;   /* size of fs in f_frsize units */
     libssh2_uint64_t  f_bfree;    /* # free blocks */
     libssh2_uint64_t  f_bavail;   /* # free blocks for non-root */
     libssh2_uint64_t  f_files;    /* # inodes */
     libssh2_uint64_t  f_ffree;    /* # free inodes */
     libssh2_uint64_t  f_favail;   /* # free inodes for non-root */
     libssh2_uint64_t  f_fsid;     /* file system ID */
     libssh2_uint64_t  f_flag;     /* mount flags */
     libssh2_uint64_t  f_namemax;  /* maximum filename length */
 };
It is unspecified whether all members of the returned struct have meaningful values on all file systems.
The field f_flag is a bit mask. Bits are defined as follows:
LIBSSH2_SFTP_ST_RDONLY
Read-only file system.
LIBSSH2_SFTP_ST_NOSUID
Set-user-ID/set-group-ID bits are ignored by exec(3).
RETURN VALUE
Returns 0 on success or negative on failure. If used in non-blocking mode, it returns LIBSSH2_ERROR_EAGAIN when it would otherwise block. While LIBSSH2_ERROR_EAGAIN is a negative number, it isn't really a failure per se.
ERRORS
LIBSSH2_ERROR_ALLOC -  An internal memory allocation call failed.
LIBSSH2_ERROR_SOCKET_SEND - Unable to send data on socket.
LIBSSH2_ERROR_SOCKET_TIMEOUT -
LIBSSH2_ERROR_SFTP_PROTOCOL - An invalid SFTP protocol response was received on the socket, or an SFTP operation caused an errorcode to be returned by the server.
AVAILABILITY
Added in libssh2 1.2.6
SEE ALSO
libssh2_sftp_open_ex,
This HTML page was made with roffit.
]]

function _M:statvfs(path, path_len, st)
	return prototype.libssh2_sftp_statvfs(self.sftp, path, path_len, st)
end



--[[
url: https://www.libssh2.org/libssh2_sftp_fstat_ex.html
name: libssh2_sftp_fstat_ex - get or set attributes on an SFTP file handle
description: handle - SFTP File Handle as returned by  libssh2_sftp_open_ex,
attrs - Pointer to an LIBSSH2_SFTP_ATTRIBUTES structure to set file metadata from or into depending on the value of setstat.
setstat - When non-zero, the file's metadata will be updated  with the data found in attrs according to the values of attrs->flags  and other relevant member attributes.
Get or Set statbuf type data for a given LIBSSH2_SFTP_HANDLE instance.
DATA TYPES
LIBSSH2_SFTP_ATTRIBUTES is a typedefed struct that is defined as below
struct _LIBSSH2_SFTP_ATTRIBUTES {
     /* If flags & ATTR_* bit is set, then the value in this
      * struct will be meaningful Otherwise it should be ignored
      */
     unsigned long flags;
     /* size of file, in bytes */
     libssh2_uint64_t filesize;
     /* numerical representation of the user and group owner of
      * the file
      */
     unsigned long uid, gid;
     /* bitmask of permissions */
     unsigned long permissions;
     /* access time and modified time of file */
     unsigned long atime, mtime;
 };
You will find a full set of defines and macros to identify flags and permissions on the libssh2_sftp.h header file, but some of the most common ones are:
To check for specific user permissions, the set of defines are in the pattern LIBSSH2_SFTP_S_I<action><who> where <action> is R, W or X for read, write and executable and <who> is USR, GRP and OTH for user, group and other. So, you check for a user readable file, use the bit LIBSSH2_SFTP_S_IRUSR while you want to see if it is executable for other, you use LIBSSH2_SFTP_S_IXOTH and so on.
To check for specific file types, you would previously (before libssh2 1.2.5) use the standard posix S_IS***() macros, but since 1.2.5 libssh2 offers its own set of macros for this functionality:
LIBSSH2_SFTP_S_ISLNK
Test for a symbolic link
LIBSSH2_SFTP_S_ISREG
Test for a regular file
LIBSSH2_SFTP_S_ISDIR
Test for a directory
LIBSSH2_SFTP_S_ISCHR
Test for a character special file
LIBSSH2_SFTP_S_ISBLK
Test for a block special file
LIBSSH2_SFTP_S_ISFIFO
Test for a pipe or FIFO special file
LIBSSH2_SFTP_S_ISSOCK
Test for a socket
RETURN VALUE
Return 0 on success or negative on failure.  It returns LIBSSH2_ERROR_EAGAIN when it would otherwise block. While LIBSSH2_ERROR_EAGAIN is a negative number, it isn't really a failure per se.
ERRORS
LIBSSH2_ERROR_ALLOC -  An internal memory allocation call failed.
LIBSSH2_ERROR_SOCKET_SEND - Unable to send data on socket.
LIBSSH2_ERROR_SOCKET_TIMEOUT -
LIBSSH2_ERROR_SFTP_PROTOCOL - An invalid SFTP protocol response was  received on the socket, or an SFTP operation caused an errorcode to  be returned by the server.
AVAILABILITY
This function has been around since forever, but most of the LIBSSH2_SFTP_S_* defines were introduced in libssh2 0.14 and the LIBSSH2_SFTP_S_IS***() macros were introduced in libssh2 1.2.5.
SEE ALSO
libssh2_sftp_open_ex,
This HTML page was made with roffit.
]]

function _M:fstat_ex(handle, attrs, setstat)
	return prototype.libssh2_sftp_fstat_ex(handle, attrs, setstat)
end

--[[
url: https://www.libssh2.org/libssh2_sftp_unlink_ex.html
name: libssh2_sftp_unlink_ex - unlink an SFTP file
description: sftp - SFTP instance as returned by  libssh2_sftp_init,
filename - Path and name of the existing filesystem entry
filename_len - Length of the path and name of the existing  filesystem entry
Unlink (delete) a file from the remote filesystem.
RETURN VALUE
Return 0 on success or negative on failure.  It returns LIBSSH2_ERROR_EAGAIN when it would otherwise block. While LIBSSH2_ERROR_EAGAIN is a negative number, it isn't really a failure per se.
ERRORS
LIBSSH2_ERROR_ALLOC -  An internal memory allocation call failed.
LIBSSH2_ERROR_SOCKET_SEND - Unable to send data on socket.
LIBSSH2_ERROR_SOCKET_TIMEOUT -
LIBSSH2_ERROR_SFTP_PROTOCOL - An invalid SFTP protocol response was  received on the socket, or an SFTP operation caused an errorcode to  be returned by the server.
SEE ALSO
libssh2_sftp_init,
This HTML page was made with roffit.
]]

function _M:unlink_ex(filename, filename_len)
	return prototype.libssh2_sftp_unlink_ex(self.sftp, filename, filename_len)
end

--[[
url: https://www.libssh2.org/libssh2_sftp_closedir.html
name: libssh2_sftp_closedir - convenience macro for libssh2_sftp_close_handle calls
description: This is a macro defined in a public libssh2 header file that is using the underlying function libssh2_sftp_close_handle.
RETURN VALUE
See libssh2_sftp_close_handle
ERRORS
See libssh2_sftp_close_handle
SEE ALSO
libssh2_sftp_close_handle,
This HTML page was made with roffit.
]]

function _M:closedir(handle)
	return prototype.libssh2_sftp_close_handle(handle)
end

--[[
url: https://www.libssh2.org/libssh2_sftp_readdir_ex.html
name: libssh2_sftp_readdir_ex - read directory data from an SFTP handle
description: Reads a block of data from a LIBSSH2_SFTP_HANDLE and returns file entry information for the next entry, if any.
handle - is the SFTP File Handle as returned by  libssh2_sftp_open_ex,
buffer - is a pointer to a pre-allocated buffer of at least buffer_maxlen bytes to read data into.
buffer_maxlen - is the length of buffer in bytes. If the length of the  filename is longer than the space provided by buffer_maxlen it will be  truncated to fit.
longentry - is a pointer to a pre-allocated buffer of at least longentry_maxlen bytes to read data into. The format of the `longname' field is unspecified by SFTP protocol. It MUST be suitable for use in the output of a directory listing command (in fact, the recommended operation for a directory listing command is to simply display this data).
longentry_maxlen - is the length of longentry in bytes. If the length of the full directory entry is longer than the space provided by longentry_maxlen it will be truncated to fit.
attrs - is a pointer to LIBSSH2_SFTP_ATTRIBUTES storage to populate  statbuf style data into.
RETURN VALUE
Number of bytes actually populated into buffer (not counting the terminating zero), or negative on failure.  It returns LIBSSH2_ERROR_EAGAIN when it would otherwise block. While LIBSSH2_ERROR_EAGAIN is a negative number, it isn't really a failure per se.
BUG
Passing in a too small buffer for 'buffer' or 'longentry' when receiving data only results in libssh2 1.2.7 or earlier to not copy the entire data amount, and it is not possible for the application to tell when it happens!
ERRORS
LIBSSH2_ERROR_ALLOC -  An internal memory allocation call failed.
LIBSSH2_ERROR_SOCKET_SEND - Unable to send data on socket.
LIBSSH2_ERROR_SOCKET_TIMEOUT -
LIBSSH2_ERROR_SFTP_PROTOCOL - An invalid SFTP protocol response was  received on the socket, or an SFTP operation caused an errorcode to be  returned by the server.
From 1.2.8, LIBSSH2_ERROR_BUFFER_TOO_SMALL is returned if any of the given 'buffer' or 'longentry' buffers are too small to fit the requested object name.
SEE ALSO
libssh2_sftp_open_ex, libssh2_sftp_close_handle,
This HTML page was made with roffit.
]]

function _M:readdir_ex(handle, buffer, buffer_maxlen, longentry, longentry_maxlen, attrs)
	return prototype.libssh2_sftp_readdir_ex(handle, buffer, buffer_maxlen, longentry, longentry_maxlen, attrs)
end

--[[
url: https://www.libssh2.org/libssh2_sftp_seek.html
name: libssh2_sftp_seek - set the read/write position indicator within a file
description: Deprecated function. Use libssh2_sftp_seek64 instead!
handle - SFTP File Handle as returned by  libssh2_sftp_open_ex,
offset - Number of bytes from the beginning of file to seek to.
Move the file handle's internal pointer to an arbitrary location.  Note that libssh2 implements file pointers as a localized concept to make  file access appear more POSIX like. No packets are exchanged with the server  during a seek operation. The localized file pointer is simply used as a  convenience offset during read/write operations.
SEE ALSO
libssh2_sftp_open_ex, libssh2_sftp_seek64,
This HTML page was made with roffit.
]]

function _M:seek(handle, offset)
	prototype.libssh2_sftp_seek(handle, offset)
end


--[[
url: https://www.libssh2.org/libssh2_sftp_fsetstat.html
name: libssh2_sftp_fsetstat - convenience macro for libssh2_sftp_fstat_ex calls
description: This is a macro defined in a public libssh2 header file that is using the underlying function libssh2_sftp_fstat_ex.
RETURN VALUE
See libssh2_sftp_fstat_ex
ERRORS
See libssh2_sftp_fstat_ex
SEE ALSO
libssh2_sftp_fstat_ex,
This HTML page was made with roffit.
]]

function _M:fsetstat(handle, attrs)
	return prototype.libssh2_sftp_fstat_ex(handle, attrs, 1)
end


--[[
url: https://www.libssh2.org/libssh2_sftp_open_ex.html
name: libssh2_sftp_open - open filehandle for file on SFTP.
description: sftp - SFTP instance as returned by libssh2_sftp_init
filename - Remote file/directory resource to open
filename_len - Length of filename
flags - Any reasonable combination of the LIBSSH2_FXF_* constants:
LIBSSH2_FXF_READ
Open the file for reading.
LIBSSH2_FXF_WRITE
Open the file for writing.  If both this and LIBSSH2_FXF_READ are specified, the file is opened for both reading and writing.
LIBSSH2_FXF_APPEND
Force all writes to append data at the end of the file.
LIBSSH2_FXF_CREAT,
If this flag is specified, then a new file will be created if one does not already exist (if LIBSSH2_FXF_TRUNC is specified, the new file will be truncated to zero length if it previously exists)
LIBSSH2_FXF_TRUNC
Forces an existing file with the same name to be truncated to zero length when creating a file by specifying LIBSSH2_FXF_CREAT. LIBSSH2_FXF_CREAT MUST also be specified if this flag is used.
LIBSSH2_FXF_EXCL
Causes the request to fail if the named file already exists. LIBSSH2_FXF_CREAT MUST also be specified if this flag is used.
mode - POSIX file permissions to assign if the file is being newly created. See the LIBSSH2_SFTP_S_* convenience defines in <libssh2_sftp.h>
open_type - Either of LIBSSH2_SFTP_OPENFILE (to open a file) or LIBSSH2_SFTP_OPENDIR (to open a directory).
RETURN VALUE
A pointer to the newly created LIBSSH2_SFTP_HANDLE instance or NULL on failure.
ERRORS
LIBSSH2_ERROR_ALLOC -  An internal memory allocation call failed.
LIBSSH2_ERROR_SOCKET_SEND - Unable to send data on socket.
LIBSSH2_ERROR_SOCKET_TIMEOUT -
LIBSSH2_ERROR_SFTP_PROTOCOL - An invalid SFTP protocol response was  received on the socket, or an SFTP operation caused an errorcode to be  returned by the server.
LIBSSH2_ERROR_EAGAIN - Marked for non-blocking I/O but the call would block.
SEE ALSO
libssh2_sftp_close_handle,
This HTML page was made with roffit.
]]

function _M:open_ex(filename, filename_len, flags, mode, open_type)
	return prototype.libssh2_sftp_open_ex(self.sftp, filename, filename_len, flags, mode, open_type)
end


--[[
url: https://www.libssh2.org/libssh2_sftp_rewind.html
name: libssh2_sftp_rewind - convenience macro for libssh2_sftp_seek64 calls
description: This is a macro defined in a public libssh2 header file that is using the underlying function libssh2_sftp_seek64.
RETURN VALUE
See libssh2_sftp_seek64
ERRORS
See libssh2_sftp_seek64
SEE ALSO
libssh2_sftp_seek64,
This HTML page was made with roffit.
]]

function _M:rewind(handle)
	prototype.libssh2_sftp_seek64(handle, 0)
	return 0
end


--[[
url: https://www.libssh2.org/libssh2_sftp_realpath.html
name: libssh2_sftp_realpath - convenience macro for libssh2_sftp_symlink_ex
description: This is a macro defined in a public libssh2 header file that is using the underlying function libssh2_sftp_symlink_ex.
RETURN VALUE
See libssh2_sftp_symlink_ex
ERRORS
See libssh2_sftp_symlink_ex
SEE ALSO
libssh2_sftp_symlink_ex,
This HTML page was made with roffit.
]]

--#define libssh2_sftp_realpath(sftp, path, target, maxlen)    libssh2_sftp_symlink_ex((sftp), (path), strlen(path), (target), (maxlen),                            LIBSSH2_SFTP_REALPATH)


--[[
url: https://www.libssh2.org/libssh2_sftp_rename_ex.html
name: libssh2_sftp_rename_ex - rename an SFTP file
description: sftp - SFTP instance as returned by  libssh2_sftp_init,
sourcefile - Path and name of the existing filesystem entry
sourcefile_len - Length of the path and name of the existing  filesystem entry
destfile - Path and name of the target filesystem entry
destfile_len - Length of the path and name of the target  filesystem entry
flags -  Bitmask flags made up of LIBSSH2_SFTP_RENAME_* constants.
Rename a filesystem object on the remote filesystem. The semantics of  this command typically include the ability to move a filesystem object  between folders and/or filesystem mounts. If the LIBSSH2_SFTP_RENAME_OVERWRITE  flag is not set and the destfile entry already exists, the operation  will fail. Use of the other two flags indicate a preference (but not a  requirement) for the remote end to perform an atomic rename operation  and/or using native system calls when possible.
RETURN VALUE
Return 0 on success or negative on failure.  It returns LIBSSH2_ERROR_EAGAIN when it would otherwise block. While LIBSSH2_ERROR_EAGAIN is a negative number, it isn't really a failure per se.
ERRORS
LIBSSH2_ERROR_ALLOC -  An internal memory allocation call failed.
LIBSSH2_ERROR_SOCKET_SEND - Unable to send data on socket.
LIBSSH2_ERROR_SOCKET_TIMEOUT -
LIBSSH2_ERROR_SFTP_PROTOCOL - An invalid SFTP protocol response was  received on the socket, or an SFTP operation caused an errorcode to  be returned by the server.
SEE ALSO
libssh2_sftp_init,
This HTML page was made with roffit.
]]

function _M:rename_ex(source_filename, source_filename_len, dest_filename, dest_filename_len, flags)
	return prototype.libssh2_sftp_rename_ex(self.sftp, source_filename, source_filename_len, dest_filename, dest_filename_len, flags)
end


--[[
url: https://www.libssh2.org/libssh2_sftp_setstat.html
name: libssh2_sftp_setstat - convenience macro for libssh2_sftp_stat_ex calls
description: This is a macro defined in a public libssh2 header file that is using the underlying function libssh2_sftp_stat_ex.
RETURN VALUE
See libssh2_sftp_stat_ex
ERRORS
See libssh2_sftp_stat_ex
SEE ALSO
libssh2_sftp_stat_ex,
This HTML page was made with roffit.
]]

function _M:setstat(path, attr)
	return prototype.libssh2_sftp_stat_ex(self.sftp, path, libssh2.c_strlen(path), ffi.C.LIBSSH2_SFTP_SETSTAT, attr)
end


--[[
url: https://www.libssh2.org/libssh2_sftp_opendir.html
name: libssh2_sftp_opendir - convenience macro for libssh2_sftp_open_ex calls
description: This is a macro defined in a public libssh2 header file that is using the underlying function libssh2_sftp_open_ex.
RETURN VALUE
See libssh2_sftp_open_ex
ERRORS
See libssh2_sftp_open_ex
SEE ALSO
libssh2_sftp_open_ex,
This HTML page was made with roffit.
]]

function _M:opendir(path)
	return prototype.libssh2_sftp_open_ex(self.sftp, path,libssh2.c_strlen(path), 0, 0, ffi.C.LIBSSH2_SFTP_OPENDIR)
end


--[[
url: https://www.libssh2.org/libssh2_sftp_rmdir.html
name: libssh2_sftp_rmdir - convenience macro for libssh2_sftp_rmdir_ex
description: This is a macro defined in a public libssh2 header file that is using the underlying function libssh2_sftp_rmdir_ex.
RETURN VALUE
See libssh2_sftp_rmdir_ex
ERRORS
See libssh2_sftp_rmdir_ex
SEE ALSO
libssh2_sftp_rmdir_ex,
This HTML page was made with roffit.
]]

--#define libssh2_sftp_rmdir(sftp, path)      libssh2_sftp_rmdir_ex((sftp), (path), strlen(path))


--[[
url: https://www.libssh2.org/libssh2_sftp_close.html
name: libssh2_sftp_close - convenience macro for libssh2_sftp_close_handle calls
description: This is a macro defined in a public libssh2 header file that is using the underlying function libssh2_sftp_close_handle.
RETURN VALUE
See libssh2_sftp_close_handle
ERRORS
See libssh2_sftp_close_handle
SEE ALSO
libssh2_sftp_close_handle,
This HTML page was made with roffit.
]]

function _M:close(handle)
	return prototype.libssh2_sftp_close_handle(handle)
end


--[[
url: https://www.libssh2.org/libssh2_sftp_tell64.html
name: libssh2_sftp_tell64 - get the current read/write position indicator for a file
description: handle - SFTP File Handle as returned by libssh2_sftp_open_ex
Identify the current offset of the file handle's internal pointer.
RETURN VALUE
Current offset from beginning of file in bytes.
AVAILABILITY
Added in libssh2 1.0
SEE ALSO
libssh2_sftp_open_ex, libssh2_sftp_tell,
This HTML page was made with roffit.
]]

function _M:tell64(handle)
	return prototype.libssh2_sftp_tell64(handle)
end


--[[
url: https://www.libssh2.org/libssh2_sftp_readlink.html
name: libssh2_sftp_readlink - convenience macro for libssh2_sftp_symlink_ex
description: This is a macro defined in a public libssh2 header file that is using the underlying function libssh2_sftp_symlink_ex.
RETURN VALUE
See libssh2_sftp_symlink_ex
ERRORS
See libssh2_sftp_symlink_ex
SEE ALSO
libssh2_sftp_symlink_ex,
This HTML page was made with roffit.
]]

--#define libssh2_sftp_readlink(sftp, path, target, maxlen)      libssh2_sftp_symlink_ex((sftp), (path), strlen(path), (target), (maxlen),      LIBSSH2_SFTP_READLINK)


--[[
url: https://www.libssh2.org/libssh2_sftp_mkdir_ex.html
name: libssh2_sftp_mkdir_ex - create a directory on the remote file system
description: sftp - SFTP instance as returned by  libssh2_sftp_init,
path - full path of the new directory to create. Note that the new  directory's parents must all exist prior to making this call.
path_len - length of the full path of the new directory to create.
mode - directory creation mode (e.g. 0755).
Create a directory on the remote file system.
RETURN VALUE
Return 0 on success or negative on failure. LIBSSH2_ERROR_EAGAIN when it would otherwise block. While LIBSSH2_ERROR_EAGAIN is a negative number, it isn't really a failure per se.
ERRORS
LIBSSH2_ERROR_ALLOC -  An internal memory allocation call failed.
LIBSSH2_ERROR_SOCKET_SEND - Unable to send data on socket.
LIBSSH2_ERROR_SOCKET_TIMEOUT -
LIBSSH2_ERROR_SFTP_PROTOCOL - An invalid SFTP protocol response was  received on the socket, or an SFTP operation caused an errorcode to be  returned by the server.
SEE ALSO
libssh2_sftp_open_ex,
This HTML page was made with roffit.
]]

function _M:mkdir_ex(path, path_len, mode)
	return prototype.libssh2_sftp_mkdir_ex(self.sftp, path, path_len, mode)
end


--[[
url: https://www.libssh2.org/libssh2_sftp_rmdir_ex.html
name: libssh2_sftp_rmdir_ex - remove an SFTP directory
description: Remove a directory from the remote file system.
sftp - SFTP instance as returned by  libssh2_sftp_init,
sourcefile - Full path of the existing directory to remove.
sourcefile_len - Length of the full path of the existing directory to remove.
RETURN VALUE
Return 0 on success or negative on failure.  It returns LIBSSH2_ERROR_EAGAIN when it would otherwise block. While LIBSSH2_ERROR_EAGAIN is a negative number, it isn't really a failure per se.
ERRORS
LIBSSH2_ERROR_ALLOC -  An internal memory allocation call failed.
LIBSSH2_ERROR_SOCKET_SEND - Unable to send data on socket.
LIBSSH2_ERROR_SOCKET_TIMEOUT -
LIBSSH2_ERROR_SFTP_PROTOCOL - An invalid SFTP protocol response was  received on the socket, or an SFTP operation caused an errorcode to  be returned by the server.
SEE ALSO
libssh2_sftp_init,
This HTML page was made with roffit.
]]

function _M:rmdir_ex(path, path_len)
	return prototype.libssh2_sftp_rmdir_ex(self.sftp, path, path_len)
end

--[[
url: https://www.libssh2.org/libssh2_sftp_open.html
name: libssh2_sftp_open - convenience macro for libssh2_sftp_open_ex calls
description: This is a macro defined in a public libssh2 header file that is using the underlying function libssh2_sftp_open_ex.
RETURN VALUE
See libssh2_sftp_open_ex
ERRORS
See libssh2_sftp_open_ex
SEE ALSO
libssh2_sftp_open_ex,
This HTML page was made with roffit.
]]

function _M:open(path, flags, mode)
	return prototype.libssh2_sftp_open_ex(self.sftp, path, libssh2.c_strlen(path), flags, mode, ffi.C.LIBSSH2_SFTP_OPENFILE)
end


--[[
url: https://www.libssh2.org/libssh2_sftp_stat_ex.html
name: libssh2_sftp_stat_ex - get status about an SFTP file
description: sftp - SFTP instance as returned by  libssh2_sftp_init,
path - Remote filesystem object to stat/lstat/setstat.
path_len - Length of the name of the remote filesystem object  to stat/lstat/setstat.
stat_type - One of the three constants specifying the type of  stat operation to perform:
LIBSSH2_SFTP_STAT: performs stat(2) operation LIBSSH2_SFTP_LSTAT: performs lstat(2) operation LIBSSH2_SFTP_SETSTAT: performs operation to set stat info on file
attrs - Pointer to a LIBSSH2_SFTP_ATTRIBUTES structure to set file metadata from or into depending on the value of stat_type.
Get or Set statbuf type data on a remote filesystem object. When getting statbuf data, libssh2_sftp_stat, will follow all symlinks, while  libssh2_sftp_lstat, will return data about the object encountered, even if that object  happens to be a symlink.
The LIBSSH2_SFTP_ATTRIBUTES struct looks like this:
struct LIBSSH2_SFTP_ATTRIBUTES {
     /* If flags & ATTR_* bit is set, then the value in this struct will be
      * meaningful Otherwise it should be ignored
      */
     unsigned long flags;
     libssh2_uint64_t filesize;
     unsigned long uid;
     unsigned long gid;
     unsigned long permissions;
     unsigned long atime;
     unsigned long mtime;
 };
RETURN VALUE
Returns 0 on success or negative on failure.  It returns LIBSSH2_ERROR_EAGAIN when it would otherwise block. While LIBSSH2_ERROR_EAGAIN is a negative number, it isn't really a failure per se.
ERRORS
LIBSSH2_ERROR_ALLOC -  An internal memory allocation call failed.
LIBSSH2_ERROR_SOCKET_SEND - Unable to send data on socket.
LIBSSH2_ERROR_SOCKET_TIMEOUT -
LIBSSH2_ERROR_SFTP_PROTOCOL - An invalid SFTP protocol response was  received on the socket, or an SFTP operation caused an errorcode to  be returned by the server.
SEE ALSO
libssh2_sftp_init,
This HTML page was made with roffit.
]]

function _M:stat_ex(path, path_len, stat_type, attrs)
	return prototype.libssh2_sftp_stat_ex(self.sftp, path, path_len, stat_type, attrs)
end


--[[
url: https://www.libssh2.org/libssh2_sftp_fstat.html
name: libssh2_sftp_fstat - convenience macro for libssh2_sftp_fstat_ex calls
description: This is a macro defined in a public libssh2 header file that is using the underlying function libssh2_sftp_fstat_ex.
RETURN VALUE
See libssh2_sftp_fstat_ex
ERRORS
See libssh2_sftp_fstat_ex
SEE ALSO
libssh2_sftp_fstat_ex,
This HTML page was made with roffit.
]]

function _M:fstat(handle, attrs)
	return prototype.libssh2_sftp_fstat_ex(handle, attrs, 0)
end


--[[
url: https://www.libssh2.org/libssh2_sftp_write.html
name: libssh2_sftp_write - write SFTP data
description: libssh2_sftp_write writes a block of data to the SFTP server. This method is modeled after the POSIX write() function and uses the same calling semantics.
handle - SFTP file handle as returned by libssh2_sftp_open_ex.
buffer - points to the data to send off.
count - Number of bytes from 'buffer' to write. Note that it may not be possible to write all bytes as requested.
libssh2_sftp_handle(3) will use as much as possible of the buffer and put it into a single SFTP protocol packet. This means that to get maximum performance when sending larger files, you should try to always pass in at least 32K of data to this function.
WRITE AHEAD
Starting in libssh2 version 1.2.8, the default behavior of libssh2 is to create several smaller outgoing packets for all data you pass to this function and it will return a positive number as soon as the first packet is acknowledged from the server.
This has the effect that sometimes more data has been sent off but isn't acked yet when this function returns, and when this function is subsequently called again to write more data, libssh2 will immediately figure out that the data is already received remotely.
In most normal situation this should not cause any problems, but it should be noted that if you've once called libssh2_sftp_write() with data and it returns short, you MUST still assume that the rest of the data might've been cached so you need to make sure you don't alter that data and think that the version you have in your next function invoke will be detected or used.
The reason for this funny behavior is that SFTP can only send 32K data in each packet and it gets all packets acked individually. This means we cannot use a simple serial approach if we want to reach high performance even on high latency connections. And we want that.
RETURN VALUE
Actual number of bytes written or negative on failure.
If used in non-blocking mode, it returns LIBSSH2_ERROR_EAGAIN when it would otherwise block. While LIBSSH2_ERROR_EAGAIN is a negative number, it isn't really a failure per se.
If this function returns 0 (zero) it should not be considered an error, but simply that there was no error but yet no payload data got sent to the other end.
ERRORS
LIBSSH2_ERROR_ALLOC -  An internal memory allocation call failed.
LIBSSH2_ERROR_SOCKET_SEND - Unable to send data on socket.
LIBSSH2_ERROR_SOCKET_TIMEOUT -
LIBSSH2_ERROR_SFTP_PROTOCOL - An invalid SFTP protocol response was  received on the socket, or an SFTP operation caused an errorcode to  be returned by the server.
SEE ALSO
libssh2_sftp_open_ex,
This HTML page was made with roffit.
]]

function _M:write(handle, buffer, count)
	return prototype.libssh2_sftp_write(handle, buffer, count)
end


--[[
url: https://www.libssh2.org/libssh2_sftp_symlink.html
name: libssh2_sftp_symlink - convenience macro for libssh2_sftp_symlink_ex
description: This is a macro defined in a public libssh2 header file that is using the underlying function libssh2_sftp_symlink_ex.
RETURN VALUE
See libssh2_sftp_symlink_ex
ERRORS
See libssh2_sftp_symlink_ex
SEE ALSO
libssh2_sftp_symlink_ex,
This HTML page was made with roffit.
]]

--#define libssh2_sftp_symlink(sftp, orig, linkpath)      libssh2_sftp_symlink_ex((sftp), (orig), strlen(orig), (linkpath),                              strlen(linkpath), LIBSSH2_SFTP_SYMLINK)



--[[
url: https://www.libssh2.org/libssh2_sftp_symlink_ex.html
name: libssh2_sftp_symlink_ex - read or set a symbolic link
description: Create a symlink or read out symlink information from the remote side.
sftp - SFTP instance as returned by  libssh2_sftp_init,
path - Remote filesystem object to create a symlink from or resolve.
path_len - Length of the name of the remote filesystem object to  create a symlink from or resolve.
target - a pointer to a buffer. The buffer has different uses depending what the link_type argument is set to. LIBSSH2_SFTP_SYMLINK: Remote filesystem object to link to. LIBSSH2_SFTP_READLINK: Pre-allocated buffer to resolve symlink target into. LIBSSH2_SFTP_REALPATH: Pre-allocated buffer to resolve realpath target into.
target_len - Length of the name of the remote filesystem target object.
link_type - One of the three previously mentioned constants which  determines the resulting behavior of this function.
These are convenience macros:
libssh2_sftp_symlink, : Create a symbolic link between two filesystem objects. libssh2_sftp_readlink, : Resolve a symbolic link filesystem object to its next target. libssh2_sftp_realpath, : Resolve a complex, relative, or symlinked filepath to its effective target.
RETURN VALUE
When using LIBSSH2_SFTP_SYMLINK, this function returns 0 on success or negative on failure.
When using LIBSSH2_SFTP_READLINK or LIBSSH2_SFTP_REALPATH, it returns the number of bytes it copied to the target buffer (not including the terminating zero) or negative on failure.
It returns LIBSSH2_ERROR_EAGAIN when it would otherwise block. While LIBSSH2_ERROR_EAGAIN is a negative number, it isn't really a failure per se.
From 1.2.8, LIBSSH2_ERROR_BUFFER_TOO_SMALL is returned if the given 'target' buffer is too small to fit the requested object name.
BUG
Passing in a too small buffer when receiving data only results in libssh2 1.2.7 or earlier to not copy the entire data amount, and it is not possible for the application to tell when it happens!
ERRORS
LIBSSH2_ERROR_ALLOC -  An internal memory allocation call failed.
LIBSSH2_ERROR_SOCKET_SEND - Unable to send data on socket.
LIBSSH2_ERROR_SOCKET_TIMEOUT -
LIBSSH2_ERROR_SFTP_PROTOCOL - An invalid SFTP protocol response was  received on the socket, or an SFTP operation caused an errorcode to  be returned by the server.
SEE ALSO
libssh2_sftp_init,
This HTML page was made with roffit.
]]

function _M:symlink_ex(path, path_len, target, target_len, link_type)
	return prototype.libssh2_sftp_symlink_ex(self.sftp, path, path_len, target, target_len, link_type)
end


--[[
url: https://www.libssh2.org/libssh2_sftp_close_handle.html
name: libssh2_sftp_close_handle - close filehandle
description: handle - SFTP File Handle as returned by libssh2_sftp_open_ex or libssh2_sftp_opendir (which is a macro).
Close an active LIBSSH2_SFTP_HANDLE. Because files and directories share the same underlying storage mechanism these methods may be used interchangeably. libssh2_sftp_close and libssh2_sftp_closedir are macros for libssh2_sftp_close_handle.
RETURN VALUE
Return 0 on success or negative on failure.  It returns LIBSSH2_ERROR_EAGAIN when it would otherwise block. While LIBSSH2_ERROR_EAGAIN is a negative number, it isn't really a failure per se.
ERRORS
LIBSSH2_ERROR_ALLOC -  An internal memory allocation call failed.
LIBSSH2_ERROR_SOCKET_SEND - Unable to send data on socket.
LIBSSH2_ERROR_SOCKET_TIMEOUT -
LIBSSH2_ERROR_SFTP_PROTOCOL - An invalid SFTP protocol response was  received on the socket, or an SFTP operation caused an errorcode to  be returned by the server.
SEE ALSO
libssh2_sftp_open_ex,
This HTML page was made with roffit.
]]

function _M:close_handle(handle)
	return prototype.libssh2_sftp_close_handle(handle)
end


--[[
url: https://www.libssh2.org/libssh2_sftp_shutdown.html
name: libssh2_sftp_shutdown - shut down an SFTP session
description: sftp - SFTP instance as returned by  libssh2_sftp_init,
Destroys a previously initialized SFTP session and frees all resources  associated with it.
RETURN VALUE
Return 0 on success or negative on failure.  It returns LIBSSH2_ERROR_EAGAIN when it would otherwise block. While LIBSSH2_ERROR_EAGAIN is a negative number, it isn't really a failure per se.
SEE ALSO
libssh2_sftp_init,
This HTML page was made with roffit.
]]

function _M:shutdown()
	return prototype.libssh2_sftp_shutdown(self.sftp)
end


--[[
url: https://www.libssh2.org/libssh2_sftp_tell.html
name: libssh2_sftp_tell - get the current read/write position indicator for a file
description: handle - SFTP File Handle as returned by libssh2_sftp_open_ex.
Returns the current offset of the file handle's internal pointer. Note that this is now deprecated. Use the newer libssh2_sftp_tell64 instead!
RETURN VALUE
Current offset from beginning of file in bytes.
SEE ALSO
libssh2_sftp_open_ex, libssh2_sftp_tell64,
This HTML page was made with roffit.
]]

function _M:tell(handle)
	return prototype.libssh2_sftp_tell(handle)
end


--[[
url: https://www.libssh2.org/libssh2_sftp_unlink.html
name: libssh2_sftp_unlink - convenience macro for libssh2_sftp_unlink_ex calls
description: This is a macro defined in a public libssh2 header file that is using the underlying function libssh2_sftp_unlink_ex.
RETURN VALUE
See libssh2_sftp_unlink_ex
ERRORS
See libssh2_sftp_unlink_ex
SEE ALSO
libssh2_sftp_unlink_ex,
This HTML page was made with roffit.
]]

function _M:unlink(filename)
	return prototype.libssh2_sftp_unlink_ex(self.sftp, filename,libssh2.c_strlen(filename))
end


--[[
url: https://www.libssh2.org/libssh2_sftp_readdir.html
name: libssh2_sftp_readdir - convenience macro for libssh2_sftp_readdir_ex calls
description: This is a macro defined in a public libssh2 header file that is using the underlying function libssh2_sftp_readdir_ex.
RETURN VALUE
See libssh2_sftp_readdir_ex
ERRORS
See libssh2_sftp_readdir_ex
SEE ALSO
libssh2_sftp_readdir_ex,
This HTML page was made with roffit.
]]

function _M:readdir(handle, buffer, buffer_maxlen, attrs)
	return prototype.libssh2_sftp_readdir_ex(handle, buffer, buffer_maxlen, nil, 0, attrs)
end


--[[
url: https://www.libssh2.org/libssh2_sftp_read.html
name: libssh2_sftp_read - read data from an SFTP handle
description: handle is the SFTP File Handle as returned by  libssh2_sftp_open_ex,
buffer is a pointer to a pre-allocated buffer of at least
buffer_maxlen bytes to read data into.
Reads a block of data from an LIBSSH2_SFTP_HANDLE. This method is modelled after the POSIX  read(2) function and uses the same calling semantics.  libssh2_sftp_read, will attempt to read as much as possible however it may not fill all of buffer if the file pointer reaches the end or if further reads would cause the socket to block.
RETURN VALUE
Number of bytes actually populated into buffer, or negative on failure.   It returns LIBSSH2_ERROR_EAGAIN when it would otherwise block. While LIBSSH2_ERROR_EAGAIN is a negative number, it isn't really a failure per se.
ERRORS
LIBSSH2_ERROR_ALLOC -  An internal memory allocation call failed.
LIBSSH2_ERROR_SOCKET_SEND - Unable to send data on socket.
LIBSSH2_ERROR_SOCKET_TIMEOUT -
LIBSSH2_ERROR_SFTP_PROTOCOL - An invalid SFTP protocol response was received on the socket, or an SFTP operation caused an errorcode to be returned by the server.
SEE ALSO
libssh2_sftp_open_ex, libssh2_sftp_read,
This HTML page was made with roffit.
]]

function _M:read(handle, buffer, buffer_maxlen)
	return prototype.libssh2_sftp_read(handle, buffer, buffer_maxlen)
end


--[[
url: https://www.libssh2.org/libssh2_sftp_fstatvfs.html
name: nil
description:
]]

function _M:fstatvfs(handle, st)
	return prototype.libssh2_sftp_fstatvfs(handle, st)
end


--[[
url: https://www.libssh2.org/libssh2_sftp_seek64.html
name: libssh2_sftp_seek64 - set the read/write position within a file
description: handle - SFTP File Handle as returned by  libssh2_sftp_open_ex,
offset - Number of bytes from the beginning of file to seek to.
Move the file handle's internal pointer to an arbitrary location. libssh2 implements file pointers as a localized concept to make file access appear more POSIX like. No packets are exchanged with the server during a seek operation. The localized file pointer is simply used as a convenience offset during read/write operations.
You MUST NOT seek during writing or reading a file with SFTP, as the internals use outstanding packets and changing the "file position" during transit will results in badness.
AVAILABILITY
Added in 1.0
SEE ALSO
libssh2_sftp_open_ex,
This HTML page was made with roffit.
]]

function _M:seek64(handle, offset)
	prototype.libssh2_sftp_seek64(handle, offset)
end


--[[
url: https://www.libssh2.org/libssh2_sftp_fsync.html
name: libssh2_sftp_fsync - synchronize file to disk
description: This function causes the remote server to synchronize the file data and metadata to disk (like fsync(2)).
For this to work requires fsync@openssh.com support on the server.
handle - SFTP File Handle as returned by libssh2_sftp_open_ex,
RETURN VALUE
Returns 0 on success or negative on failure. If used in non-blocking mode, it returns LIBSSH2_ERROR_EAGAIN when it would otherwise block. While LIBSSH2_ERROR_EAGAIN is a negative number, it isn't really a failure per se.
ERRORS
LIBSSH2_ERROR_ALLOC -  An internal memory allocation call failed.
LIBSSH2_ERROR_SOCKET_SEND - Unable to send data on socket.
LIBSSH2_ERROR_SFTP_PROTOCOL - An invalid SFTP protocol response was received on the socket, or an SFTP operation caused an errorcode to be returned by the server.  In particular, this can be returned if the SSH server does not support the fsync operation: the SFTP subcode LIBSSH2_FX_OP_UNSUPPORTED will be returned in this case.
AVAILABILITY
Added in libssh2 1.4.4 and OpenSSH 6.3.
SEE ALSO
fsync(2)
This HTML page was made with roffit.
]]

function _M:fsync(handle)
	return prototype.libssh2_sftp_fsync(handle)
end


return _M