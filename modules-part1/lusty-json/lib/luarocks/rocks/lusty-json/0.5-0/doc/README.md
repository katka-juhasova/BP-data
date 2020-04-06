lusty-json
==========

Version 1.0

add json input and output handling to your lusty requests. automatically
decodes or encodes based on content type / accept type http headers.

output writes the result of `context.output` as the json response.

Require it in your config:

```lua
local config = {
  --...
  input = {
    ['lusty-json.input'] = { }
  },
  -...
  output = {
    ['lusty-json.output'] = { }
  }
}
```


License
-------
Copyright 2013 Olivine Labs, LLC. MIT licensed. See LICENSE file for details.
