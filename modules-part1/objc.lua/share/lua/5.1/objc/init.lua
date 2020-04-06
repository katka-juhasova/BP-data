local ffi = require "ffi"
local bit = require "bit"

require "objc/ffi-defs"
local utils = require "objc/utils"

local objc = {
  _VERSION = "0.0.1",
  _URL     = 'https://github.com/lukaskollmer/objc.lua',
  _DESCRIPTION = 'Lua ⇆ Objective-C bridge (experimental)',
}

local searchPaths = {
  "/System/Library/Frameworks/%s.framework/%s",
  "/System/Library/PrivateFrameworks/%s.framework/%s"
}

ffi.load("/usr/lib/libobjc.A.dylib", true)

local C = ffi.C

function objc.import(name, isPrivate)
  isPrivate = isPrivate or false

  local path
  if isPrivate then
    path = searchPaths[1]
  else
    path = searchPaths[2]
  end

  path = path:format(name, name)
  return ffi.load(path, true)
end

objc.import("Foundation")

local cache = {
  classes = {}
}

setmetatable(objc, {
    __index = function(t, key)
      local cachedClass = cache.classes[key]

      if cachedClass ~= nil then
        return cachedClass
      else
        local class = objc.getClass(key)
        cache.classes[key] = class
        return class
      end
    end
})

function objc.getClass(name)
  return ffi.cast("Class", C.objc_getClass(name))
end


function isClass(obj)
  return ffi.istype("Class", obj)
end

function isObject(obj)
  return ffi.istype("id", obj)
end

function objectToString(self)
  if isClass(self) then
    return ffi.string(C.class_getName(self))
  end

  if isObject(self) then
    return self:description():UTF8String()
  end
end

function SEL(selector)
  return C.sel_registerName(selector)
end

objc.SEL = SEL


function createUnrecognizedSelectorError(obj, selector, isClassMethod)
  -- the object doesn't respond to the selector, so we'll throw an error
  -- the error message should look like the messages produced by the objc runtime
  -- eg: +[NSString thisIsBS]: unrecognized selector sent to class 0x7fffbdfe9f98
  local methodType
  local objectType
  if isClassMethod == true then
    methodType = "+"
    objectType = "class"
  else
    methodType = "-"
    objectType = "instance"
  end

  local buf = ffi.new("char[?]", 25)
  local len = C.sprintf(buf, "%p", ffi.cast("void*", obj))
  local address = ffi.string(buf, len)

  local classname = ffi.string(C.class_getName(C.object_getClass(obj)))
  local selector = ffi.string(C.sel_getName(selector))

  local errorMessage = "%s[%s %s]: unrecognized selector sent to %s %s" -- TODO update error message
  return errorMessage:format(methodType, classname, selector, objectType, address)
end

local encodings = {
  ["c"] = "char",
  ["i"] = "int",
  ["s"] = "short",
  ["q"] = "long long",
  ["C"] = "unsigned char",
  ["I"] = "unsigned int",
  ["S"] = "unsigned short",
  ["L"] = "unsigned long",
  ["Q"] = "NSUInteger",
  ["f"] = "float",
  ["d"] = "double",
  ["B"] = "bool",
  ["v"] = "void",
  ["*"] = "char *",
  ["r*"] = "const char*",
  ["@"] = "id",
  ["#"] = "Class",
  [":"] = "SEL",
  ["^@"] = "id"
}

local numberConvertibleTypeEncodings = {"c", "i", "s", "q", "I", "L", "Q", "f", "d"}


-- convert a lua value (string, number or table) to its corresponding objc type
-- this even works for nested tables
function objc.ns(value)
  local type = type(value)

  if type == "string" then
    return objc.NSString:stringWithUTF8String_(value)
  elseif type == "number" then
    return objc.NSNumber:numberWithDouble_(value)
  elseif type == "table" then
    local object
    if utils.is_array(value) then
      object = objc.NSMutableArray:new()
      for index, obj in ipairs(value) do
        object:addObject_(objc.ns(obj))
      end
    else -- it's a dictionary!
      object = objc.NSMutableDictionary:new()
      for k, v in pairs(value) do
        object:setObject_forKey_(objc.ns(v), objc.ns(tostring(k)))
      end
    end
    -- object now is a NSMutable{Array|Dictionary} holding the contents of the table
    return object

  else
    return nil
  end
