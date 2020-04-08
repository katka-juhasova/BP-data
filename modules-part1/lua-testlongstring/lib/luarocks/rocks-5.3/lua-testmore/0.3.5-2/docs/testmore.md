
# Test.More

---

# Reference

All functions are injected in the global environment `_G`.

#### plan( arg )

```lua
plan(2)

pass "one"
pass "two"
```

gives

```text
1..2
ok 1 - one
ok 2 - two
```

#### done_testing( num_tests )

```lua
plan 'no_plan'

pass "one"
pass "two"
done_testing()
```

gives

```text
ok 1 - one
ok 2 - two
1..2
```

#### skip_all( reason )

```lua
if everything_looks_good then
    plan(7)
else
    skip_all "looks bad"
end
```

gives

```text
1..0 # SKIP looks bad
```

#### BAIL_OUT( reason )

```lua
plan(7)

if not require_ok 'MyApp' then
    BAIL_OUT "no MyApp"
end
```

gives

```text
1..7
not ok 1 - require 'MyApp'
#     module 'MyApp' not found:
#       no field package.preload['MyApp']
#       no file '.\MyApp.lua'
#       ...
Bail out!  no MyApp
```

and breaks the execution of `prove`.

#### subtest( name, func )

```lua
plan(3)
pass "First test"
subtest('An example subtest', function ()
    plan(2)
    pass "This is a subtest"
    pass "So is this"
end)
pass "Third test"
```

gives

```text
1..3
ok 1 - First test
# Subtest: An example subtest
    1..2
    ok 1 - This is a subtest
    ok 2 - So is this
ok 2 - An example subtest
ok 3 - Third test
```

#### ok( test [, name] )

#### nok( test [, name] )

#### is( got, expected [, name] )

#### isnt( got, expected [, name] )

#### like( got, pattern [, name] )

#### unlike( got, pattern [, name] )

#### cmp_ok( this, op, that [, name] )

#### type_ok( val, t [, name] )

#### pass( name )

#### fail( name )

#### require_ok( mod )

#### eq_array( got, expected [, name] )

#### is_deeply( got, expected [, name] )

#### error_is( code [, params_array], expected [, name] )

#### error_like( code [, params_array], pattern [, name] )

#### lives_ok( code [, params_array] [, name] )

#### diag( msg )

#### note( msg )

#### skip( reason [, count] )

```lua
plan(4)

pass "one"

if true then
    skip("here, segfault", 2)
else
    fail "two"
    fail "three"
end

pass "four"
```

gives

```text
1..4
ok 1 - one
ok 2 - # skip here, segfault
ok 3 - # skip here, segfault
ok 4 - four
```

#### todo_skip( reason [, count] )

```lua
plan(3)

pass "one"

if true then
    todo_skip "here, segfault"
else
    fail "two"
end

pass "three"
```

gives

```text
1..3
ok 1 - one
not ok 2 - # TODO & SKIP here, segfault
ok 3 - three
```

#### skip_rest( reason )

```lua
plan(3)

if not require_ok 'MyApp' then
    skip_rest "no MyApp"
    os.exit()
end

pass "two"
pass "three"
```

gives

```text
1..3
not ok 1 - require 'MyApp'
#     module 'MyApp' not found:
#       no field package.preload['MyApp']
#       no file '.\MyApp.lua'
#       ...
ok 2 - # skip no MyApp
ok 3 - # skip no MyApp
```

#### todo( reason [, count] )

```lua
plan(4)

pass "one"

todo( "not yet implemented", 2 )
fail "two"
fail "three"

pass "four"
```

gives

```text
1..4
ok 1 - one
not ok 2 - two # TODO # not yet implemented
not ok 3 - three # TODO # not yet implemented
ok 4 - four
```

# Examples

```lua
-- 99example.t
#!/usr/bin/lua
require 'Test.More'

plan(9)

ok(true, "true")
ok(1, "1 is true")
nok(false, "false")
nok(nil, "nil is false")

is(1 + 1, 2, "addition")

like("with aaa", 'a', "pattern matches")
unlike("with aaa", 'b', "pattern doesn't match")

error_like([[error 'MSG']], '^[^:]+:%d+: MSG', "loadstring error")
error_is(error, { 'MSG' }, 'MSG', "function error with param")
```

```text
$ lua 99example.t
1..9
ok 1 - true
ok 2 - 1 is true
ok 3 - false
ok 4 - nil is false
ok 5 - addition
ok 6 - pattern matches
ok 7 - pattern doesn't match
ok 8 - loadstring error
ok 9 - function error with param
```

Now, with [prove](http://search.cpan.org/~andya/Test-Harness/bin/prove).

```text
$ prove 99example.t
99example.t .. ok
All tests successful.
Files=1, Tests=9,  0 wallclock secs ( 0.05 usr +  0.20 sys =  0.25 CPU)
Result: PASS
```

If your continuous integration tool
(for example, [Jenkins](http://jenkins-ci.org/))
requires the JUnix XML format.

```xml
$ prove --formatter=TAP::Formatter::JUnit 99example.t
<testsuites>
  <testsuite failures="0"
             errors="0"
             tests="9"
             name="test_99example_t">
    <testcase name="1 - true"></testcase>
    <testcase name="2 - 1 is true"></testcase>
    <testcase name="3 - false"></testcase>
    <testcase name="4 - nil is false"></testcase>
    <testcase name="5 - addition"></testcase>
    <testcase name="6 - pattern matches"></testcase>
    <testcase name="7 - pattern doesn't match"></testcase>
    <testcase name="8 - loadstring error"></testcase>
    <testcase name="9 - function error with param"></testcase>
    <system-out><![CDATA[1..9
ok 1 - true
ok 2 - 1 is true
ok 3 - false
ok 4 - nil is false
ok 5 - addition
ok 6 - pattern matches
ok 7 - pattern doesn't match
ok 8 - loadstring error
ok 9 - function error with param
]]></system-out>
    <system-err></system-err>
  </testsuite>
</testsuites>
```

If your results must be stored first, and processed after.

```text
$ lua 99example.t > 99example.tap
$ prove --source=TAP::Parser::SourceHandler::RawTAP 99example.tap
99example.tap .. ok
All tests successful.
Files=1, Tests=9,  0 wallclock secs ( 0.02 usr +  0.04 sys =  0.06 CPU)
Result: PASS
```
