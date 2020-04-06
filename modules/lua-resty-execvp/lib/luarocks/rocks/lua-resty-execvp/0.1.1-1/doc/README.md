lua-resty-execvp [![CircleCI](https://circleci.com/gh/3scale/lua-resty-execvp.svg?style=svg)](https://circleci.com/gh/3scale/lua-resty-execvp)
====

lua-resty-execvp - FFI wrapper for execvp syscall.


Table of Contents
=================

* [Name](#name)
* [Status](#status)
* [Description](#description)
* [Synopsis](#synopsis)
* [Methods](#methods)
    * [get](#get)
    * [set](#set)
    * [value](#value)
    * [enabled](#enabled)
    * [reset](#reset)
* [Installation](#installation)
* [TODO](#todo)
* [Community](#community)
* [Bugs and Patches](#bugs-and-patches)
* [Author](#author)
* [Copyright and License](#copyright-and-license)
* [See Also](#see-also)

Status
======

This library is considered production ready.

Description
===========

This Lua library is very simple wrapper using FFI to call `execvp(const char *path, char *const argv[])`.

This library can replace current process with some other and pass arguments and environment. 

Synopsis
========

```lua
http {
    init_by_lua_block {
        local exec = require 'resty.execvp'
    
        exec('echo', { 'foo', 'bar' }, { SHELL = '/bin/sh' })
    }
}
```

[Back to TOC](#table-of-contents)

Methods
=======

Module itself can be called as a function.

`syntax: execvp.split(file, args, env)`

Replaces current process with execution of `file` passing it list of `args` and optionally setting `env` variables.

[Back to TOC](#table-of-contents)


Installation
============

If you are using the OpenResty bundle (http://openresty.org ), then
you can use [opm](https://github.com/openresty/opm#synopsis) to install this package.

```shell
opm get 3scale/lua-resty-execvp
```

[Back to TOC](#table-of-contents)

Bugs and Patches
================

Please report bugs or submit patches by

1. creating a ticket on the [GitHub Issue Tracker](http://github.com/3scale/lua-resty-execvp/issues),

[Back to TOC](#table-of-contents)

Author
======

Michal "mikz" Cichra <mcichra@redhat.com>, Red Hat Inc.

[Back to TOC](#table-of-contents)

Copyright and License
=====================

This module is licensed under the Apache License Version 2.0.

Copyright (C) 2016-2017, Red Hat Inc.

All rights reserved.

See [LICENSE](LICENSE) for the full license.

[Back to TOC](#table-of-contents)

See Also
========
* the APIcast API Gateway: https://github.com/3scale/apicast/#readme

[Back to TOC](#table-of-contents)
