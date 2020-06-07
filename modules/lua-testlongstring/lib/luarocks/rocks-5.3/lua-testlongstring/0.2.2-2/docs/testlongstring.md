
# Test.LongString

---

# Reference

#### is_string( got, expected [, name] )

`is_string()` is equivalent to `Test.More.is()`,
but with more helpful diagnostics in case of failure.

- It doesn't print the entire strings in the failure message.
- It reports the lengths of the strings that have been compared.
- It reports the length of the common prefix of the strings.
- In the diagnostics, non-ASCII characters are escaped as `\ddd`.

#### is_string_nows( got, expected [, name] )

Like `is_string()`, but removes whitepace (in the `%s` sense)
from the arguments before comparing them.

#### like_string( got, pattern [, name] )

#### unlike_string( got, pattern [, name] )

`like_string()` and `unlike_string()` are replacements
for `Test.More.like()` and `unlike()`
that only print the beginning of the received string in the output.
Unfortunately, they can't print out the position where the regex failed to match.

#### contains_string( string, substring [, name] )

`contains_string()` searches for `substring` in `string`.
It's the same as `like_string()`,
except that it's not a regular expression search.

#### lacks_string( string, substring [, name] )

`lacks_string()` makes sure that `substring` does NOT exist in `string`.
It's the same as `unlike_string()`,
except that it's not a regular expression search.

# Examples

```lua
require 'Test.More'
require 'Test.LongString'

plan(5)

is_string('str', 'str', "is_string")
like_string('str', '^%w+', "like_string")
unlike_string('str', '^%d+', "unlike_string")
contains_string('a string', 'str', "contains_string")
lacks_string('a string', 'STR', "lacks_string")
```
