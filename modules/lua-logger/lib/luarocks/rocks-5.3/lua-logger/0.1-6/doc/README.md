## General Information

### Contributors

| Name            | Email                | GitHub Account |
| ----------------|----------------------|--------------- |
| Charles Heywood | charles@hashbang.sh  | ChickenNuggers |

### Project Information

I've always found myself having to rewrite a logging library, so I decided
to just keep my current version stored in a repository. The logger itself
is IRC-color-compatible along with xterm color code compatible.

This library is not intended to be used by anyone else but if someone wants
it they can feel free to have it. I place no restrictions on the usage of
this logger except for the requirements in the LICENSE file.

## Examples

**MoonScript**:

```moonscript
logger = require 'logger'

logger.print 'Hello World!'
logger.print '\00311Colors test!'

logger.set_color false
logger.print '\00311Colors test 2!'

logger.debug 'Goodbye World!'
logger.set_debug true
logger.debug 'Hello World!'
```

**Lua**:

```lua
local logger = require("logger")

logger.print("Hello World!")
logger.print("\00311Colors test!")

logger.set_color(false)
logger.print("\00311Colors test 2!")

logger.debug("Goodbye World!")
logger.set_debug(true)
logger.debug("Hello World!")
```
