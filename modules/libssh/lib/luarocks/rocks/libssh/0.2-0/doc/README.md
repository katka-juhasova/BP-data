# libssh


[libssh](https://www.libssh.org/)をLuajit FFIで呼び出すモジュールです。


# 依存

[bit32](https://luarocks.org/modules/siffiejoe/bit32)

[Penlight](https://github.com/stevedonovan/Penlight)

[libssh](https://www.libssh.org/) >= 0.5.2

Luajit

# インストール
`$ luarocks install libssh`

# 使い方
```lua
local sftp = require "libssh.sftp"

local private = {
	params = {
	  host = "***.***.***.***",
	  port = 22,
	  user = "user",
	};
	password = "password",
	key_file_path = "/path/to/private_key_file_path",
}

local _sftp = sftp()

-- set option
for k,v in pairs(private.params) do
	_sftp:setOption(k, v)
end

-- password auth
assert(_sftp:authentication(private.password))
assert(_sftp:openSftp())

local ret = assert(_sftp:commandExcec("ls -l"))
print(ret)

_sftp:closeSftp()
_sftp:close()
```

# API

* libssh()

Luajit.ffiオブジェクトを返す。

* authentication(password, private_key)

SSHサーバーに対して認証を行う。

* openSftp()

SFTPを初期化する。

* closeSftp()

SFTPを開放する。

* close()

クラスを開放する。

* getError()

直近のエラーを返す。

* commandExcec(command)

シェルコマンドを発行し結果を返す。

* setOption(option, value)

オプションを設定する。

* directoryEnumeration(target_dir)

指定リモートディレクトリの内容を列挙する。

* fileUpload(remote_file_path, local_file_path, access_type, perm)

指定ファイルを指定リモートディレクトリにアップロードする。

* fileDownload(remote_file_path, local_file_path, access_type, perm)

指定リモートファイルを指定ディレクトリにダウンロードする。

## エラーハンドリング

返り値を持つ関数は共通で{返り値,エラー}のテーブルを返却する。

`local ret, err = libssh:commandExcec("ls")`

or

`assert(libssh:fileUpload(remote_file_path, local_file_path, access_type, perm))`


## option対応表

[ssh_options_set()](http://api.libssh.org/master/group__libssh__session.html#ga7a801b85800baa3f4e16f5b47db0a73d)

ssh_options_set()に渡す値と同様です。

|option|libssh define|
|-|-|
|host|SSH_OPTIONS_HOST|
|port|SSH_OPTIONS_PORT|
|user|SSH_OPTIONS_USER|
|ssh_dir|SSH_OPTIONS_SSH_DIR|
|identity|SSH_OPTIONS_IDENTITY|
|known_hosts|SSH_OPTIONS_KNOWNHOSTS|
|timeout|SSH_OPTIONS_TIMEOUT|
|ssh1|SSH_OPTIONS_SSH1|
|ssh2|SSH_OPTIONS_SSH2|
