# mockuna
[![Build Status](https://travis-ci.org/kraftman/mockuna.svg?branch=master)](https://travis-ci.org/kraftman/mokuna) [![codecov](https://codecov.io/gh/kraftman/mockuna/branch/master/graph/badge.svg)](https://codecov.io/gh/kraftman/mockuna)

Lua mocking framework based on [sinon](http://sinonjs.org/)

### Key differences from sinon.
The sinon API is stuck to where possible, the exceptions are:
- Spy/stub methods use Lua's colon syntax rather than dot syntax
- As lua supports multiple returns, return related methods support passing in multiple values
- Doesn't support stubbing the entire object as it is bad practise

<!--ts-->
   * [Usage](#usage)
   * [API](#api)
      * [Spies](#spies)
      * [Stubs](#stubs)
<!--te-->

## Usage
Basic busted example:

```lua
local mockuna = require '../lib/mockuna'
local mockable = {
    test = function()
        return 'not mocked'
    end
}

describe('test', function()
    local newMock
    before_each(function()
        local mockFunction = function() return 'mocked' end
        newMock = mockuna:stub(mockable, 'test', mockFunction)
    end)

    after_each(function()
        newMock:restore();
    end)

    it('it mocks out a method', function()
        local result = mockable.test()
        assert(result == 'mocked')
    end)
end)

```

## API

Spies:
======

Spies watch functions and record what goes into them, out of them, 
how many times they were called, and any exceptions they threw

Creating spies:

```lua
local mockable = require '../lib/mockable'
local mockuna = require 'mockuna'
local spy = mockuna:spy(mockable, 'test')
```

Spy API

#### Spy properties

`spy.callCount`
- The number of recorded calls.

`spy.called`
- True if the spy was called one or more times.

`spy.notCalled`
- False if the spy was called one or more times.

`spy.calledOnce` / `calledTwice` / `calledThrice`
- Shortcuts for spy.callCount() == 1, etc.

`spy.fistCall` / `secondCall` / `thirdCall`
- The first, second or third call.

`spy.lastCall`
- The last call

`spy.args`
- Arguments recieved by the spy. `spy.args[1][1]` would be the firt argument of the first call of the spy

`spy.exceptions`
- exceptions per call, or nil if no exception was thrown

### Call Methods:

`spy:calledBefore(anotherSpy)`
- True if the spy was called before another spy/stub.

`spy:calledAfter`
- True if the spy was called after another spy/stub.

`spy:calledImmediatelyBefore(anotherSpy)`
- True if the spy was called imme

`spy:calledWith(arg1, arg2, ...)`
- True if the spy was called with the provided arguments one or more times

`spy:calledOnceWith(arg1, arg2, ...)`
- True if the spy was called with the provided arguments once.

`spy:alwaysCalledWith(arg1, arg2, ...)`
- True if every call to the spy contained the provided arguments

`spy:calledWithExactly(arg1, arg2, ...)`
- True if the call was called one or more times with the provided arguments and no others

`spy:calledOnceWithExactly(arg1, arg2, ...)`
- True if the call was only called once with the exact arguments provided

`spy:alwaysCalledWithExactly(arg1, arg2, ...)`
- True if every call matched the arguments provided and not others

`spy:neverCalledWith(arg1, arg2, ...)`
- True if the call was never called with the provided arguments

Return methods:
`spy:returned(arg1, arg2, ...)`
- True if the spy returned the provided arguments

`spy:alwaysReturned(arg1, arg2, ...)`
- True if every return of the spy matches the provided arguments

Other Methods:
`spy:getCall(n)`
- Returns the nth call
`spy:getCalls()`
- Returns all the calls recorded by the spy


Stubs
=====

Stubs extend spies by overriding the values the the function returns.

Creating Stubs:

```lua
local mockuna = require 'mockuna'
local fakeFunction = function()
    return 'from fake'
end
local spy = mockuna:spy(mockable, 'test', fakeFunction)
```

`mockuna:stub(table, "methodName", function)`
- Replace the method if it exists, returns a stub

`stub:withArgs(arg1, arg2, ...)`
- Stubs the method only if the provided arguments are passed in

`stub:onCall(n)`
Specifies the return function for the nth call.

`stub:resetHistory()`
- Resets the stubs callCount, args, etc

`stub:resetBehaviour()`
- Resets the behaviour of the stub set by withArgs or onCall

`stub:reset()`
- Resets both history and behaviour
