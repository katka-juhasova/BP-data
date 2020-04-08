local ffi = require "ffi"
local curl = require "luajit-curl"

local _M = {}
_M.__index = _M

function build_body_cb(ptr, size, nmemb, stream)
	local bytes = size*nmemb
	local dst = ffi.new("char[?]", size*nmemb)
	ffi.copy(dst, ptr, size*nmemb)
	table.insert(_M._raw_body, ffi.string(dst, size*nmemb))
	return bytes
end

function build_header_cb(ptr, size, nmemb, stream)
	local bytes = size*nmemb
	local dst = ffi.new("char[?]", size*nmemb)
	ffi.copy(dst, ptr, size*nmemb)
	table.insert(_M._raw_header, ffi.string(dst, size*nmemb))
	return bytes
end

function setCurlOpt(self)
	self._opt.method = self._opt.method or "GET"
	self._opt.body = self._opt.body or nil
	self._opt.header = self._opt.header or {}
	self._opt.user_agent = self._opt.user_agent or nil
	self._opt.http_timeout_sec = self._opt.http_timeout_sec or 60

	self._curl_handle = curl.curl_easy_init()
	self._status_code = nil
	self._status_message = nil
	self._body = nil
	self._header = {}
	self._error = nil

	if _M.clb1 == nil then
		_M.clb1 = ffi.cast("curl_callback", build_body_cb)
	end

	if _M.clb2 == nil then
		_M.clb2 = ffi.cast("curl_callback", build_header_cb)
	end

	curl.curl_easy_setopt(self._curl_handle, curl.CURLOPT_URL, self._url)

	curl.curl_easy_setopt(self._curl_handle, curl.CURLOPT_FOLLOWLOCATION, 1)

	-- CURLOPT_CUSTOMREQUEST
	if self._opt.method == "HEAD" then
		curl.curl_easy_setopt(self._curl_handle, curl.CURLOPT_NOBODY, true)
	elseif self._opt.method ~= nil then
		curl.curl_easy_setopt(self._curl_handle, curl.CURLOPT_CUSTOMREQUEST, self._opt.method)

		if (self._opt.method ~= "GET" or self._opt.method ~= "DELETE") and self._opt.body ~= nil then
			curl.curl_easy_setopt(self._curl_handle, curl.CURLOPT_POSTFIELDS, self._opt.body)
		end
	end

	-- CURLOPT_SSL_VERIFYPEER
	curl.curl_easy_setopt(self._curl_handle, curl.CURLOPT_SSL_VERIFYPEER, false)
	-- CURLOPT_NOSIGNAL
	curl.curl_easy_setopt(self._curl_handle, curl.CURLOPT_NOSIGNAL, 1)
	-- CURLOPT_TIMEOUT
	curl.curl_easy_setopt(self._curl_handle, curl.CURLOPT_TIMEOUT, self._opt.http_timeout_sec)

	if self._opt.user_agent ~= nil then
		-- CURLOPT_USERAGENT
		curl.curl_easy_setopt(self._curl_handle, curl.CURLOPT_USERAGENT, self._opt.user_agent)
	end

	curl.curl_easy_setopt(self._curl_handle, curl.CURLOPT_WRITEFUNCTION, _M.clb1)
	curl.curl_easy_setopt(self._curl_handle, curl.CURLOPT_HEADERFUNCTION, _M.clb2)
end

---
-- @brief インスタンス化を行う
-- @param url URL
-- @param opt table
-- @return table
-- @note opt.method HTTPメソッド
-- opt.body リクエストボディ
-- opt.header リクエストヘッダ
-- opt.user_agent ユーザーエージェント
-- opt.http_timeout_sec HTTPタイムアウト（秒）
--
function _M.init(url, opt)
	local self = setmetatable({}, _M)

	assert(type(url) == "string")
	if opt ~= nil then
		assert(type(opt) == "table")
	end

	self._url = url
	self._opt = opt or {}

	self._opt.external_opt = {}

	return self
end

---
-- @brief リクエストを実行し成否を返す
-- @retval true 正常
-- @retval false エラー
-- @return boolean
--
function _M:perform()
	local ret = false

	setCurlOpt(self)

	_M._raw_body = {}
	_M._raw_header = {}

	local request_header_list

	if #self._opt.header > 0 then
		request_header_list = ffi.new("struct curl_slist *")
		for i=1, #self._opt.header do
			request_header_list = curl.curl_slist_append(request_header_list, self._opt.header[i])
		end

		-- CURLOPT_HTTPHEADER
		curl.curl_easy_setopt(self._curl_handle, curl.CURLOPT_HTTPHEADER, request_header_list)
	end

	for k, v in pairs(self._opt.external_opt) do
		curl.curl_easy_setopt(self._curl_handle, k, v)
	end

	local success, err = pcall(function()
		return curl.curl_easy_perform(self._curl_handle)
	end)

	if request_header_list ~= nil then
		curl.curl_slist_free_all(request_header_list)
	end

	local result = tonumber(err)

	ret = result == curl.CURLE_OK

	if not ret then
		self._error = ffi.string(curl.curl_easy_strerror(result))
	end

	self._body = table.concat(_M._raw_body)
	local header = table.concat(_M._raw_header)

	self._status_code = nil
	self._header = {}

	if header ~= nil then
		for v in string.gmatch(header, "([^\n\r]+)") do
			local name, value = v:match("(.-): (.+)")

			if name and value then
				self._header[name] = value:gsub("[\n\r]", "")
			else
				local code, codemessage = string.match(v, "^HTTP/.* (%d+) (.+)$")
				if code and codemessage then
					self._status_code = tonumber(code)
					self._status_message = codemessage:gsub("[\n\r]", "")
				end
			end
		end
	end

	curl.curl_easy_cleanup(self._curl_handle)
	self._curl_handle = nil

	return ret
end

---
-- @brief レスポンスヘッダを取得する
-- @return table
--
function _M:header()
	return self._header
end

---
-- @brief レスポンスボディを取得する
-- @return string
--
function _M:body()
	return self._body
end

---
-- @brief ステータスコードを取得する
-- @return number
--
function _M:statusCode()
	return self._status_code
end

---
-- @brief ステータスメッセージを取得する
-- @return string
--
function _M:statusMessage()
	return self._status_message
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
-- @brief curlエラーを取得する
-- @return string
--
function _M:lastError()
	return self._error
end

return _M