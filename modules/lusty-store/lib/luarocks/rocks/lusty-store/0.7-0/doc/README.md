lusty-store
===========

add storage handler publising to your context. this will publish to whatever
storage handlers need to respond (such as lusty-store-mongo).

Require it in your config:

```lua
local config = {
  --...
  context = {
    ['lusty-store.context.store'] = { }
  }
  -...
}
```

call it:

```lua
context.store({ })
```

License
-------
Copyright 2013 Olivine Labs, LLC. MIT licensed. See LICENSE file for details.
