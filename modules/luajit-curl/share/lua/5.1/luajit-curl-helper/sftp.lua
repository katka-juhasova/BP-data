local ffi = require "ffi"
local curl = require "luajit-curl"
local ffi_c = ffi.C

local _M = {}
_M.__index = _M

ffi.cdef([[
enum {
	/* CURLPROTO_ defines are for the CURLOPT_*PROTOCOLS options */
	CURLPROTO_HTTP   = (1<<0),
	CURLPROTO_HTTPS  = (1<<1),
	CURLPROTO_FTP    = (1<<2),
	CURLPROTO_FTPS   = (1<<3),
	CURLPROTO_SCP    = (1<<4),
	CURLPROTO_SFTP   = (1<<5),
	CURLPROTO_TELNET = (1<<6),
	CURLPROTO_LDAP   = (1<<7),
	CURLPROTO_LDAPS  = (1<<8),
	CURLPROTO_DICT   = (1<<9),
	CURLPROTO_FILE   = (1<<10),
	CURLPROTO_TFTP   = (1<<11),
	CURLPROTO_IMAP   = (1<<12),
	CURLPROTO_IMAPS  = (1<<13),
	CURLPROTO_POP3   = (1<<14),
	CURLPROTO_POP3S  = (1<<15),
	CURLPROTO_SMTP   = (1<<16),
	CURLPROTO_SMTPS  = (1<<17),
	CURLPROTO_RTSP   = (1<<18),
	CURLPROTO_RTMP   = (1<<19),
	CURLPROTO_RTMPT  = (1<<20),
	CURLPROTO_RTMPE  = (1<<21),
	CURLPROTO_RTMPTE = (1<<22),
	CURLPROTO_RTMPS  = (1<<23),
	CURLPROTO_RTMPTS = (1<<24),
	CURLPROTO_GOPHER = (1<<25),
	CURLPROTO_SMB    = (1<<26),
	CURLPROTO_SMBS   = (1<<27),
	CURLPROTO_ALL    = (~0), /* enable everything */
};

enum {
	CURLAUTH_NONE         = ((unsigned long)0),
	CURLAUTH_BASIC        = (((unsigned long)1)<<0),
	CURLAUTH_DIGEST       = (((unsigned long)1)<<1),
	CURLAUTH_NEGOTIATE    = (((unsigned long)1)<<2),
	/* Deprecated since the advent of CURLAUTH_NEGOTIATE */
	CURLAUTH_GSSNEGOTIATE = (((unsigned long)1)<<2),
	CURLAUTH_NTLM         = (((unsigned long)1)<<3),
	CURLAUTH_DIGEST_IE    = (((unsigned long)1)<<4),
	CURLAUTH_NTLM_WB      = (((unsigned long)1)<<5),
	CURLAUTH_ONLY         = (((unsigned long)1)<<31),
	CURLAUTH_ANY          = (~(((unsigned long)1)<<4)),
	CURLAUTH_ANYSAFE      = (~((((unsigned long)1)<<0)|(((unsigned long)1)<<4))),
};

enum {
	CURLSSH_AUTH_ANY       = ~0,     /* all types supported by the server */
	CURLSSH_AUTH_NONE      = 0,      /* none allowed, silly but complete */
	CURLSSH_AUTH_PUBLICKEY = (1<<0), /* public/private key files */
	CURLSSH_AUTH_PASSWORD  = (1<<1), /* password */
	CURLSSH_AUTH_HOST      = (1<<2), /* host key files */
	CURLSSH_AUTH_KEYBOARD  = (1<<3), /* keyboard interactive */
	CURLSSH_AUTH_AGENT     = (1<<4), /* agent (ssh-agent, pageant...) */
	CURLSSH_AUTH_DEFAULT = ~0,
};

enum {
	CURL_READFUNC_ABORT = 0x10000000
};
]])

ffi.cdef([[
typedef void* FILE;
FILE *fopen(const char *filename, const char *mode);
int fclose(FILE *stream);
int ferror(FILE *stream);
size_t fread(void *buf, size_t size, size_t n, FILE *fp);
size_t fwrite(const void * restrict ptr, size_t size, size_t nmemb, FILE * restrict stream);
int fseek(FILE *stream, long offset, int origin);
long ftell(FILE *stream);
]])

ffi.cdef([[
struct FtpFile {
	const char *filename;
	FILE *stream;
};
]])

-- (void *buffer, size_t size, size_t nmemb, void *stream)
function filewrite_cb(buffer, size, nmemb, stream)
	local out = ffi.cast("struct FtpFile*", stream) -- (struct FtpFile *)stream;

	if out.stream == nil then
		out.stream = ffi_c.fopen(out.filename, "wb")
		if out.stream == nil then
			return -1; --/* failure, can't open file to write */
		end
	end
	return ffi_c.fwrite(buffer, size, nmemb, out.stream)
end

