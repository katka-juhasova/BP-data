local ffi = require "ffi"

local libssh = require "libssh.libssh"
local types = require "libssh.types"
local bit32 = require "bit32"
local class = require "pl.class"
local path = require "pl.path"

local function int_to_num(i)
   return ffi.new("int[1]", i)
end

--- 指定ファイルを*バイトまでに抑えて取得する
--
local function getFileSliced(file_path, buffer_size, offset, file_size)
	local buffer = {}

	local s = {
		SEEK_SET = 0,
		SEEK_CUR = 1,
		SEEK_END = 2,
	}

	local f = ffi.C.fopen(file_path, "rb")
	ffi.C.fseek(f, offset, s.SEEK_SET)
	while true do
		local byte = ffi.new("char[1]")
		ffi.C.fread(ffi.cast("void*", byte), 1, 1, f)
		buffer[#buffer + 1] = byte[0]

		if #buffer >= buffer_size then break end
		local tell = tonumber(ffi.C.ftell(f))
		if tell >= file_size then break end
	end
	ffi.C.fclose(f)
	return buffer, #buffer
end

class.sftp {

	_session = nil,

	_sftp_session = nil,

	_version = "0.4-1",

	_download_buffer_size = 1024 * 1024,
	_upload_buffer_size = 1024 * 1024,

	---
	--
	_init = function(self)
		local err = nil
		self._session, err = libssh.ssh_new()
		assert(self._session, "ssh_new : " .. (err or "nil"));
	end;

	---
	--
	__tostring = function(self)
		return "libssh " .. self._version
	end;

	---
	--
	libssh = function(self)
		return self.libssh
	end;

	---
	--
	authentication = function(self, password, private_key)
		assert(self ~= nil)
		assert(self._session ~= nil, "Session shouldn't be nil")
		assert(libssh.ssh_connect(self._session) == types.SSH_AUTH_SUCCESS, "Unable to connect")

		local auth_status = types.SSH_AUTH_ERROR

		if password ~= nil then
			auth_status = libssh.ssh_userauth_password(self._session, nil, password)
		elseif private_key ~= nil then
			auth_status = libssh.ssh_userauth_privatekey_file(self._session, nil, private_key, nil)
		end

		if auth_status == types.SSH_AUTH_SUCCESS or auth_status == types.SSH_AUTH_PARTIAL then
			-- ok
			return true, nil
		else
			return false, self:getError()
		end
	end;

	---
	--
	openSftp = function(self)
		assert(self ~= nil)
		assert(self._session ~= nil, "Session shouldn't be nil")

		self._sftp_session = libssh.sftp_new(self._session)
		if self._sftp_session == nil then
			return false, self:getError()
		end

		local rc = libssh.sftp_init(self._sftp_session)
		if rc ~= types.SSH_OK then
			self:close()
			return false, self:getError()
		end
		return true, nil
	end;

	---
	--
	closeSftp = function(self)
		assert(self ~= nil)

		if self._sftp_session ~= nil then
			libssh.sftp_free(self._sftp_session)
			self._sftp_session = nil
		end
	end;

	---
	--
	close = function(self)
		assert(self ~= nil)

		if self._session ~= nil then
			if libssh.ssh_is_connected(self._session) then
				libssh.ssh_disconnect(self._session)
			end
			libssh.ssh_free(self._session)
			self._session = nil
		end
	end;

	---
	--
	ssh_is_server_known = function(self)
		assert(self ~= nil)
		assert(self._session ~= nil, "Session shouldn't be nil")
		libssh.ssh_is_server_known(self._session)
	end;

	---
	--
	getError = function(self)
		assert(self ~= nil)
		assert(self._session ~= nil, "Session shouldn't be nil")
		return ffi.string(libssh.ssh_get_error(self._session))
	end;

	--- Executing a remote command
	--
	commandExcec = function (self, command)
		assert(self ~= nil)
		assert(self._session ~= nil, "Session shouldn't be nil")
		assert(type(command) == "string", "command must be string")

		channel = libssh.ssh_channel_new(self._session)
		if channel == nil then
			return false, self:getError()
		end

		local rc = libssh.ssh_channel_open_session(channel)
		if rc ~= types.SSH_OK then
			self:close()
			return false, self:getError()
		end

		if libssh.ssh_channel_request_exec(channel, command) ~= types.SSH_OK then
			libssh.ssh_channel_close(channel)
			libssh.ssh_channel_free(channel)
			return false, self:getError()
		end

		local ret = ""
		local buffer = ffi.new("char[256]")
		local nbytes = libssh.ssh_channel_read(channel, ffi.cast("void*", buffer), 256, 0);
		while nbytes > 0 do
			ret = ret .. ffi.string(buffer)
			nbytes = libssh.ssh_channel_read(channel, ffi.cast("void*", buffer), 256, 0);
		end

		if nbytes < 0 then
			libssh.ssh_channel_close(channel)
			libssh.ssh_channel_free(channel)
			return false, self:getError()
		end

		libssh.ssh_channel_close(channel)
		libssh.ssh_channel_send_eof(channel)
		libssh.ssh_channel_free(channel)

		return ret, nil
	end;

	--- set ssh option
	--
	setOption = function (self, option, value)
		assert(self ~= nil)
		assert(self._session ~= nil, "Session shouldn't be nil")
		if option == "host" then
			assert(type(value) == "string", "host must be string")
			return (libssh.ssh_options_set(self._session, 0, value) >= 0)
		elseif option == "port" then
			assert(type(value) == "number", "port must be integer")
			return (libssh.ssh_options_set(self._session, 1, int_to_num(value)) >= 0)
		elseif option == "user" then
			assert(type(value) == "string", "user must be string")
			return (libssh.ssh_options_set(self._session, 4, value) >= 0)
		elseif option == "ssh_dir" then
			assert(type(value) == "string", "ssh_dir must be string")
			return (libssh.ssh_options_set(self._session, 5, value) >= 0)
		elseif option == "identity" then
			assert(type(value) == "string", "identity must be string")
			return (libssh.ssh_options_set(self._session, 6, value) >= 0)
		elseif option == "known_hosts" then
			assert(type(value) == "string", "known_hosts must be string")
			return (libssh.ssh_options_set(self._session, 8, value) >= 0)
		elseif option == "timeout" then
			assert(type(value) == "number", "Timeout must be number")
			return (libssh.ssh_options_set(self._session, 9, int_to_num(value)) >= 0)
		elseif option == "ssh1" then
			assert(type(value) == "boolean", "ssh1 must be boolean")
			return (libssh.ssh_options_set(self._session, 11, int_to_num(value and 1 or 0)) >= 0)
		elseif option == "ssh2" then
			assert(type(value) == "boolean", "ssh2 must be boolean")
			return (libssh.ssh_options_set(self._session, 12, int_to_num(value and 1 or 0)) >= 0)
		else
			return nil, "Not implemented"
		end
		return nil, "Unknown option"
	end;

	--- enumeration directoris
	--
	directoryEnumeration = function (self, target_dir)
		assert(self ~= nil)
		assert(self._session ~= nil, "Session shouldn't be nil")

		local dir = libssh.sftp_opendir(self._sftp_session, target_dir)
		if not dir then
			return nil, self:getError()
		end

		local list = {}
		local attributes = nil

		repeat
			attributes = libssh.sftp_readdir(self._sftp_session, dir)
			if attributes ~= nil then
				local tmp = {
					name = ffi.string(attributes.name),
					longname = ffi.string(attributes.longname),
					flags = tonumber(attributes.flags),
					type = tonumber(attributes.type),
					size = tonumber(attributes.size),
					uid = tonumber(attributes.uid),
					gid = tonumber(attributes.gid),
					owner = ffi.string(attributes.owner),
					group = ffi.string(attributes.group),
					permissions = tonumber(attributes.permissions),
					atime64 = tonumber(attributes.atime64),
					atime = tonumber(attributes.atime),
					atime_nseconds = tonumber(attributes.atime_nseconds),
					createtime = tonumber(attributes.createtime),
					createtime_nseconds = tonumber(attributes.createtime_nseconds),
					mtime64 = tonumber(attributes.mtime64),
					mtime = tonumber(attributes.mtime),
					mtime_nseconds = tonumber(attributes.mtime_nseconds),
				}
				table.insert(list, tmp)
				libssh.sftp_attributes_free(attributes);
			end
		until attributes == nil

		if not libssh.sftp_dir_eof(dir) then
			libssh.sftp_closedir(dir)
			return nil, self:getError()
		end

		local rc = libssh.sftp_closedir(dir)
		if rc ~= types.SSH_OK then
			return nil, self:getError()
		end

		return list, nil
	end;

	--- file upload
	--
	fileUpload = function (self, remote_file_path, local_file_path, access_type, perm)
		assert(self ~= nil)
		assert(self._sftp_session ~= nil, "SftpSession shouldn't be nil")
		assert(type(remote_file_path) == "string", "remote_file_path must be string")
		assert(type(local_file_path) == "string", "local_file_path must be string")

		if access_type == nil then
			--types.O_WRONLY | types.O_CREAT | types.O_TRUNC
			access_type = bit32.bor(0, types.O_WRONLY)
			access_type = bit32.bor(access_type, types.O_CREAT)
			access_type = bit32.bor(access_type, types.O_TRUNC)
		end

		if perm == nil then
			perm = types.S_IRWXU
		end

		local file = libssh.sftp_open(self._sftp_session, remote_file_path, access_type, perm)
		if file == nil then
			return false, self:getError()
		end

		local file_size = path.getsize(local_file_path)

		local last_per = -1
		local temporary_buffer_size = self._upload_buffer_size --- Temporary buffer
		local offset = 0
		while true do
			local buffer, length = getFileSliced(local_file_path, temporary_buffer_size, offset, file_size)

			local tmp = ffi.new("char[" .. length .. "]", buffer)

			local nwritten = libssh.sftp_write(file, ffi.cast("void*", tmp), length)
			if nwritten ~= length then
				return false, self:getError()
			end

			offset = offset + length

			--[[
			local per = math.floor((offset / file_size) * 100)
			if per ~= last_per then
				last_per = per
				print(per .. "%完了")
			end
			]]

			if offset >= file_size then break end
		end

		local rc = libssh.sftp_close(file)
		if rc ~= types.SSH_OK then
			return false, self:getError()
		end

		return true, nil
	end;

	--- file download
	--
	fileDownload = function (self, remote_file_path, local_file_path, access_type, perm)
		assert(self ~= nil)
		assert(self._sftp_session ~= nil, "SftpSession shouldn't be nil")
		assert(type(remote_file_path) == "string", "remote_file_path must be string")
		assert(type(local_file_path) == "string", "local_file_path must be string")

		if access_type == nil then
			access_type = types.O_RDONLY
		end

		if perm == nil then
			perm = 0
		end

		--- リモートのファイルopen
		local file = libssh.sftp_open(self._sftp_session, remote_file_path, access_type, perm)
		if file == nil then
			return false, self:getError()
		end

		--- リモートファイルのサイズ取得
		local file_stat = libssh.sftp_stat(self._sftp_session, remote_file_path)
		if file_stat == nil then
			libssh.sftp_close(file)
			return false, self:getError()
		end

		local remote_file_length = tonumber(file_stat.size)
		libssh.sftp_attributes_free(file_stat)

		--- ローカルのファイルopen
		local fd = ffi.C.fopen(local_file_path, "wb")
		if fd == nil then
			return false, string.format("Error : fopen fail")
		end

		local last_per = 0
		local now_local_file_length = 0
		while true do
			local buffer_length = self._download_buffer_size --- buffer bytes
			local buffer = ffi.new("char[" .. buffer_length .. "]")
			local nbytes = libssh.sftp_read(file, buffer, buffer_length)

			--[[
			now_local_file_length = now_local_file_length + nbytes
			local per = math.floor((now_local_file_length / remote_file_length) * 100)
			if per ~= last_per then
				last_per = per
				print(per .. "%完了")
			end
			]]

			if nbytes == 0 then
				break -- EOF
			elseif nbytes < 0 then
				libssh.sftp_close(file)
				return false, self:getError()
			end

			local nwritten = tonumber(ffi.C.fwrite(buffer, 1, nbytes, fd))
			if nwritten ~= nbytes then
				libssh.sftp_close(file)
				return false, self:getError()
			end
		end

		ffi.C.fclose(fd)

		local rc = libssh.sftp_close(file)
		if rc ~= types.SSH_OK then
			return false, self:getError()
		end

		return true, nil
	end;
}

return sftp