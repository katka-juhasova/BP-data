TestingUnit
===========

Another unit testing library for Lua inspired by Python's `unittest`.

TestingUnit is a very simple but fairly featureful and useful unit test runner for Lua that does auto test descovery, fixtures, and expected failures.

Like Lua itself, TestingUnit is trivially easy to interface from an embedded program, which makes testing your Lua bindings straightforward.

Quick Start
===========
<!--START EXAMPLE SOURCE-->

```lua

mytest = TestingUnit{
    --[[ The testing unit base is overridden with your test method.
        All test methods are functions accepting ``self`` by convention.
    ]]
    
    --[[The fixtures table is queried for tables matching the test method name.
    
    ]]
    fixtures = {
        test_fixtures_equals={{1, 2}, {22, 22}, {'hello', 'hello'}, {0,'hello'}},
        test_fixtures_raises={{1, 2, 3,function()end}, {'a', 'b', 'c', {}}, {{},{},{},{}}},
        test_fixtures_nan_equal_expected_failure=(function()
            --generate our fixtures dynamically
            local t = {} 
            for i= 1, 1000 do 
                t[i] = {math.random()}
            end 
            return t 
        end)(),
    },
    
    setup = function(self, test_func, args)
        -- do your setup here.  Called before every test if defined.  
    end,
    
    teardown = function(self, test_func, args)
        --cleanup in aisle 2.  Called after every test if defined.
    end,
    
    test_equals_fails = function(self)
        --[[all callable members whose name begins with `test` are 
            autodiscovered by the test runner.
        ]]
            self:assert_equal(1, 2) --(fails)
    end,
    
    test_in_will_fail = function(self)
        --TestingUnit supports testing container membership
        self:assert_in('hello', 'world')            --(fails)
        
    end,
    test_in_will_pass = function(self)
        self:assert_in({1, 2, hello='world'}, 'world')     --(passes)
    end,
    
    test_a_calls_b = function(self)
        --[[TestingUnit has inbuilt support for checking that certain 
        functions call others, allowing you to test your assumptions 
        about lower abstraction levels/confirm certain conditions.
        ]]
        
        --first define some functions we want to check call other
        local function a() return("hello from a()") end
        local function b() print("Hello from b()") end
        local function c() return a() == "hello from a()" end
        
        self:assert_calls(c, a)         --(passes)
        self:assert_calls(a, b, {7})    --(fails)
    end,
    
    test_fixtures_equals = function(self, x, y)
        --[[ Tests with valid fixture data will be called 
        once per fixture with those values as arguments.
        ]]
        self:assert_equal(x, y)
    end,
    
    test_fixtures_raises = function(self, w, x, y, z)
        --[[table concat does not convert non atomic types. This test assumes 
        that behaviour will not change.
        Our test fixtures have one non-atomic argument per fixture.
        --]]
        self:assert_raises(function() return table.concat({w, x, y, z}, '|')end)
    
    end,
    
    --functions with variations of ``expected failure`` in their name 
    --will be treated as expected failures by the test runner
    test_fixtures_nan_equal_expected_failure = function(self, x)
        --[[(0/0) is guaranteed by ieee754 to never compare as equal to any value.
        Whatever the value of our fixture, this test will expected-fail 
        when the machine is ieee754
        ]]
        self:assert_equal(a, 0/0) 
    end,
}


```
<!--END EXAMPLE SOURCE-->


Save that file as `tests.lua` and run the `testingunit` script from the same directory.  All the tests will be automatically discovered, loaded and run, and you will get output like the following:
<!--START EXAMPLE OUTPUT-->
```

loading 'examples/test_readme.lua'...
======================================================================
FAILURE:test_equals_fails(1, 2)
[examples/test_readme.lua]:30
----------------------------------------------------------------------
assert_equal failed: 1 ~= 2

======================================================================
FAILURE:test_fixtures_equals(1, 2)
[examples/test_readme.lua]:61
----------------------------------------------------------------------
assert_equal failed: 1 ~= 2

======================================================================
FAILURE:test_fixtures_equals(1, 2)
[examples/test_readme.lua]:61
----------------------------------------------------------------------
assert_equal failed: 0 ~= hello

======================================================================
FAILURE:test_in_will_fail()
[examples/test_readme.lua]:37
----------------------------------------------------------------------
'world' not found in 'hello'

======================================================================
FAILURE:test_a_calls_b()
[examples/test_readme.lua]:46
----------------------------------------------------------------------
assert_calls failure:'[examples/test_readme.lua]:54' not called by '[examples/test_readme.lua]:53 with args(7)'

Ran 1011 tests in 0 seconds.
            5 failures, 1000 expected failures, 0 errors, 6 passed

```
<!--END EXAMPLE OUTPUT-->

Notes
=====

Test discovery is currently exceuted by wrapping the posix `find` command in `io.popen()` which means that this system won't work without a `find` installation in your `$PATH`. i.e. no win32 support.  If someone wants to add this without adding any `require()` calls, please submit a pull request.

Version Support
===============
TestingUnit works with Lua5.2, Lua5.1 and luajit.  Other versions may work, but have not been tested
