

local mocker = {}
local callObj = require 'mockuna.call'

local allCalls = {}
local allMocks = {}
local mockBase = {}

function mockBase:findMockPairs(otherMock)
  local firstFoundAt, secondFoundAt = 0,0
  for i = 1, #allCalls do
    if allCalls[i] == self then
      firstFoundAt = i
    elseif allCalls[i] == otherMock then
      secondFoundAt = i
    end
  end
  return firstFoundAt, secondFoundAt
end

function mockBase:calledBefore(otherMock)
  local firstFoundAt, secondFoundAt = self:findMockPairs(otherMock)
  return firstFoundAt < secondFoundAt
end


function mockBase:calledAfter(otherMock)
  local firstFoundAt, secondFoundAt = self:findMockPairs(otherMock)
  return firstFoundAt > secondFoundAt
end

function mockBase:calledImmediatelyBefore(otherMock)
  local firstFoundAt, secondFoundAt = self:findMockPairs(otherMock)
  if firstFoundAt + secondFoundAt == 0 then
    return false
  end
  return secondFoundAt - firstFoundAt == 1
end

function mockBase:calledImmediatelyAfter(otherMock)
  local firstFoundAt, secondFoundAt = self:findMockPairs(otherMock)
  if firstFoundAt + secondFoundAt == 0 then
    return false
  end
  return firstFoundAt - secondFoundAt == 1
end

function mockBase:addArgs(args)
  for _,v in pairs(args) do
    self.__allArgs[v] = true
  end
  table.insert(self.args, args)
end

function mockBase:calledWithCount(...)
  local count = 0
  for _, call in pairs(self.calls) do
    if call:calledWith(...) then
      count = count + 1
    end
  end
  return count
end

function mockBase:threwCount(errorMessage)
  local count = 0
  for _, call in pairs(self.calls) do
    if call:threw(errorMessage) then
      count = count + 1
    end
  end
  return count
end

function mockBase:threw(errorMessage)
  return self:threwCount(errorMessage) > 0
end

function mockBase:alwaysThrew(errorMessage)
  return self:threwCount(errorMessage) == self.callCount
end

function mockBase:calledWith(...)
  return self:calledWithCount(...) > 0
end

function mockBase:neverCalledWith(...)
  return self:calledWithCount(...) == 0
end

function mockBase:calledWithExactlyCount(...)
  local count = 0
  for _, call in pairs(self.calls) do
    if call:calledWithExactly(...) then
      count = count + 1
    end
  end
  return count
end

function mockBase:calledWithExactly(...)
  return self:calledWithExactlyCount(...) > 0
end

function mockBase:calledOnceWithExactly(...)
  return self:calledWithExactlyCount(...) == 1
end

function mockBase:alwaysCalledWithExactly(...)
  return self:calledWithExactlyCount(...) == self.callCount
end

function mockBase:returnedCount(...)
  local count = 0
  for _, call in pairs(self.calls) do
    if call:returned(...) then
      count = count + 1
    end
  end
  return count
end

function mockBase:returnedExactlyCount(...)
  local count = 0
  for _, call in pairs(self.calls) do
    if call:returnedExactly(...) then
      count = count + 1
    end
  end

  return count
end

function mockBase:returned(...)
  return self:returnedCount(...) > 0
end

function mockBase:alwaysReturned(...)
  return self:returnedCount(...) == self.callCount
end

function mockBase:returnedExactly(...)
  return self:returnedExactlyCount(...) > 0
end

function mockBase:alwaysReturnedExactly(...)
  return self:returnedExactlyCount(...) == self.callCount
end

function mockBase:getCall(index)
  return self.calls[index]
end

function mockBase:getCalls()
  return self.calls
end

local function containsArgs(argSet1, argSet2)
  for k,v in ipairs(argSet1) do
    if argSet2[k] ~= v then
      return
    end
  end
  return true
end

function mockBase:__getArgReturn(...)
  local args = {...}
  for _, argReturn in pairs(self.__argReturns) do
    if containsArgs(argReturn.args, args) then
      return argReturn.method
    end
  end
  return nil
