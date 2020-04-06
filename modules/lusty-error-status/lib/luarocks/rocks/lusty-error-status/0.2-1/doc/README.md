lusty-error-status
==========

Version 1.0

Handles error conditions based on status code,
specifies channels to be executed

Require it in your config:

```lua
local config = {
  --...
  error = {
    ['lusty-error.error.status'] = {
      prefix = {{'input'}},
      status = {
        500 = {{'request:500'}},
        404 = {{'request:404'}}
      },
      suffix = {{'render'}, {'output'}}
    }
  }
}
```

error codes xxx default to x00 if no specific handler specified

License
-------
Copyright 2013 Olivine Labs, LLC. MIT licensed. See LICENSE file for details.
