-------------------------------------------------------
--      localexec
--      Written by Erik Poupaert, Cambodia
--      (c) 2019
--      Licensed under the LGPL
-------------------------------------------------------

local funcs={}

-------
-- interpolate a string
-------
local string_interp=function(str, t)
  return (str:gsub('($%b{})', function(w) return t[w:sub(3, -2)] or w end))
end

-------
-- escape every single quotes and surround result with single quotes
-------
local string_escapeshellarg=function(str)
    return "'" .. str:gsub("'","'\"'\"'") .. "'"
end

-------
-- (functional programming) map
-------
local map=function(t_in,func)
    local t_out = {}
    for k,v in pairs(t_in) do
        table.insert(t_out,func(k,v))
    end
    return t_out
end

-------
-- return true, if table is empty
-------
local table_empty=function(t) 
    if t ~= nil then
        return next(t) == nil 
    else
        return true
    end
end

-------
-- serializes table using function supplied
-------
local table_serialize=function(t,func)
    if table_empty(t) then return "" end
    return table.concat(map(t,func)," ")
end

-------
-- inserts string into table, if string is not empty
-------
local table_insert_ifnotempty=function(t,str)
    if str ~= "" then table.insert(t,str) end
end

-------
-- serializes env, cmd, and args into an executable program string
-- env1=val1 env2=val2 ... program arg1 arg2 ...
-------
local shell_program=function(processInput)
    local t={}
    -- serializes a table to string { k1=v1, k2=v2, ... } ==> "k1=v1 k2=v2 ...", while shell-escaping the values
    table_insert_ifnotempty(t,table_serialize(processInput.env,function(k,v) return 
            string_interp("${k}=${v}", {k=k, v=string_escapeshellarg(v)}) end))
    assert(processInput.cmd ~= nil, "cmd field mandatory")
    table.insert(t,processInput.cmd)
    -- serializes a table to string { v1, v2, ... } ==> "v1 v2 ...", while shell-escaping the values
    table_insert_ifnotempty(t,table_serialize(processInput.args,function(k,v) return 
            string_escapeshellarg(v) end))
    return table.concat(t," ")
end

-------
-- generate temporary file name
-------
local temp_filename=function()
    return string.match(os.tmpname(),"/tmp/(.*)")
end

-------
-- generate ipc (inter-process-communcation) file paths
-- for stdin, stdout, sterr, and saving retcode
-------
local filepaths_ipc=function(tmpFileName)
    function ipcFilePath(path,ext) return string_interp("${path}.${ext}",{path=path,ext=ext}) end
    local filePathBase="/dev/shm/"..tmpFileName
    return {
          stdin=ipcFilePath(filePathBase,"stdin")
        , stdout=ipcFilePath(filePathBase,"stdout")
        , stderr=ipcFilePath(filePathBase,"stderr")
        , retcode=ipcFilePath(filePathBase,"retcode")
    }
end

-------
-- serializes stdin, env, cmd, args into executable expression
-- reading/writing from/to shared memory files
-- cat stdin | shell_program > stdout 2> stderr
-------
local shell_statement=function(processInput,filePaths) 
    local stdinString=""    
    if processInput.stdin ~= nil then
        stdinString=string_interp("cat ${path} |",{path=filePaths.stdin})
    end

    local t={}
    table_insert_ifnotempty(t,stdinString)
    table.insert(t,shell_program(processInput))
    table.insert(t,string_interp("> ${path}",{path=filePaths.stdout}))
    table.insert(t,string_interp("2> ${path}",{path=filePaths.stderr}))
    table.insert(t,string_interp("; echo $? > ${path}",{path=filePaths.retcode}))
    return table.concat(t," ")
end

-------
-- writes string to shared memory file
-------
local shm_write_stdinfile=function(path,str)
    local file=io.open(path, "w+")
    file:write(str)
    file:close()
end

-------
-- reads string from shared memory file
-------
local shm_read_outputfile=function(path)
    local file=io.open(path,"r")
    local output=file:read("*a")
    file:close()
    os.remove(path)
    return output
end

-------------------------------------------------------
-- processInput:

--      optional: stdin=<string>
--      optional: env={ env1=val1, env2=val2, ... }
--      optional: args={ arg1, arg2, ... }
--      required: cmd=program

-- returning processOutput:

--      result = true or nil
--      retcode = <integer>
--      stdout = <string>
--      stderr = <string>
-------------------------------------------------------

local spawn=function (processInput)

    -------
    -- validate env keys
    -------

    if processInput.env ~= nil then 
        for k,_ in pairs(processInput.env) do
            assert(string.match(k,"^[a-zA-Z0-9_%-]+$"), "env key "..k.." is invalid")
        end
    end

    local tmpFileName=temp_filename()
    local filePaths=filepaths_ipc(tmpFileName)
    local shellCmd=shell_statement(processInput,filePaths)

    if processInput.stdin ~= nil then shm_write_stdinfile(filePaths.stdin,processInput.stdin) end

    local luaresult=os.execute(shellCmd)

    if processInput.stdin ~= nil then os.remove(filePaths.stdin) end

    return { 
            luaresult=luaresult,
            retcode=tonumber(shm_read_outputfile(filePaths.retcode)), 
            stdout=shm_read_outputfile(filePaths.stdout), 
            stderr=shm_read_outputfile(filePaths.stderr) 
    }
end

-- for test purposes
funcs.string_interp=string_interp
funcs.string_escapeshellarg=string_escapeshellarg
funcs.map=map
funcs.table_empty=table_empty
funcs.table_serialize=table_serialize
funcs.table_insert_ifnotempty=table_insert_ifnotempty
funcs.shell_program=shell_program
funcs.temp_filename=temp_filename
funcs.filepaths_ipc=filepaths_ipc
funcs.shell_statement=shell_statement
funcs.shm_write_stdinfile=shm_write_stdinfile
funcs.shm_read_outputfile=shm_read_outputfile

-- only real export
funcs.spawn=spawn

return funcs