end

function mockBase:__getmethod(...)
  local callReturn = self.__callReturns[self.callCount]
  local argReturn = self:__getArgReturn(...)

  return callReturn or argReturn or self.__newFunction
end

function mockBase.call(self, ...)
  self.callCount = self.callCount + 1
  local correctMethod = self:__getmethod(...)
  local newCall = callObj:new(self, correctMethod, ...)
  self:addArgs(newCall.args)
  table.insert(self.calls, newCall)
  table.insert(allCalls, self)

  local results = table.pack(newCall:call())
  table.insert(self.returnValues, results)
  table.insert(self.exceptions, newCall.exceptionMessage or nil)

  if newCall.exceptionMessage then
    return error(newCall.exceptionMessage)
  end
  
  return unpack(results)
end

function mockBase:resetBehaviour()
  self.__callReturns = {}
  self.__argReturns = {}
end

function mockBase:resetHistory()
  self.callCount = 0
  self.args = {}
  self.returnValues = {}
  self.calls = {}
  self.__allArgs = {}
  self.exceptions = {}
end

function mockBase:reset()
  self:resetHistory()
  self:resetBehaviour()
end

function mockBase:restore()
  self.__originalParent[self.__originalName] = self.__originalFunction
end

function mockBase:returns(newFunction)
  self.__newFunction = newFunction
end

function mockBase:__addCallReturns(index, ...)
  local returns = {...}
  self.__callReturns[index] = function()
    return unpack(returns)
  end
end

function mockBase:__addArgReturns(args, ...)
  local returns = {...}
  table.insert(self.__argReturns, {args = args, method = function()
    return unpack(returns)
  end})
end

function mockBase:onCall(index)
  if type(index) ~= 'number' then
    error('onCall(n) must be an integer')
  end
  local parent = self
  return {
    returns = function(_, ...)
      parent:__addCallReturns(index, ...)
    end
  }
end

function mockBase:onFirstCall()
  return self:onCall(1)
end

function mockBase:onSecondCall()
  return self:onCall(2)
end

function mockBase:onThirdCall()
  return self:onCall(3)
end

function mockBase:withArgs(...)
  local parent = self
  local args = {...}
  return {
    returns = function(_, ...)
      parent:__addArgReturns(args, ...)
    end
  }
end

local getters = {}


getters.calledOnce = function(mock)
  return mock.callCount == 1
end

getters.calledTwice = function(mock)
  return mock.callCount == 2
end

getters.calledThrice = function(mock)
  return mock.callCount == 3
end

getters.called = function(mock)
  return mock.callCount > 0
end

getters.notCalled = function(mock)
  return mock.callCount == 0
end

getters.firstCall = function(mock)
  return mock.calls[1]
end

getters.secondCall = function(mock)
  return mock.calls[2]
end

getters.thirdCall = function(mock)
  return mock.calls[3]
end

getters.lastCall = function(mock)
  return mock.calls[#mock.calls]
end


local createMock = function(parent, originalName, originalFunction, newFunction)
  local mock = {}
  setmetatable(mock, mock)
  mock.callCount = 0
  mock.__originalParent = parent
  mock.__originalFunction = originalFunction
  mock.__originalName = originalName
  mock.__type = 'mock'
  mock.__call = mockBase.call
  mock.__index = function(self, key)
    if getters[key] then
      return getters[key](self)
    end
    return mockBase[key]
  end

  mock:reset()
  mock:returns(newFunction)
  table.insert(allMocks, mock)
  return mock
end

function mocker:stub(parent, methodName, stubFunction)
  local originalFunction = parent and parent[methodName]
  if parent and not originalFunction then
    return error('class does not have method: '..methodName)
  end
  if type(originalFunction) == 'table' and originalFunction.__type == 'mock' then
    error('already mocked')
  end
  local mock = createMock(parent, methodName, originalFunction, stubFunction)
  if parent then
    parent[methodName] = mock
  end
  return mock
end

function mocker:spy(parent, methodName)
  return self:stub(parent, methodName)
end

function mocker:reset()
  allCalls = {}
end

return mocker
