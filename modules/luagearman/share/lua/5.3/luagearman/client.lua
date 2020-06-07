local geaman = require "luagearman.gearman"
local ffi = require "ffi"

ffi.cdef([[
	gearman_client_st *gearman_client_create(gearman_client_st *client);

	void gearman_client_free(gearman_client_st *client);

	gearman_return_t gearman_client_add_server(gearman_client_st *client,
											   const char *host, in_port_t port);

	void *gearman_client_do(gearman_client_st *client,
							const char *function_name,
							const char *unique,
							const void *workload, size_t workload_size,
							size_t *result_size,
							gearman_return_t *ret_ptr);


	const char *gearman_client_error(const gearman_client_st *client);

	gearman_result_st *gearman_task_result(gearman_task_st *task);


	typedef enum
	{
	  GEARMAN_CLIENT_ALLOCATED=         (1 << 0),
	  GEARMAN_CLIENT_NON_BLOCKING=      (1 << 1),
	  GEARMAN_CLIENT_TASK_IN_USE=       (1 << 2),
	  GEARMAN_CLIENT_UNBUFFERED_RESULT= (1 << 3),
	  GEARMAN_CLIENT_NO_NEW=            (1 << 4),
	  GEARMAN_CLIENT_FREE_TASKS=        (1 << 5),
	  GEARMAN_CLIENT_GENERATE_UNIQUE=   (1 << 6),
	  GEARMAN_CLIENT_EXCEPTION=         (1 << 7),
	  GEARMAN_CLIENT_SSL=               (1 << 8),
	  GEARMAN_CLIENT_MAX=               (1 << 9)
	} gearman_client_options_t;

	gearman_return_t gearman_client_error_code(const gearman_client_st *client);

	int gearman_client_errno(const gearman_client_st *client);

	gearman_client_options_t gearman_client_options(const gearman_client_st *client);

	void gearman_client_set_options(gearman_client_st *client, gearman_client_options_t options);

	int gearman_client_timeout(gearman_client_st *client);

	void gearman_client_set_timeout(gearman_client_st *client, int timeout);


	typedef char gearman_job_handle_t[64];

	gearman_return_t gearman_client_do_background(gearman_client_st *client,
												  const char *function_name,
												  const char *unique,
												  const void *workload,
												  size_t workload_size,
												  gearman_job_handle_t job_handle);
]])

local client = {}
client.__index = client

---
--
function client.init()
	local self = {
		_client = nil
	}
	return setmetatable(self, client)
end

---
--
function client:create(client)
	assert(not self._client)
	self._client = geaman.ffi.gearman_client_create(client)
end

---
--
function client:addServer(host, port)
	assert(self._client)
	return geaman.ffi.gearman_client_add_server(self._client, host, port);
end

---
--
function client:free()
	assert(self._client)
	geaman.ffi.gearman_client_free(self._client)
	self._client = nil
end

---
--
function client:excute(function_name, unique, workload, arguments, context)
	assert(self._client)

	local c_arguments = nil
	if arguments ~= nil then
		c_arguments = arguments:getCInstance()
	end

	local function_name_length = #function_name
	local unique_length = 0

	if unique ~= nil then
		unique_length = #unique
	end

	local task = geaman.ffi.gearman_execute(self._client, function_name, function_name_length, unique, unique_length, workload, c_arguments, context)
	if task == nil then
		return nil
	end

	if not geaman.success(geaman.ffi.gearman_task_return(task)) then
		return nil
	end

	local result = geaman.ffi.gearman_task_result(task)

	if result == nil then
		return nil
	end

	local size = tonumber(geaman.ffi.gearman_result_size(result))
	local value = geaman.ffi.gearman_result_value(result)
	if value ~= nil then
		value = ffi.string(value)
	end

	return result, size, value
end

---
--
function client:error()
	assert(self._client)
	return ffi.string(geaman.ffi.gearman_client_error(self._client))
end

---
--
function client:errorCode()
	assert(self._client)
	return geaman.ffi.gearman_client_error_code(self._client)
end

---
--
function client:errno()
	assert(self._client)
	return geaman.ffi.gearman_client_errno(self._client)
end

---
--
function client:options()
	assert(self._client)
	return geaman.ffi.gearman_client_options(self._client)
end

---
--
function client:setOptions(options)
	assert(self._client)
	geaman.ffi.gearman_client_set_options(self._client, options)
end

---
--
function client:timeout()
	assert(self._client)
	return geaman.ffi.gearman_client_timeout(self._client)
end

---
--
function client:setTimeout(timeout)
	assert(self._client)
	geaman.ffi.gearman_client_set_timeout(self._client, timeout)
end

return client