-- (void *ptr, size_t size, size_t nmemb, void *stream)
function fileread_cb(ptr, size, nmemb, stream)
	local fp = ffi.cast("FILE*", stream) --(FILE *)stream

	if tonumber(ffi_c.ferror(fp)) ~= 0 then
		return curl.CURL_READFUNC_ABORT
	end

	local n = ffi_c.fread(ptr, size, nmemb, stream) * size
	return n
end

function writememory_cb(ptr, size, nmemb, stream)
	local bytes = size * nmemb
	local dst = ffi.new("char[?]", size * nmemb)
	ffi.copy(dst, ptr, size * nmemb)
	table.insert(_M._memory, ffi.string(dst, size * nmemb))
	return bytes
end

function setCurlOpt(self, mode, opt)
	local ret = false
	local text = nil

	local curl_handle = curl.curl_easy_init();

	--curl.curl_easy_setopt(curl_handle, curl.CURLOPT_VERBOSE, true)

	if _M.filewrite_cb == nil then
		_M.filewrite_cb = ffi.cast("curl_callback", filewrite_cb)
	end

	if _M.file_read_cb == nil  then
		_M.file_read_cb = ffi.cast("curl_callback", fileread_cb)
	end

	if _M.writememory_cb == nil  then
		_M.writememory_cb = ffi.cast("curl_callback", writememory_cb)
	end

	local password_auth = ""

	if self._opt.public_key ~= nil or self._opt.private_key ~= nil then
		curl.curl_easy_setopt(curl_handle, curl.CURLOPT_HTTPAUTH, curl.CURLSSH_AUTH_PUBLICKEY)
		password_auth = self._opt.username .. "@"
	elseif self._opt.password ~= nil then
		curl.curl_easy_setopt(curl_handle, curl.CURLOPT_HTTPAUTH, curl.CURLSSH_AUTH_PASSWORD)
		password_auth = self._opt.username .. ":"..self._opt.password .. "@"
	else
		--assert()
	end

	if self._opt.private_key ~= nil then
		curl.curl_easy_setopt(curl_handle, curl.CURLOPT_SSH_PUBLIC_KEYFILE, self._opt.private_key)
	end
	if self._opt.private_key_password ~= nil then
		curl.curl_easy_setopt(curl_handle, curl.CURLOPT_KEYPASSWD, self._opt.private_key_password)
	end
	if self._opt.public_key ~= nil then
		curl.curl_easy_setopt(curl_handle, curl.CURLOPT_SSH_PRIVATE_KEYFILE, self._opt.public_key)
	end

	local destruct = nil
	local quote_list = {}

	if mode == "upload" then
		local url = "sftp://" .. password_auth .. self._opt.remote_addr .. ":" .. self._opt.port .. "/" .. opt.remote_dir

		curl.curl_easy_setopt(curl_handle, curl.CURLOPT_URL, url)
		curl.curl_easy_setopt(curl_handle, curl.CURLOPT_UPLOAD, true);

		local fp = ffi_c.fopen(opt.target_file_dir, 'rb');
		if fp ~= nil then
			curl.curl_easy_setopt(curl_handle, curl.CURLOPT_READFUNCTION, _M.file_read_cb);
			curl.curl_easy_setopt(curl_handle, curl.CURLOPT_READDATA, fp);

			destruct = function()
				ffi_c.fclose(fp)
			end
		end
	elseif mode == "download" then
		local url = "sftp://" .. password_auth .. self._opt.remote_addr .. ":" .. self._opt.port .. "/" .. opt.remote_dir

		local ftpfile = ffi.new("struct FtpFile", {opt.target_file_dir, nil})

		curl.curl_easy_setopt(curl_handle, curl.CURLOPT_URL, url)
		curl.curl_easy_setopt(curl_handle, curl.CURLOPT_WRITEFUNCTION, _M.filewrite_cb)
		curl.curl_easy_setopt(curl_handle, curl.CURLOPT_WRITEDATA, ftpfile);

		destruct = function()
			if ftpfile.stream ~= nil then
				ffi_c.fclose(ftpfile.stream)
			end
		end
	elseif mode == "remove" then
		local url = "sftp://" .. password_auth .. self._opt.remote_addr .. ":" .. self._opt.port .. "/" .. opt.remote_dir

		self:log("URL", url)
		curl.curl_easy_setopt(curl_handle, curl.CURLOPT_URL, url)

		local command = "rm " .. opt.remote_dir

		self:log("command", command)

		table.insert(quote_list, command)
	elseif mode == "rename" then
		local url = "sftp://" .. password_auth .. self._opt.remote_addr .. ":" .. self._opt.port .. "/" .. opt.remote_dir

		self:log("URL", url)
		curl.curl_easy_setopt(curl_handle, curl.CURLOPT_URL, url)

		local command = "rename " .. opt.remote_dir .. " " .. opt.name

		self:log("command", command)

		table.insert(quote_list, command)
	elseif mode == "dir" then
		local url = "sftp://" .. password_auth .. self._opt.remote_addr .. ":" .. self._opt.port .. "/" .. opt.remote_dir

		self:log("URL", url)
		curl.curl_easy_setopt(curl_handle, curl.CURLOPT_URL, url)

		local command = "pwd"

		self:log("command", command)

		table.insert(quote_list, command)

		curl.curl_easy_setopt(curl_handle, curl.CURLOPT_WRITEFUNCTION, _M.writememory_cb)

		_M._memory = {}
	end


	local list = nil

	if #quote_list > 0 then
		list = ffi.new("struct curl_slist *")
		for i=1, #quote_list do
			list = curl.curl_slist_append(list, quote_list[i])
		end

		curl.curl_easy_setopt(curl_handle, curl.CURLOPT_POSTQUOTE, list)
	end

	for k, v in pairs(self._opt.external_opt) do
		curl.curl_easy_setopt(curl_handle, k, v)
	end

	local success, err = pcall(function()
		self:log("perform")
		return curl.curl_easy_perform(curl_handle)
	end)

	if #quote_list > 0 then
		curl.curl_slist_free_all(list)
	end

	local result = tonumber(err)

	ret = result == curl.CURLE_OK

	if not ret then
		self._error = ffi.string(curl.curl_easy_strerror(result))
	end

	curl.curl_easy_cleanup(curl_handle);

	if destruct then
		destruct()
	end

	if mode == "dir" then
		text = table.concat(_M._memory)
	end

	return ret, text
