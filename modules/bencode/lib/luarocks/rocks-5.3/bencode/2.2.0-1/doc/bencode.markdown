bencode.lua API
===============

```
b = require('bencode') -- load the module
```

Lua datatypes map nicely and almost 1:1 on bencoded data types so this module
should be easy to use.

In case you're handling large amounts of data, see the bencode-push
implementation for a more efficient but slightly trickier to use way of
handling bencoded data.

Decoding bencoded data
----------------------

```
local decoded, e1, e2 = b.decode('bencoded data goes here') 
```
or
```
local decoded, e1, e2 = b.decode('bencoded data goes here', 2)
```

The first parameter is the string to decode. The second, optional parameter can
be a 1-indexed offset inside the string which will be the start of the decoding
process.

In case of an error, decoded will be nil and e1 will contain an error message.
e2 is optional and if present, contains the value that caused the error.

In case of success, exactly one list, dict, string or integer is decoded by the
function, e1 will be the 1-indexed offset of the first character behind the
part of the string which was decoded, or the end of the string in case there is
no extra data.

decoded will be one of the following:

* A table with numeric keys in case the bencoded data was of type list.

* A table with string keys in case the bencoded data was of type dict.

* A number if the data was an integer (positive or negative)

* A string if the data was a string

In case of a list or dict, the values in the dict or list are one of the above
four types. Recurse as appropriate.



Bencoding data
--------------

```
local data, err, errval = b.encode {
  'foo', 'bar', 'baz', 42,
  {
    ["hello"] = "world",
    ["tomorrow"] = "friday"
  }
}

if not data then
  print("Error:", err, errval)
else
  -- data contains the bencoded data now
end
```

The encode function returns the bencoded string representation of its sole
argument. In case of an error, it returns nil, an error message and an optional
value that caused the error.

* Tables are checked for their keys:

  * If all keys are integers and there are no gaps, a list is created.

  * If all keys are strings, they are sorted alphabetically (as required by
    the specification) and a dict is created mapping their keys to their
    values.

* Integers and strings are converted to their bencoded representations.

Recursion is applied internally in case of a table.
