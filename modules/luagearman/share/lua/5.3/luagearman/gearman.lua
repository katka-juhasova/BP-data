local ffi = require "ffi"

ffi.cdef([[

typedef uint16_t in_port_t;

typedef enum gearman_return_t
{
  GEARMAN_SUCCESS,
  GEARMAN_IO_WAIT,
  GEARMAN_SHUTDOWN,
  GEARMAN_SHUTDOWN_GRACEFUL,
  GEARMAN_ERRNO,
  GEARMAN_EVENT, // DEPRECATED, SERVER ONLY
  GEARMAN_TOO_MANY_ARGS,
  GEARMAN_NO_ACTIVE_FDS, // No servers available
  GEARMAN_INVALID_MAGIC,
  GEARMAN_INVALID_COMMAND,
  GEARMAN_INVALID_PACKET,
  GEARMAN_UNEXPECTED_PACKET,
  GEARMAN_GETADDRINFO,
  GEARMAN_NO_SERVERS,
  GEARMAN_LOST_CONNECTION,
  GEARMAN_MEMORY_ALLOCATION_FAILURE,
  GEARMAN_JOB_EXISTS, // see gearman_client_job_status()
  GEARMAN_JOB_QUEUE_FULL,
  GEARMAN_SERVER_ERROR,
  GEARMAN_WORK_ERROR,
  GEARMAN_WORK_DATA,
  GEARMAN_WORK_WARNING,
  GEARMAN_WORK_STATUS,
  GEARMAN_WORK_EXCEPTION,
  GEARMAN_WORK_FAIL,
  GEARMAN_NOT_CONNECTED,
  GEARMAN_COULD_NOT_CONNECT,
  GEARMAN_SEND_IN_PROGRESS, // DEPRECATED, SERVER ONLY
  GEARMAN_RECV_IN_PROGRESS, // DEPRECATED, SERVER ONLY
  GEARMAN_NOT_FLUSHING,
  GEARMAN_DATA_TOO_LARGE,
  GEARMAN_INVALID_FUNCTION_NAME,
  GEARMAN_INVALID_WORKER_FUNCTION,
  GEARMAN_NO_REGISTERED_FUNCTION,
  GEARMAN_NO_REGISTERED_FUNCTIONS,
  GEARMAN_NO_JOBS,
  GEARMAN_ECHO_DATA_CORRUPTION,
  GEARMAN_NEED_WORKLOAD_FN,
  GEARMAN_PAUSE, // Used only in custom application for client return based on work status, exception, or warning.
  GEARMAN_UNKNOWN_STATE,
  GEARMAN_PTHREAD, // DEPRECATED, SERVER ONLY
  GEARMAN_PIPE_EOF, // DEPRECATED, SERVER ONLY
  GEARMAN_QUEUE_ERROR, // DEPRECATED, SERVER ONLY
  GEARMAN_FLUSH_DATA, // Internal state, should never be seen by either client or worker.
  GEARMAN_SEND_BUFFER_TOO_SMALL,
  GEARMAN_IGNORE_PACKET, // Internal only
  GEARMAN_UNKNOWN_OPTION, // DEPRECATED
  GEARMAN_TIMEOUT,
  GEARMAN_ARGUMENT_TOO_LARGE,
  GEARMAN_INVALID_ARGUMENT,
  GEARMAN_IN_PROGRESS, // See gearman_client_job_status()
  GEARMAN_INVALID_SERVER_OPTION, // Bad server option sent to server
  GEARMAN_JOB_NOT_FOUND, // Job did not exist on server
  GEARMAN_MAX_RETURN, /* Always add new error code before */
  GEARMAN_FAIL= GEARMAN_WORK_FAIL,
  GEARMAN_FATAL= GEARMAN_WORK_FAIL,
  GEARMAN_ERROR= GEARMAN_WORK_ERROR
} gearman_return_t;

static bool gearman_continue(enum gearman_return_t rc)
{
  return rc == GEARMAN_IO_WAIT || rc == GEARMAN_IN_PROGRESS ||  rc == GEARMAN_PAUSE || rc == GEARMAN_JOB_EXISTS;
}

static bool gearman_failed(enum gearman_return_t rc)
{
  return rc != GEARMAN_SUCCESS;
}

static bool gearman_success(enum gearman_return_t rc)
{
  return rc == GEARMAN_SUCCESS;
}

typedef struct {} gearman_client_st;


typedef struct gearman_string_t {
  const char *c_str;
  const size_t size;
} gearman_string_t;

typedef struct gearman_argument_t {
  gearman_string_t name;
  gearman_string_t value;
} gearman_argument_t;



typedef enum
{
  GEARMAN_JOB_PRIORITY_HIGH,
  GEARMAN_JOB_PRIORITY_NORMAL,
  GEARMAN_JOB_PRIORITY_LOW,
  GEARMAN_JOB_PRIORITY_MAX /* Always add new commands before this. */
} gearman_job_priority_t;

typedef enum  {
  GEARMAN_TASK_ATTR_FOREGROUND,
  GEARMAN_TASK_ATTR_BACKGROUND,
  GEARMAN_TASK_ATTR_EPOCH
} gearman_task_attr_kind_t;

typedef unsigned long time_t;

typedef struct  {
  time_t value;
} gearman_task_attr_epoch_t;

typedef struct {
  gearman_task_attr_kind_t kind;
  gearman_job_priority_t priority;
  union {
    char bytes[sizeof(gearman_task_attr_epoch_t)];
    gearman_task_attr_epoch_t epoch;
  } options;
} gearman_task_attr_t;

typedef struct {} gearman_task_st;

gearman_task_st *gearman_execute(gearman_client_st *client,
                                 const char *function_name, size_t function_name_length,
                                 const char *unique, size_t unique_length,
                                 gearman_task_attr_t *workload,
                                 gearman_argument_t *arguments,
                                 void *context);

gearman_return_t gearman_task_return(const gearman_task_st *task);


typedef struct {} gearman_result_st;
size_t gearman_result_size(const gearman_result_st *self);
const char *gearman_result_value(const gearman_result_st *self);


///////////////////////////////////////////////////////////////////

enum gearman_function_kind_t {
  GEARMAN_WORKER_FUNCTION_NULL,
  GEARMAN_WORKER_FUNCTION_V1,
  GEARMAN_WORKER_FUNCTION_V2,
  GEARMAN_WORKER_FUNCTION_PARTITION
};

typedef struct {} gearman_job_st;
typedef struct {} gearman_aggregator_st;

typedef gearman_return_t (gearman_function_fn)(gearman_job_st *job, void *worker_context);
typedef gearman_return_t (gearman_aggregator_fn)(gearman_aggregator_st *, gearman_task_st *, gearman_result_st *);

typedef void* (gearman_worker_fn)(gearman_job_st *job, void *context,
                                  size_t *result_size,
                                  gearman_return_t *ret_ptr);

struct gearman_function_v1_t {
  gearman_worker_fn *func;
};

struct gearman_function_v2_t {
  gearman_function_fn *func;
};

struct gearman_function_partition_v1_t {
  gearman_function_fn *func;
  gearman_aggregator_fn *aggregator;
};

typedef struct {
	const enum gearman_function_kind_t kind;
	union {
		char bytes[sizeof(struct gearman_function_partition_v1_t)]; // @note gearman_function_partition_v1_t is the largest structure
		struct gearman_function_v1_t function_v1;
		struct gearman_function_v2_t function_v2;
		struct gearman_function_partition_v1_t partitioner;
	} callback;
} gearman_function_t;

gearman_function_t gearman_function_create(gearman_function_fn func);

////////////////////////////////////////////////////////////////

const void *gearman_job_workload(const gearman_job_st *job);
size_t gearman_job_workload_size(const gearman_job_st *job);

]])

ffi.cdef([[
	void *malloc(size_t size);
	void free(void *ptr);
	char *strdup(const char *string);
]])

local _gearman = ffi.load("gearman")

local gearman = {
	["ffi"] = _gearman
}
gearman.__index = gearman

---
--
function gearman.continue(rc)
	return rc == _gearman.GEARMAN_IO_WAIT or rc == _gearman.GEARMAN_IN_PROGRESS or rc == _gearman.GEARMAN_PAUSE or rc or _gearman.GEARMAN_JOB_EXISTS
end

---
--
function gearman.failed(rc)
	return rc ~= _gearman.GEARMAN_SUCCESS
end

---
--
function gearman.success(rc)
	return rc == _gearman.GEARMAN_SUCCESS
end



return gearman
