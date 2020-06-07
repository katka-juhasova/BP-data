
return {
	SSH_FX_OK = 0,
	SSH_FX_EOF = 1,
	SSH_FX_NO_SUCH_FILE = 2,
	SSH_FX_PERMISSION_DENIED = 3,
	SSH_FX_FAILURE = 4,
	SSH_FX_BAD_MESSAGE = 5,
	SSH_FX_NO_CONNECTION = 6,
	SSH_FX_CONNECTION_LOST = 7,
	SSH_FX_OP_UNSUPPORTED = 8,
	SSH_FX_INVALID_HANDLE = 9,
	SSH_FX_NO_SUCH_PATH = 10,
	SSH_FX_FILE_ALREADY_EXISTS = 11,
	SSH_FX_WRITE_PROTECT = 12,
	SSH_FX_NO_MEDIA = 13,
	SSH_OK   = 0, -- No error */
	SSH_ERROR   = -1, -- Error of some kind */
	SSH_AGAIN   = -2, -- The nonblocking call must be repeated */
	SSH_EOF   = -127, -- We have already a eof */

	-- enum ssh_auth_e
	SSH_AUTH_SUCCESS = 0,
	SSH_AUTH_DENIED = 1,
	SSH_AUTH_PARTIAL = 2,
	SSH_AUTH_INFO = 3,
	SSH_AUTH_AGAIN = 4,
	SSH_AUTH_ERROR = -1,

	-- enum ssh_server_known_e
	SSH_SERVER_ERROR = -1,
	SSH_SERVER_NOT_KNOWN = 0,
	SSH_SERVER_KNOWN_OK = 1,
	SSH_SERVER_KNOWN_CHANGED = 2,
	SSH_SERVER_FOUND_OTHER = 3,
	SSH_SERVER_FILE_NOT_FOUND = 4,

	O_RDONLY	= 0x0000,--		/* open for reading only */
	O_WRONLY	= 0x0001,--		/* open for writing only */
	O_RDWR		= 0x0002,--		/* open for reading and writing */
	O_ACCMODE	= 0x0003,--		/* mask for above modes */

	O_CREAT		= 0x0200,--		/* create if nonexistant */
	O_TRUNC		= 0x0400,--		/* truncate to zero length */
	O_EXCL		= 0x0800,--		/* error if already exists */

	S_ISUID	= 0004000,--	set-user-ID bit
	S_ISGID	= 0002000,--	set-group-ID bit (下記参照)
	S_ISVTX	= 0001000,--	スティッキービット (下記参照)

	S_IRWXU	= 00700,--	ファイル所有者のアクセス許可用のビットマスク
	S_IRUSR	= 00400,--	所有者の読み込み許可
	S_IWUSR	= 00200,--	所有者の書き込み許可
	S_IXUSR	= 00100,--	所有者の実行許可

	S_IRWXG	= 00070,--	グループのアクセス許可用のビットマスク
	S_IRGRP	= 00040,--	グループの読み込み許可
	S_IWGRP	= 00020,--	グループの書き込み許可
	S_IXGRP	= 00010,--	グループの実行許可

	S_IRWXO	= 00007,--	他人 (others) のアクセス許可用のビットマスク
	S_IROTH	= 00004,--	他人の読み込み許可
	S_IWOTH	= 00002,--	他人の書き込み許可
	S_IXOTH	= 00001,--	他人の実行許可
}