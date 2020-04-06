local sig = require 'posix.signal'
local ngx = require 'ngx'
local kill = ngx.thread.kill
local wait = ngx.thread.wait
local log = ngx.log
local ERR = ngx.ERR
local signal = sig.signal
local SIGINT = sig.SIGINT
local SIGTERM = sig.SIGTERM
local SIGHUP = sig.SIGHUP
local status = coroutine.status
local DEAD = 'dead'
local _M = {}


local function resume_dead_task(tasks, threads)
    for i = 1, #tasks do
        if status(threads[i]) == DEAD then
            threads[i] = tasks[i].task(unpack(tasks[i].params))
        end
    end
end


function _M.spawn(tasks)
    local threads = {}
    for i, task in ipairs(tasks) do
        local t, err = task.task(unpack(task.params))
        if not t then
            for j = 1, #threads do
                kill(threads[j])
            end
            return nil, err
        end
    end

    local sig_handler = function ()
        for _, t in ipairs(threads) do
            kill(t)
        end
        os.exit()
    end

    signal(SIGINT, sig_handler)
    signal(SIGHUP, sig_handler)
    signal(SIGTERM, sig_handler)

    while true do
        local ok, err = wait(unpack(threads))
        if not ok then
            log(ERR, err)
        end

        resume_dead_task(tasks, threads)

        if #threads == 0 then
            return
        end
    end
end


return _M

