# luajit-curl


[curl](https://curl.haxx.se/)のバインディングです。

こちらのソースがオリジナルです。

https://gist.github.com/LPGhatguy/09d3955207ab35d96e97

# Install
`$ luarocks install luajit-curl`

# Usage

## luajit-curl

```lua
local curl = require("luajit-curl")
local ch = curl.curl_easy_init()

if (ch) then
	curl.curl_easy_setopt(ch, curl.CURLOPT_URL, "http://example.com")
	curl.curl_easy_setopt(ch, curl.CURLOPT_FOLLOWLOCATION, 1)

	local result = curl.curl_easy_perform(ch)
	if (result ~= curl.CURLE_OK) then
		print("FAILURE:", ffi.string(curl.curl_easy_strerror(result)))
	end

	curl.curl_easy_cleanup(ch)
end
```

## luajit-curl-helper

### HTTP

```lua
local http = require "luajit-curl-helper.http"

local request = http.init("http://example.com/")

local st = request:perform()

if not st then
	error(request:lastError())
end

local status_code = request:statusCode()
local status_message = request:statusMessage()
print("status_code, status_message" status_code, status_message)

local body = request:body()
print("body", body)
```

### FTP

```lua
local ftp = require "luajit-curl-helper.ftp"

local opt = {
	remote_addr = "localhost",
	username = "hoge",
	password = "hoge",
}

local instance = ftp.init(opt)

local ret = instance:upload("/public/test", "/local/dir/test")

if not ret then
	error(instance:lastError())
end

local ret, dir = instance:dir("/public/")

if not ret then
	error(instance:lastError())
end

print(dir)
```

### SFTP

```lua
local sftp = require "luajit-curl-helper.sftp"

local opt = {
	remote_addr = "localhost",
	username = "hoge",
	public_key = "/publickey/local/dir/key"
}

local instance = sftp.init(opt)

local ret = instance:upload("/public/test", "/local/dir/test")

if not ret then
	error(instance:lastError())
end

local ret, dir = instance:dir("/public/")

if not ret then
	error(instance:lastError())
end

print(dir)
```

# Revesion

* 2019/08/01 v1.1 add SetOpt
* 2019/07/31 v1.0 helper major change
* 2019/07/23 v0.3 add helper
* 2019/07/22 v0.1 release
