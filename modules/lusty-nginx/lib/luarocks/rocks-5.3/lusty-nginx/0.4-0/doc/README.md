lusty-nginx
===========

Version 1.0

nginx bindings for lusty.

Require it in your config:

```lua
local config = {
  server = require "lusty-nginx.server",
  --...
  
  log = {
    --...
    { ["lusty-nginx.log"] = {} }
  }
  -...
}
```

License
-------
Copyright 2013 Olivine Labs, LLC. MIT licensed. See LICENSE file for details.