end



function MethodCallProxy(object, selector)
  return function(self, ...)
    --print("calling", selector, "with args", ...)

    selector = selector:gsub("_", ":")

    if type(selector) == "string" then
      selector = SEL(selector)
    end

    local isClass = isClass(self)
    local method

    if isClass then
      method = C.class_getClassMethod(self, selector)
    else
      local class = C.object_getClass(self)
      method = C.class_getInstanceMethod(class, selector)
    end

    if isClass then
      self = ffi.cast("id", self)
    end

    if method == nil then
      error(createUnrecognizedSelectorError(self, selector, isClass))
    end

    -- map _self, _sel and the varargs passed into a table
    local argv = {self, selector}
    for i, v in ipairs{...} do
      argv[i + 2] = v
    end

    -- cast all arguments to the expected type
    local argc = C.method_getNumberOfArguments(method)
    for i = 0, argc - 1 do
      local arg = argv[i + 1]
      local argumentEncoding = ffi.string(C.method_copyArgumentType(method, i))
      --print(argumentEncoding)

      -- the method expects an objc object, but we got a lua object
      if argumentEncoding == "@" and type(arg) ~= "cdata" then
        arg = objc.ns(arg)
      end

      if argumentEncoding == "@?" then
        break -- we don't need to cast blocks, they're magical :)
      end

      argv[i + 1] = ffi.cast(encodings[argumentEncoding], arg)
    end

    -- get the return type, call the method
    local returnTypeEncoding = ffi.string(C.method_copyReturnType(method))
    local retval = C.objc_msgSend(unpack(argv))

    -- return the object returned from the objc runtime - cast if needed
    local returnType = encodings[returnTypeEncoding]

    if returnTypeEncoding == "@" then
      return retval -- TODO maybe retain
    elseif utils.has_value(numberConvertibleTypeEncodings, returnTypeEncoding) then
      return tonumber(ffi.cast(returnType, retval))
    elseif returnTypeEncoding == "r" or returnTypeEncoding == "r*" then
      return ffi.string(ffi.cast(returnType, retval))
    elseif returnTypeEncoding == "v" then
      return nil
    else
      return ffi.cast(returnType, retval)
    end
  end
end


local runtime_metatable = {
  __tostring = objectToString,
  __index = MethodCallProxy
}

ffi.metatype("struct objc_object", runtime_metatable)
ffi.metatype("struct objc_class", runtime_metatable)
ffi.metatype("struct objc_selector", { __tostring = function(sel) return ffi.string(C.sel_getName(sel)) end })



local function _createBlockWrapper(fn, encoding)
  -- 1. Parse the type encoding into a C function signature (eg `int (*) (void* arg1, id arg2, double arg3)` )
  encoding = encoding or {"v", {}}
  local signature = encodings[encoding[1]] .. " (*) (void* _block"

  for i, v in ipairs(encoding[2]) do
    signature = signature .. ", " .. encodings[v] .. " arg" .. tostring(i)
  end

  signature = signature .. ")"

  -- 2. create a wrapper function for the block that suppresses the first argument (the block itself)
  local block_invoke_fn = function(_block, ...)
    return fn(...)
  end

  -- 3. return that wrapper function cast to the block's function signature
  return ffi.cast(signature, block_invoke_fn)
end


local BlockType = ffi.typeof("struct block_literal")

function objc.Block(fn, encoding)
  if type(fn) ~= "function" then
    error("Can't create a block from a non-function value")
  end

  local blockDescriptor = ffi.new("struct block_descriptor")
  blockDescriptor.reserved = 0;
  blockDescriptor.size = ffi.sizeof("struct block_literal")

  local block = BlockType()
  block.isa = C._NSConcreteGlobalBlock
  block.flags = bit.lshift(1, 29)
  block.reserved = 0
  block.invoke = ffi.cast("void *", _createBlockWrapper(fn, encoding))
  block.descriptor = blockDescriptor

  return ffi.cast("id", block)
end

return objc
