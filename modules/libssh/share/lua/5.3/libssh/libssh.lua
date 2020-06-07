local ffi = require "ffi"

ffi.cdef[[
typedef struct ssh_string_struct ssh_string;

typedef struct sftp_attributes_struct {
char *name;
char *longname;
uint32_t flags;
uint8_t type;
uint64_t size;
uint32_t uid;
uint32_t gid;
char *owner;
char *group;
uint32_t permissions;
uint64_t atime64;
uint32_t atime;
uint32_t atime_nseconds;
uint64_t createtime;
uint32_t createtime_nseconds;
uint64_t mtime64;
uint32_t mtime;
uint32_t mtime_nseconds;
} *sftp_attributes;

typedef struct sftp_client_message_struct* sftp_client_message;
typedef struct sftp_dir_struct* sftp_dir;
typedef struct sftp_ext_struct *sftp_ext;
typedef struct sftp_file_struct* sftp_file;
typedef struct sftp_message_struct* sftp_message;
typedef struct sftp_packet_struct* sftp_packet;
typedef struct sftp_request_queue_struct* sftp_request_queue;
typedef struct sftp_session_struct* sftp_session;
typedef struct sftp_status_message_struct* sftp_status_message;
typedef struct sftp_statvfs_struct {
uint64_t f_bsize;
uint64_t f_frsize;
uint64_t f_blocks;
uint64_t f_bfree;
uint64_t f_bavail;
uint64_t f_files;
uint64_t f_ffree;
uint64_t f_favail;
uint64_t f_fsid;
uint64_t f_flag;
uint64_t f_namemax;
}* sftp_statvfs_t;
typedef struct ssh_session_struct* ssh_session;
typedef struct ssh_channel_struct* ssh_channel;
typedef struct ssh_auth_callback_struct* ssh_auth_callback;
typedef int mode_t;
typedef int uid_t;
typedef int gid_t;
typedef int ssize_t;

const char *ssh_version(int req_version);
int ssh_options_set(ssh_session session, int type, const void* value);
void ssh_free (ssh_session session);
int ssh_connect (ssh_session session);
void ssh_disconnect (ssh_session session);
int ssh_is_server_known (ssh_session session);
int ssh_is_connected (ssh_session session);
int ssh_write_knownhost (ssh_session session);
int ssh_userauth_password (ssh_session session, const char *username, const char *password);
char* ssh_get_issue_banner(ssh_session session);

ssh_channel ssh_channel_new(ssh_session session);
int ssh_channel_open_session(ssh_channel channel);
int ssh_channel_close(ssh_channel channel);
void ssh_channel_free(ssh_channel channel);
int ssh_channel_request_exec (ssh_channel channel, const char *	cmd);
int ssh_channel_read(ssh_channel channel, void *dest, uint32_t count, int is_stderr);
int ssh_channel_read_nonblocking(ssh_channel channel, void *dest, uint32_t count, int is_stderr);
int ssh_channel_send_eof(ssh_channel channel);
const char* ssh_get_error (void * error);
typedef struct ssh_private_key_struct* ssh_private_key;
typedef struct ssh_public_key_struct* ssh_public_key;
typedef struct ssh_key_struct* ssh_key;
typedef struct ssh_string_struct* ssh_string;

int ssh_userauth_autopubkey(ssh_session session, const char *passphrase);
int ssh_userauth_pubkey(ssh_session session, const char *username, ssh_string publickey, ssh_private_key privatekey);
int ssh_userauth_privatekey_file(ssh_session session, const char *username,
    const char *filename, const char *passphrase);

ssh_session ssh_new(void);

int 	sftp_async_read (sftp_file file, void *data, uint32_t len, uint32_t id);
int 	sftp_async_read_begin (sftp_file file, uint32_t len);
void 	sftp_attributes_free (sftp_attributes file);
char * 	sftp_canonicalize_path (sftp_session sftp, const char *path);
int 	sftp_chmod (sftp_session sftp, const char *file, mode_t mode);
int 	sftp_chown (sftp_session sftp, const char *file, uid_t owner, gid_t group);
int 	sftp_close (sftp_file file);
int 	sftp_closedir (sftp_dir dir);
int 	sftp_dir_eof (sftp_dir dir);
int 	sftp_extension_supported (sftp_session sftp, const char *name, const char *data);
unsigned int 	sftp_extensions_get_count (sftp_session sftp);
const char * 	sftp_extensions_get_data (sftp_session sftp, unsigned int indexn);
const char * 	sftp_extensions_get_name (sftp_session sftp, unsigned int indexn);
void 	sftp_file_set_blocking (sftp_file handle);
void 	sftp_file_set_nonblocking (sftp_file handle);
void 	sftp_free (sftp_session sftp);
sftp_attributes 	sftp_fstat (sftp_file file);
sftp_statvfs_t 	sftp_fstatvfs (sftp_file file);
int 	sftp_fsync (sftp_file file);
int 	sftp_get_error (sftp_session sftp);
int 	sftp_init (sftp_session sftp);
sftp_attributes 	sftp_lstat (sftp_session session, const char *path);
int 	sftp_mkdir (sftp_session sftp, const char *directory, mode_t mode);
sftp_session 	sftp_new (ssh_session session);
sftp_session 	sftp_new_channel (ssh_session session, ssh_channel channel);
sftp_file 	sftp_open (sftp_session session, const char *file, int accesstype, mode_t mode);
sftp_dir 	sftp_opendir (sftp_session session, const char *path);
ssize_t 	sftp_read (sftp_file file, void *buf, size_t count);
sftp_attributes 	sftp_readdir (sftp_session session, sftp_dir dir);
char * 	sftp_readlink (sftp_session sftp, const char *path);
int 	sftp_rename (sftp_session sftp, const char *original, const char *newname);
void 	sftp_rewind (sftp_file file);
int 	sftp_rmdir (sftp_session sftp, const char *directory);
int 	sftp_seek (sftp_file file, uint32_t new_offset);
int 	sftp_seek64 (sftp_file file, uint64_t new_offset);
int 	sftp_server_init (sftp_session sftp);
sftp_session 	sftp_server_new (ssh_session session, ssh_channel chan);
int 	sftp_server_version (sftp_session sftp);
int 	sftp_setstat (sftp_session sftp, const char *file, sftp_attributes attr);
sftp_attributes 	sftp_stat (sftp_session session, const char *path);
sftp_statvfs_t 	sftp_statvfs (sftp_session sftp, const char *path);
void 	sftp_statvfs_free (sftp_statvfs_t statvfs_o);
int 	sftp_symlink (sftp_session sftp, const char *target, const char *dest);
unsigned long 	sftp_tell (sftp_file file);
uint64_t 	sftp_tell64 (sftp_file file);
int 	sftp_unlink (sftp_session sftp, const char *file);
int 	sftp_utimes (sftp_session sftp, const char *file, const struct timeval *times);
ssize_t 	sftp_write (sftp_file file, const void *buf, size_t count);
int 	ssh_pki_import_privkey_file (const char *filename, const char *passphrase, ssh_auth_callback auth_fn, void *auth_data, ssh_key *pkey);
int     ssh_pki_export_privkey_to_pubkey (const ssh_key privkey, ssh_key* pkey);
int     ssh_userauth_publickey (ssh_session session, const char* username, const ssh_key privkey);
ssh_key 	ssh_key_new (void);

typedef struct ssh_buffer_struct* ssh_buffer;
ssh_buffer ssh_buffer_new	(void);

typedef struct {
  char *fpos;
  void *base;
  unsigned short handle;
  short flags;
  short unget;
  unsigned long alloc;
  unsigned short buffincrement;
} FILE;

FILE *fopen(const char *filename, const char *mode);
int fclose(FILE *stream);
size_t fread(void *buf, size_t size, size_t n, FILE *fp);
size_t fwrite(const void * restrict ptr, size_t size, size_t nmemb, FILE * restrict stream);
int fseek(FILE *fp, long offset, int origin);
long ftell(FILE *stream);
char *strerror(int errnum);
]]

local libssh = ffi.load("ssh")
local low_version = 5 * 2^8 + 2
assert(libssh.ssh_version(ffi.new("int", low_version)), "Your libssh is too old! At least 0.5.2 is required.")

return libssh