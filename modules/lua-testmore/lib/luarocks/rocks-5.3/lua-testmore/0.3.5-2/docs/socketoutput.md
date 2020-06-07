
# Test.Builder.SocketOutput

---

# Reference

This module allows to redirect the test output (`stdout/stderr`)
to a `socket`.

This feature is useful for embedded development
where the test runs into a target but the output is consumed by a host.

The use with the **Corona SDK** is described in this
[blog](http://blog.anscamobile.com/2011/08/automated-testing-on-mobile-devices-part3/).

This module requires
[LuaSocket](http://w3.impa.br/~diego/software/luasocket/).

# Examples

```lua
require 'Test.More'
require 'socket'
local conn = socket.connect(host, port)
require 'Test.Builder.SocketOutput'.init(conn)
-- now, as usual
plan(...)
...
```
