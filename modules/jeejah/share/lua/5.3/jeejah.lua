local socket = require "socket"
local serpent = require "serpent"
local bencode = require "bencode"

local load = loadstring or load

local timeout = 0.001

local d = function(_) end
local serpent_pp = function(p) return function(x)
      local serpent_opts = {maxlevel=8,maxnum=64,nocode=true}
      p(serpent.block(x, serpent_opts)) end
end
local sessions = {}

local response_for = function(old_msg, msg)
   msg.session, msg.id, msg.ns = old_msg.session, old_msg.id, ""
   return msg
end

local send = function(conn, msg)
   d("Sending", bencode.encode(msg))
   conn:send(bencode.encode(msg))
end

local write_for = function(conn, msg)
   return function(...)
      send(conn, response_for(msg, {out=table.concat({...}, "\t")}))
   end
end

local print_for = function(write)
   return function(...)
      local args = {...}
      for i,x in ipairs(args) do args[i] = tostring(x) end
      table.insert(args, "\n")
      write(table.concat(args, " "))
   end
end

local read_for = function(conn, msg)
   return function()
      send(conn, response_for(msg, {status={"need-input"}}))
      while(not sessions[msg.session].input) do
         coroutine.yield()
         d("yielded")
      end
      local input = sessions[msg.session].input
      sessions[msg.session].input = nil
      return input
   end
end

local sandbox_for = function(write, provided_sandbox)
   local sandbox = { io = { write = write },
                     print = print_for(write), }
   for k,v in pairs(provided_sandbox) do
      sandbox[k] = v
   end
   return sandbox
end

-- for stuff that's shared between eval and load_file
local execute_chunk = function(session, chunk, pp)
   local old_write, old_print, old_read = io.write, print, io.read
   if(session.sandbox) then
      setfenv(chunk, session.sandbox)
      pp = pp or serpent_pp(session.sandbox.print)
   else
      _G.print = print_for(session.write)
      _G.io.write, _G.io.read = session.write, session.read
      pp = pp or serpent_pp(_G.print)
   end

   local trace, err
   local result = {xpcall(chunk, function(e)
                             trace = debug.traceback()
                             err = e end)}

   _G.print, _G.io.write, _G.io.read = old_print, old_write, old_read

   if(result[1]) then
      local res, i = pp(result[2]), 3
      while i <= #result do
         res = res .. ', ' .. pp(result[i])
         i = i + 1
      end
      return res
   else
      return nil, (err or "Unknown error") .. "\n" .. trace
   end
end

local eval = function(session, code, pp)
   local chunk, err = load("return " .. code, "*socket*")
   if(err and not chunk) then -- statement, not expression
      chunk, err = load(code, "*socket*")
      if(not chunk) then
         return nil, "Compilation error: " .. (err or "unknown")
      end
   end
   return execute_chunk(session, chunk, pp)
end

local load_file = function(session, file, loader)
   local chunk, err = (loader or loadfile)(file)
   if(not chunk) then
      return nil, "Compilation error in " .. file ": ".. (err or "unknown")
   end
   return execute_chunk(session, chunk)
end

local register_session = function(conn, msg, provided_sandbox)
   local session = tostring(math.random(999999999))
   local write = write_for(conn, msg)
   local sandbox = provided_sandbox and sandbox_for(write, provided_sandbox)
   sessions[session] = { conn = conn, write = write, print = print_for(write),
                         sandbox = sandbox, coros = {}}
   return response_for(msg, {["new-session"]=session, status={"done"}})
end

local unregister_session = function(msg)
   sessions[msg.session] = nil
   return response_for(msg, {status={"done"}})
end

local describe = function(msg, handlers)
   local ops = { "clone", "close", "describe", "eval", "load-file",
                 "ls-sessions", "complete", "stdin", "interrupt" }
   for op in handlers do table.insert(ops, op) end
   return response_for(msg, {ops=ops, status={"done"}})
end

local session_for = function(conn, msg, sandbox)
   local s = sessions[msg.session] or register_session(conn, msg, sandbox)
   s.write = write_for(conn, msg)
   s.read = read_for(conn, msg)
   return s
end

local complete = function(msg, sandbox)
   local clone = function(t)
      local n = {} for k,v in pairs(t) do n[k] = v end return n
   end
   local top_ctx = clone(sandbox or _G)
   for k,v in pairs(msg.libs or {}) do
      top_ctx[k] = require(v:sub(2,-2))
   end

   local function cpl_for(input_parts, ctx)
      if type(ctx) ~= "table" then return {} end
      if #input_parts == 0 and ctx ~= top_ctx then
         return ctx
      elseif #input_parts == 1 then
         local matches = {}
         for k in pairs(ctx) do
            if k:find('^' .. input_parts[1]) then
               table.insert(matches, k)
            end
         end
         return matches
      else
         local token1 = table.remove(input_parts, 1)
         return cpl_for(input_parts, ctx[token1])
      end
   end
   local input_parts = {}
   for i in string.gmatch(msg.input, "([^.%s]+)") do
      table.insert(input_parts, i)
   end
   return response_for(msg, {completions = cpl_for(input_parts, top_ctx)})
end

