local gearman = require "luagearman.gearman"
local ffi = require "ffi"

ffi.cdef([[
	typedef enum
	{
	  GEARMAN_WORKER_ALLOCATED=        (1 << 0),
	  GEARMAN_WORKER_NON_BLOCKING=     (1 << 1),
	  GEARMAN_WORKER_PACKET_INIT=      (1 << 2),
	  GEARMAN_WORKER_GRAB_JOB_IN_USE=  (1 << 3),
	  GEARMAN_WORKER_PRE_SLEEP_IN_USE= (1 << 4),
	  GEARMAN_WORKER_WORK_JOB_IN_USE=  (1 << 5),
	  GEARMAN_WORKER_CHANGE=           (1 << 6),
	  GEARMAN_WORKER_GRAB_UNIQ=        (1 << 7),
	  GEARMAN_WORKER_TIMEOUT_RETURN=   (1 << 8),
	  GEARMAN_WORKER_GRAB_ALL=         (1 << 9),
	  GEARMAN_WORKER_SSL=              (1 << 10),
	  GEARMAN_WORKER_IDENTIFIER=       (1 << 11),
	  GEARMAN_WORKER_MAX=   (1 << 12)
	} gearman_worker_options_t;

	typedef enum {
		GEARMAN_WORKER_STATE_START,
		GEARMAN_WORKER_STATE_FUNCTION_SEND,
		GEARMAN_WORKER_STATE_CONNECT,
		GEARMAN_WORKER_STATE_GRAB_JOB_SEND,
		GEARMAN_WORKER_STATE_GRAB_JOB_RECV,
		GEARMAN_WORKER_STATE_PRE_SLEEP
	} gearman_worker_state_t;

	typedef enum {
		GEARMAN_WORKER_WORK_UNIVERSAL_GRAB_JOB,
		GEARMAN_WORKER_WORK_UNIVERSAL_FUNCTION,
		GEARMAN_WORKER_WORK_UNIVERSAL_COMPLETE,
		GEARMAN_WORKER_WORK_UNIVERSAL_FAIL
	} gearman_worker_universal_t;

	typedef struct
	{
	  struct {
		bool is_allocated;
		bool is_initialized;
	  } options;
	  void *_impl;
	} gearman_worker_st;

	gearman_worker_st *gearman_worker_create(gearman_worker_st *client);

	void gearman_worker_free(gearman_worker_st *client);

	const char *gearman_worker_error(const gearman_worker_st *worker);

	gearman_return_t gearman_worker_work(gearman_worker_st *worker);

	gearman_return_t gearman_worker_add_server(gearman_worker_st *worker, const char *host, in_port_t port);

	gearman_return_t gearman_worker_add_function(gearman_worker_st *worker, const char *function_name, uint32_t timeout, gearman_worker_fn *function, void *context);

	int gearman_worker_errno(gearman_worker_st *worker);

	gearman_worker_options_t gearman_worker_options(const gearman_worker_st *worker);

	void gearman_worker_set_options(gearman_worker_st *worker, gearman_worker_options_t options);

	int gearman_worker_timeout(gearman_worker_st *worker);

	void gearman_worker_set_timeout(gearman_worker_st *worker, int timeout);
]])

local worker = {}
worker.__index = worker

---
--
function worker.init()
	local self = {
		_worker = nil,
		_worker_func = {},
	}
	return setmetatable(self, worker)
end

---
--
function worker:create(worker)
	assert(not self._worker)
	self._worker = gearman.ffi.gearman_worker_create(worker)
end

---
--
function worker:addServer(host, port)
	assert(self._worker)
	return gearman.ffi.gearman_worker_add_server(self._worker, host, port);
end

---
--
function worker:free()
	assert(self._worker)
	for k, v in pairs(self._worker_func) do
		v:free()
	end
	gearman.ffi.gearman_worker_free(self._worker)
end

---
--
function worker:addFunction(function_name, timeout, func, context)
	assert(self._worker)

	local clb = ffi.cast("gearman_worker_fn*", function(job, context, result_size, ret_ptr)
		local workload = gearman.ffi.gearman_job_workload(job);
		local workload_size = gearman.ffi.gearman_job_workload_size(job);
		local dst = ffi.new("char[?]", workload_size + 1)
		ffi.fill(dst, workload_size + 1)
		ffi.copy(dst, workload, workload_size)

		-- clientから送られてくるargmentはstringなのでデコードする
		local decorded = ffi.string(dst)

		local ret = func(decorded)

		-- returnするchar*はmallocした領域を返却する
		local c_ret = gearman.ffi.strdup(ret)
		result_size[0] = #ret
		return ffi.cast("void*", c_ret)
	end)

	local ret = gearman.ffi.gearman_worker_add_function(self._worker, function_name, timeout, clb, context)

	self._worker_func[function_name] = clb

	return ret
end

---
--
function worker:error()
	assert(self._worker)
	return ffi.string(gearman.ffi.gearman_worker_error(self._worker))
end

---
--
function worker:work()
	assert(self._worker)
	return gearman.ffi.gearman_worker_work(self._worker)
end

---
--
function worker:errno()
	assert(self._worker)
	return gearman.ffi.gearman_worker_errno(self._worker)
end

---
--
function worker:options()
	assert(self._worker)
	return gearman.ffi.gearman_worker_options(self._worker)
end

---
--
function worker:setOptions(options)
	assert(self._worker)
	gearman.ffi.gearman_worker_set_options(self._worker, options)
end

---
--
function worker:timeout()
	assert(self._worker)
	return gearman.ffi.gearman_worker_timeout(self._worker)
end

---
--
function worker:setTimeout(timeout)
	assert(self._worker)
	gearman.ffi.gearman_worker_set_timeout(self._worker, timeout)
end

return worker