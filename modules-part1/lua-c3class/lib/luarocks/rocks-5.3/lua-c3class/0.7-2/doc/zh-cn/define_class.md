定义一个类
====

在库设计时，类定义API的设计遵循通常的Lua编程习惯，可以按顺序书写定义类的所有成员。
首先，定义一个空类：
``` lua
local Class = require "c3class"

local MyClass = Class()
```
这就定义了一个空类，这样定义的类是匿名类，我们也可以定义一个命名类：
``` lua
local MyClass = Class("MyClassName")
```
这样就定义了一个类名为'MyClassName'的类，带名字的类在程序中只可以定义一个，如果在别处代码中定义同名类时会产生错误。

通常一个类包含以下成员：
- 类成员函数
- 类成员变量
- 构造函数
- 类静态函数
- 类静态变量

定义了类后，接下来就可以：

添加类成员变量
----
``` lua
MyClass.aIntProperty = 0
MyClass.aStringProperty = "abc"
MyClass.aTableProperty = {1, 2, 3}
```
这样就给类添加了3个成员变量，同时指定了它们的默认值。
要注意，不能给一个成员变量设置nil为默认值，因为给一个属性设置nil值在Lua中一般表示删除此属性。

添加类成员函数
----
接下来，给类添加两个类成员函数：
``` lua
MyClass.foo = function(self)
    print("foo")
end
```
或
``` lua
function MyClass.bar(self)
    print("bar")
end
```
不过定义成员函数更推荐这样的写法：
``` lua
function MyClass:foo()
    print("foo")
end

function MyClass:bar()
    print("bar")
end
```

创建实例
----
类实例的创建设计为直接函数调用类的方式，这样最简洁:
``` lua
local myClass1 = MyClass()
local myClass2 = MyClass()
```
这样就创建了两个'MyClass'的实例，这样调用类成员变量：
``` lua
myClass1.aIntProperty = 1
myClass2.aIntProperty = 2
print(myClass1.aIntProperty, myClass2.aIntProperty) --  output: 1    2
myClass2.aStringProperty = "def"
print(myClass1.aStringProperty .. myClass2.aStringProperty) --  output: "abcdef";
```
可以这样调用类成员函数：
``` lua
myClass1.foo(myClass1)
```
不过推荐这样调用：
``` lua
myClass2:bar()
```

构造函数
----
在类实例化的时候，如果成员变量是简单值类型的话，没什么问题；但如果不是简单值类型，比如示例中是一个table，问题就会变复杂：

``` lua
if myClass1.aTableProperty == myClass2.aTableProperty then
    print("reference same table")
else
    print("reference different table")
end
```

按默认行为，上面的代码会输出'reference same table'；这样一个实例中改了'aTableProperty'中的值后，另外一个类实例访问这个值也会发生变化。如果需要每个类实例的'aTableProperty'成员是独立的，可以给类添加一个构造函数来处理类似这样的需求：
``` lua
-- 库约定名为ctor的类成员函数为构造函数
function MyClass:ctor()
    local array = {}
    --  示例中的table是一个array
    for i, v in ipairs(self.aTableProperty) do
        array[i] = v
    end
    self.aTableProperty = array
end
```
这样定义构造函数后，比较两个实例的'aTableProperty'将会输出：'reference different table'

类静态成员
----
类成员变量和成员函数使用统一的定义方法：
``` lua
Class.Static(MyClass, "AStaticIntProperty", 3)
Class.Static(MyClass, "AStaticStringProperty", "STATIC")
Class.Static(MyClass, "StaticFunction", function(...)
    --  do some thing
end)
```
类静态成员只能通过类来调用：
```lua
MyClass.AStaticIntProperty = MyClass.AStaticIntProperty + 1
MyClass.StaticFunction("arg1", "arg2")
```

初始化表
----
类定义时，支持直接传入类成员初始化表的写法：
```lua
local MyClass = Class("MyClassName", {
    aIntProperty = 0,
    aStringProperty = "abc",
    aTableProperty = {1, 2, 3},
    foo = function(self)
        print("foo")
    end,
    bar = function(self)
        print("bar")
    end
})
```

类定义推荐写法
----

为了方便代码阅读，定义类时推荐这样书写：
```lua
--  MyClass.lua
local Class = require "c3class"

--  定义命名类，使用初始化表定义类成员属性
local MyClass = Class("MyClassName", {
    aIntProperty = 0,
    aStringProperty = "abc",
    aTableProperty = {1, 2, 3}
})

--  添加成员函数，ctor靠前
function MyClass:ctor()
    local array = {}
    for i,v in ipairs(self.aTableProperty) do
        array[i] = v
    end
    self.aTableProperty = array
end

function MyClass:foo()
    print("foo")
end

function MyClass:bar()
    print("bar")
end

--  添加类静态成员
Class.Static(MyClass, "AStaticIntProperty", 3)
Class.Static(MyClass, "AStaticStringProperty", "STATIC")
Class.Static(MyClass, "StaticFunction", function(...)
    --  do some thing
end)

--  export module
return MyClass
```