-- see https://github.com/clojure/tools.nrepl/blob/master/doc/ops.md
local handle = function(conn, handlers, sandbox, msg)
   if(handlers and handlers[msg.op]) then
      d("Custom op:", msg.op)
      handlers[msg.op](conn, msg, session_for(conn, msg, sandbox))
   elseif(msg.op == "clone") then
      d("New session.")
      send(conn, register_session(conn, msg, sandbox))
   elseif(msg.op == "describe") then
      d("Describe.")
      send(conn, describe(msg, handlers))
   elseif(msg.op == "eval") then
      d("Evaluating", msg.code)
      local value, err = eval(session_for(conn, msg, sandbox), msg.code, msg.pp)
      d("Got", value, err)
      -- monroe bug means you have to send done status separately
      send(conn, response_for(msg, {value=value, ex=err}))
      send(conn, response_for(msg, {status={"done"}}))
   elseif(msg.op == "load-file") then
      d("Loading file", msg.file)
      local value, err = load_file(session_for(conn, msg, sandbox),
                                   msg.file, msg.loader)
      d("Got", value, err)
      send(conn, response_for(msg, {value=value, ex=err, status={"done"}}))
   elseif(msg.op == "ls-sessions") then
      d("List sessions")
      local session_ids = {}
      for id in pairs(sessions) do table.insert(session_ids, id) end
      send(conn, response_for(msg, {sessions=session_ids, status={"done"}}))
   elseif(msg.op == "complete") then
      d("Complete", msg.input)
      local session_sandbox = session_for(conn, msg, sandbox).sandbox
      send(conn, complete(msg, session_sandbox))
   elseif(msg.op == "stdin") then
      d("Stdin", serpent.block(msg))
      sessions[msg.session].input = msg.stdin
      send(conn, response_for(msg, {status={"done"}}))
      return
   elseif(msg.op ~= "interrupt") then -- silently ignore interrupt
      send(conn, response_for(msg, {status={"unknown-op"}}))
      print("  | Unknown op", serpent.block(msg))
   end
end

local handler_coros = {}

local function receive(conn, partial)
   local s, err = conn:receive(1) -- wow this is primitive
   coroutine.yield()
   -- iterate backwards so we can safely remove
   for i=#handler_coros, 1, -1 do
      coroutine.resume(handler_coros[i])
      if(coroutine.status(handler_coros[i]) ~= "suspended") then
         table.remove(handler_coros, i)
      end
   end

   if(s) then
      return receive(conn, (partial or "") .. s)
   elseif(err == "timeout" and partial == nil) then
      return receive(conn)
   elseif(err == "timeout") then
      return partial
   else
      return nil, err
   end
end

local function handle_loop(conn, sandbox, handlers, middleware)
   local input, r_err = receive(conn)
   if(input) then
      local decoded, d_err = bencode.decode(input)
      coroutine.yield()
      if(decoded and decoded.op == "close") then
         d("End session.")
         return send(conn, unregister_session(decoded))
      elseif(decoded and decoded.op ~= "close") then
         -- If we don't spin up a coroutine here, we can't io.read, because
         -- that requires waiting for a response from the client. But most
         -- messages don't need to stick around.
         local coro = coroutine.create(handle)
         if(middleware) then
            middleware(function(msg)
                          coroutine.resume(coro, conn, handlers, sandbox, msg)
                       end, decoded)
         else
            coroutine.resume(coro, conn, handlers, sandbox, decoded)
         end
         if(coroutine.status(coro) == "suspended") then
            table.insert(handler_coros, coro)
         end
      else
         print("  | Decoding error:", d_err)
      end
      return handle_loop(conn, sandbox, handlers, middleware)
   else
      return r_err
   end
end

local connections = {}

local function loop(server, sandbox, handlers, middleware, foreground)
   socket.sleep(timeout)
   local conn, err = server:accept()
   local stop = (not foreground) and (coroutine.yield() == "stop")
   if(conn) then
      conn:settimeout(timeout)
      d("Connected.")
      local coro = coroutine.create(function()
            local ok, h_err = pcall(handle_loop, conn, sandbox, handlers, middleware)
            d("Connection closed: " .. h_err)
      end)
      table.insert(connections, coro)
      return loop(server, sandbox, handlers, middleware, foreground)
   else
      if(err ~= "timeout") then print("  | Socket error: " .. err) end
      for _,c in ipairs(connections) do coroutine.resume(c) end
      if(stop or err == "closed") then
         server:close()
         print("Server stopped.")
      else
         return loop(server, sandbox, handlers, middleware, foreground)
      end
   end
end

return {
   -- Start an nrepl socket server on the given port. For opts you can pass a
   -- table with foreground=true to run in the foreground, debug=true for
   -- verbose logging, and sandbox={...} to evaluate all code in a sandbox.  You
   -- can also give an opts.handlers table keying ops to handler functions which
   -- take the socket, the decoded message, and the optional sandbox table.
   start = function(port, opts)
      port = port or 7888
      opts = opts or {}
      -- host should always be localhost on a PC, but not always on a micro
      local server = assert(socket.bind(opts.host or "localhost", port))
      if(opts.debug) then d = print end
      if(opts.timeout) then timeout = tonumber(opts.timeout) end

      server:settimeout(timeout)
      print("Server started on port " .. port .. "...")
      if opts.foreground then
         return loop(server, opts.sandbox, opts.handlers,
                     opts.middleware, opts.foreground)
      else
         return coroutine.create(function()
               loop(server, opts.sandbox, opts.handlers, opts.middleware)
         end)
      end
   end,

   -- Pass in the coroutine from jeejah.start to this function to stop it.
   stop = function(coro)
      coroutine.resume(coro, "stop")
   end,

   broadcast = function(msg)
      for _,session in pairs(sessions) do
         send(session.conn, msg)
      end
   end,
}
