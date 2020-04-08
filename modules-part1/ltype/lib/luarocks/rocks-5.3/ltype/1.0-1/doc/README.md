ltype
=====

Faster type() function made by storing typenames in closure upvalues.

Usage
=====

When you `require("ltype")` the `type()` function in global namespace will be replaced with closured version.

    require("ltype")

    assert(type("abc") == "string")