end

---
-- @brief インスタンス化を行う
-- @param opt table
-- @param opt.remote_addr 接続先リモートアドレス
-- @param opt.username ログインユーザー名
-- @param opt.password パスワード認証用パスワード
-- @param opt.private_key 秘密鍵へのパス
-- @param opt.private_key_password 秘密鍵パスワード
-- @param opt.public_key 公開鍵へのパス
-- @return table インスタンス
--
function _M.init(opt)
	local self = setmetatable({}, _M)

	self._opt = opt or {}

	assert(type(self._opt.remote_addr) == "string")
	assert(type(self._opt.username) == "string")

	if self._opt.private_key ~= nil then
		assert(type(self._opt.private_key) == "string")
	end
	if self._opt.private_key_password ~= nil then
		assert(type(self._opt.private_key_password) == "string")
	end
	if self._opt.public_key ~= nil then
		assert(type(self._opt.public_key) == "string")
	end
	if self._opt.password ~= nil then
		assert(type(self._opt.password) == "string")
	end

	self._opt.port = self._opt.port or 22

	self._opt.external_opt = {}

	curl.curl_global_init(curl.CURL_GLOBAL_DEFAULT)

	return self
end

---
-- @brief インスタンスの開放
--
function _M:close()
	curl.curl_global_cleanup()
end

---
-- @brief ファイルをアップロードする
-- @param remote_dir アップロード先リモートディレクトリ
-- @param target_file_dir アップロード対象ローカルファイルディレクトリ
-- @param boolean 成否
--
function _M:upload(remote_dir, target_file_dir)
	assert(type(remote_dir) == "string")
	assert(type(target_file_dir) == "string")

	return setCurlOpt(self, "upload", {remote_dir = remote_dir, target_file_dir = target_file_dir})
end

---
-- @brief ファイルをダウンロードする
-- @param remote_dir ダウンロード元リモートディレクトリ
-- @param target_file_dir ダウンロード先ローカルファイルディレクトリ
-- @param boolean 成否
--
function _M:download(remote_dir, target_file_dir)
	assert(type(remote_dir) == "string")
	assert(type(target_file_dir) == "string")

	return setCurlOpt(self, "download", {remote_dir = remote_dir, target_file_dir = target_file_dir})
end

---
-- @brief ファイルを削除する
-- @param remote_dir 削除元リモートディレクトリ
-- @param boolean 成否
--
function _M:remove(remote_dir)
	assert(type(remote_dir) == "string")

	return setCurlOpt(self, "remove", {remote_dir = remote_dir})
end

---
-- @brief ファイルをリネームする
-- @param remote_dir リネーム元リモートディレクトリ
-- @param name リネーム後ディレクトリ|ファイル
-- @param boolean 成否
--
function _M:rename(remote_dir, name)
	assert(type(remote_dir) == "string")
	assert(type(name) == "string")

	return setCurlOpt(self, "rename", {remote_dir = remote_dir, name = name})
end

---
-- @brief 指定ディレクトリ内容を列挙する
-- @param remote_dir リモートディレクトリ
-- @param boolean 成否
-- @param string ディレクトリ内容
--
function _M:dir(remote_dir)
	assert(type(remote_dir) == "string")

	return setCurlOpt(self, "dir", {remote_dir = remote_dir})
end

---
-- @brief curlエラーを取得する
-- @return string
--
function _M:lastError()
	return self._error
end

---
-- @brief curlオプションを追加する
-- @param option curlオプション
-- @param paramater 値
--
function _M:SetOpt(option, paramater)
	self._opt.external_opt[option] = paramater
end

---
--
--
function _M:log(...)
	if self._opt.log_enable then
		print(...)
	end
end

return _M