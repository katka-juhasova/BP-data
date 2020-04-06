# libssh2


[libssh2](https://www.libssh2.org/) をLuajitFFIで呼び出しを行うパッケージです。

関数群のグループ毎にクラス化しています。

session,channelなどインスタンスメソッド化されているメソッドは第一引数を省略して呼び出しができます。

引数はそのままffi呼び出しに入力していますので必要に応じてキャストを行って下さい。

## クラス一覧

* agent
* base64
* channel
* hostkey
* keeplive
* knownhost
* publickey
* scp
* session
* sftp
* trace
* userauth

libssh2関数群のグループ名毎にクラス化しています。

例）libssh2_channel_get_exit_signal()　→　channel:get_exit_signal()


# 間接モジュール

* prototype
* libssh2



# 依存

Luajit >= 2.1

# インストール
`$ luarocks install libssh2`


# API


## class agent

agent.initでインスタンス化してください。

gcによってインスタンスが破棄される時libssh2_agent_freeが自動で呼ばれます。

インスタンス.agentがLIBSSH2_AGENT*のポインタです。

* agent.init(session)
* agent:userauth(username, identity)
* agent:list_identities()
* agent:get_identity(store, prev)
* agent:connect()
* agent:disconnect()

## class base64

* base64.decode(session, dest, dest_len, src, src_len)

## class channel

channel.forward_accept、
channel.direct_tcpip、
channel.open_ex、
channel.open_sessionでインスタンス化してください。

gcによってインスタンスが破棄される時libssh2_channel_freeが自動で呼ばれます。

インスタンス.channelがLIBSSH2_CHANNEL*のポインタです。


* channel:flush_stderr()
* channel:window_read_ex(read_avail, window_size_initial)
* channel:subsystem(subsystem)
* channel:x11_req_ex(single_connection, auth_proto, auth_cookie, screen_number)
* channel:process_startup(request, request_len, message, message_len)
* channel:shell()
* channel:request_pty_ex(term, term_len, modes, modes_len, width, height, width_px, height_px)
* channel:send_eof()
* channel:x11_req(screen_number)
* channel:poll_channel_read(extended)
* channel:handle_extended_data(ignore_mode)
* channel.forward_accept(listener)
* channel.forward_listen_ex(session, host, port, bound_port, queue_maxsize)
* channel:read_ex(stream_id, buf, buflen)
* channel:receive_window_adjust(adjustment, force)
* channel:setenv_ex(varname, varname_len, value, value_len)
* channel:handle_extended_data2(ignore_mode)
* channel:request_pty_size_ex(width, height, width_px, height_px)
* channel:window_write()
* channel:read(buf, buflen)
* channel.forward_cancel(listener)
* channel:close()
* channel.direct_tcpip(session, host, port)
* channel.open_ex(session, channel_type, channel_type_len, window_size, packet_size, message, message_len)
* channel:libssh2_channel_flush()
* channel:set_blocking(blocking)
* channel:window_read()
* channel:eof()
* channel:write_stderr(buf, buflen)
* channel:read_stderr(buf, buflen)
* channel:setenv(varname, value)
* channel:window_write_ex(window_size_initial)
* channel:exec(command)
* channel.open_session(session)
* channel:get_exit_signal(exitsignal, exitsignal_len, errmsg, errmsg_len, langtag, langtag_len)
* channel:write_ex(stream_id, buf, buflen)
* channel:wait_eof()
* channel:request_pty(term)
* channel:get_exit_status()
* channel:direct_tcpip_ex(session, host, port, shost, sport)
* channel:forward_listen(session, port)
* channel:flush_ex(streamid)
* channel:request_pty_size(width, height)
* channel:wait_closed()
* channel:receive_window_adjust2(adjustment, force, window)
* channel:write(buf, buflen)


## class hostkey

* hostkey.hash(session, hash_type)

## class keeplive

* keeplive.send(session, seconds_to_next)
* keeplive.config(session, want_reply, interval)

## class knownhost

knownhost.initでインスタンス化してください。

gcによってインスタンスが破棄される時libssh2_knownhost_freeが自動で呼ばれます。

インスタンス.knownhostがLIBSSH2_KNOWNHOSTS*のポインタです。

* knownhost:writeline(known, buffer, buflen, outlen, type)
* knownhost:readline(line, line, len, type)
* knownhost:check(host, key, keylen, typemask, knownhost)
* knownhost:del(entry)
* knownhost:writefile(filename, type)
* knownhost:add(host, salt, key, keylen, typemask, store)
* knownhost.init(session)
* knownhost:addc(host, salt, key, keylen, comment, commentlen, typemask, store)
* knownhost:get(store, prev)
* knownhost:checkp(host, port, key, keylen, typemask, knownhost)
* knownhost:readfile(filename, type)

## class publickey

publickey.initでインスタンス化してください。

インスタンス.publickeyがLIBSSH2_KNOWNHOSTS*のポインタです。


* publickey:list_fetch(num_keys, pkey_list)
* publickey:list_free(pkey_list)
* publickey:add_ex(name, name_len, blob, blob_len, overwrite, num_attrs, attrs)
* publickey.init(session)
* publickey:remove(name, name_len, blob, blob_len)
* publickey:shutdown()
* publickey:add(name, blob, blob_len, overwrite, num_attrs, attrs)

## class scp

* scp.recv(session, path, sb)
* scp.send(session, path, mode, size)
* scp.send_ex(session, path, mode, size, mtime, atime)
* scp.recv2(session, path, sb)
* scp.send64(session, path, mode, size, mtime, atime)

## class session

session.init、
session.init_exでインスタンス化してください。

gcによってインスタンスが破棄される時libssh2_session_freeが自動で呼ばれます。

インスタンス.sessionがLIBSSH2_SESSION*のポインタです。


* session:handshake(socket)
* session:banner_set(banner)
* session:set_timeout(timeout)
* session.init_ex(myalloc, myfree, myrealloc, abstract)
* session:abstract()
* session:disconnect(description)
* session:method_pref(method_type, prefs)
* session:get_blocking()
* session:last_errno()
* session:set_last_error(errcode, errmsg)
* session:block_directions()
* session:set_blocking(blocking)
* session:startup(socket)
* session:banner_get()
* session:disconnect_ex(reason, description, lang)
* session:callback_set(cbtype, callback)
* session:banner_set(banner)
* session:last_error(errmsg, errmsg_len, want_buf)
* session.init()
* session:flag(flag, value)
* session:methods(method_type)
* session:supported_algs(method_type, algs)
* session:timeout()
* session:hostkey(len, type)

## class sftp

sftp.initでインスタンス化してください。

gcによってインスタンスが破棄される時libssh2_sftp_shutdownが自動で呼ばれます。

インスタンス.sftpがLIBSSH2_SFTP*のポインタです。


* sftp:mkdir(path, mode)
* sftp:rename(source_filename, destination_filename)
* sftp.init(session)
* sftp:last_error()
* sftp:stat(path, attrs)
* sftp:statvfs(path, path_len, st)
* sftp:fstat_ex(handle, attrs, setstat)
* sftp:unlink_ex(filename, filename_len)
* sftp:closedir(handle)
* sftp:readdir_ex(handle, buffer, buffer_maxlen, longentry, longentry_maxlen, attrs)
* sftp:seek(handle, offset)
* sftp:fsetstat(handle, attrs)
* sftp:open_ex(filename, filename_len, flags, mode, open_type)
* sftp:rewind(handle)
* sftp:rename_ex(source_filename, source_filename_len, dest_filename, dest_filename_len, flags)
* sftp:setstat(path, attr)
* sftp:opendir(path)
* sftp:close(handle)
* sftp:tell64(handle)
* sftp:mkdir_ex(path, path_len, mode)
* sftp:rmdir_ex(path, path_len)
* sftp:open(path, flags, mode)
* sftp:stat_ex(path, path_len, stat_type, attrs)
* sftp:fstat(handle, attrs)
* sftp:write(handle, buffer, count)
* sftp:symlink_ex(path, path_len, target, target_len, link_type)
* sftp:close_handle(handle)
* sftp:shutdown()
* sftp:tell(handle)
* sftp:unlink(filename)
* sftp:readdir(handle, buffer, buffer_maxlen, attrs)
* sftp:read(handle, buffer, buffer_maxlen)
* sftp:fstatvfs(handle, st)
* sftp:seek64(handle, offset)
* sftp:fsync(handle)


## class trace

* trace.sethandler(session, context, callback)
* trace.trace(session, bitmask)

## class userauth

* userauth.keyboard_interactive(session, username, response_callback)
* userauth.password(session, username, password)
* userauth.publickey_fromfile(session, username, publickey, privatekey, passphrase)
* userauth.list(session, username, username_len)
* userauth.hostbased_fromfile_ex(session, username, username_len, publickey, privatekey, passphrase, hostname, hostname_len, local_username, local_username_len)
* userauth.publickey(session, user, pubkeydata, pubkeydata_len, sign_callback, abstract)
* userauth.hostbased_fromfile(session, username, publickey, privatekey, passphrase, hostname)
* userauth.publickey_fromfile_ex(session, username,  ousername_len, publickey, privatekey, passphrase)
* userauth.keyboard_interactive_ex(session, username, username_len, response_callback)
* userauth.password_ex(session, username, username_len, password, password_len, passwd_change_cb)
* userauth.authenticated(session)
* userauth.publickey_frommemory(session, username, username_len, publickeydata, publickeydata_len, privatekeydata, privatekeydata_len, passphrase)

## libssh2

* libssh2.poll(fds, nfds, timeout)
* libssh2.init(flags)
* libssh2.exit()
* libssh2.free(session, ptr)
* libssh2.version(required_version)
