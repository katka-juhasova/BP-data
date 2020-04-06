# Name

lua-resty-tasker - A multi light thread task manager based on `ngx.thread`

## Table of Contents

* [Name](#Name)
* [Status](#Status)
* [Description](#Description)
* [Synopsis](#Synopsis)
* [Methods](#Methods)
    * [spawn](#spawn)
* [Author](#Author)
* [Copyright and License](#Copyright and License)



## Status

This module currently ready for production.

## Description

This is a module specific for `resty-cli`. Which allows you run a worker daemon on different
tasks. The `lua-resty-tasker` module will die when it get's any signals, but it helps you maintain light-thread workers.

To clearify that, checkout the [nginx signal official documentation](http://nginx.org/en/docs/control.html)

DON'T RUN IT IN THE ACTUAL NGINX WORKER/MASTER PROCESS, RESTY-CLI ONLY.

## Synopsis

```lua
#!/usr/local/openresty/bin/resty

local tasker = require 'resty.tasker'
local worker = require 'resty.upstream.worker'

local tasks = {
    { task = worker.run, params = { { src = { name = 'foo', ... }, dest = { ... } },
    { task = worker.run, params = { { src = { name = 'bar', ... }, dest = { ... } } 
}

local ok, err = tasker.spawn(tasks)
if not ok then
    print(err)
end
```

## Methods

### spawn

Syntax `local ok, err = spawn({ ... })`

Spawn a list of tasks using task definition. It takes a list of task definition as argument and run
the `task` field.

```lua
type Task = {
    task = * -> <ngx.thread>,
    params = [arguments]
}
```

After you define a lots of tasks, then you can do:

```lua
tasker.spawn({
    ...
    ... 
})
```

This operation will run within a infinite loop. So the only way to stop this is killing the `resty` process
by sending `SIGINT` or `SIGTERM` or `SIGKILL`.


## Author

Zekai "kiddkai" Zheng kiddkai@gmail.com

## Copyright and License

This module is licensed under the BSD license.

Copyright (C) 2012-2016, by Zekai "kiddkai" Zheng kiddkai@gmail.com.

All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
