类的继承
====
在面向对象编程时，从父类派生出子类是很自然的事情。
派生出的子类不需要任何编码就拥有了父类的所有属性和成员函数。
不同的子类通过覆盖父类的同名函数就可以实现类的多态性。
本库的实现是一种类的多继承方案，示例如下：

继承父类
----
类 O 为父类，定义了两个成员；类 A 为 O 的子类：
``` lua

local O = Class("O")

O.inheritProperty = "Property Of O"

function O:testInherit()
    return "Method of O"
end

local A = Class("A", O)
```
A 的实例拥有类 O 的所有成员，调用测试代码：
``` lua
local o1 = O()
local a1 = A()

print(o1.inheritProperty)
print(o1:testInherit())
print(a1.inheritProperty)
print(a1:testInherit())
```
输出为：
```
Property Of O
Method of O
Property Of O
Method of O
```

覆盖父类成员
----
类成员包含成员属性和成员函数两类。对于成员属性，子类和父类如果定义了同名属性，那么在类的实例中其实是同一个东西，但子类定义属性的初始值可能和父类定义同名属性的初始值不相同；考虑到初始化顺序、构造函数赋值以及多继承带来的复杂性，使用覆盖父类成员属性的代码在执行中很可能出现不是预料的结果；所以在具体的编码实践中不推荐覆盖父类成员属性。

以下示例演示覆盖父类成员函数，子类 A 定义和父类 O 定义同名的函数：
``` lua
function O:testOverride()
    return "Method of O"
end

function A:testOverride()
    return "Method of A"
end
```
子类中的函数会覆盖父类成员的函数，调用测试代码：
``` lua
local o2 = O()
local a2 = A()
print(o2:testOverride())
print(a2:testOverride())
```
输出为：
```
Method of O
Method of A
```

super 函数
----

当子类的成员函数覆盖了父类的成员函数时，很多情况下子类函数的逻辑和父类的的逻辑并不是完全不一样，只需要在父类的逻辑前或后添加一些特殊处理就可以了，这种情形下可以在子类函数的逻辑中调用 super 函数来直接调用分类的函数逻辑，并不需要重新实现。

super 函数不是类的成员函数，也不是全局函数，而是在通过 Class 定义类时通过第二参数返回的一个局部函数，先定义一个基类：
``` lua
local TestSuperA =
    Class(
    "TestSuperA",
    {
        propertyA = "A"
    }
)

function TestSuperA:append(str)
    return str .. self.propertyA
end

local testSuperA = TestSuperA()
assert(testSuperA:append("STRING_") == "STRING_A")
```
然后派生一个子类：
``` lua
local TestSuperB, super =
    Class(
    "TestSuperB",
    TestSuperA,
    {
        propertyB = "B"
    }
)

```
通过局部变量 super 变量来保存 super 函数，就可以在子类函数中调用：
``` lua
function TestSuperB:append(str)
    return super(self):append(str) .. self.propertyB
end
```
调用测试函数：
``` lua
local testSuperB = TestSuperB()
testSuperB:append("STRING_")
```
输出为：
```
STRING_AB
```
- super 函数的功能可以定义为：**在当前类的父类中，按MBO顺序查找指定成员**
- super 函数接受两个参数：
    - 第一个为当前类实例
    - 第二个参数为MBO序列中最后一个不需要查找的类，默认为当前类，即: `super(self) == super(self, CurrentClass)`

再看看比较复杂的情况，把继承结构扩充成菱形:
``` lua
local TestSuperC, super =
    Class(
    "TestSuperC",
    TestSuperA,
    {
        propertyC = "C"
    }
)

function TestSuperC:append(str)
    return super(self):append(str) .. self.propertyC
end

assert(TestSuperC():append("STRING_") == "STRING_AC")

local TestSuperD, super =
    Class(
    "TestSuperD",
    TestSuperB,
    TestSuperC,
    {
        propertyD = "D"
    }
)

function TestSuperD:append(str)
    return super(self):append(str) .. self.propertyD
end
```
调用测试函数：
``` lua
local testSuperD = TestSuperD()
print(testSuperD:append("STRING_"))
```
输出为：
```
STRING_ABD
```
- 注意：本实现和 python 的实现不同，如果在 python 中， 上面测试代码应输出 `STRING_ACBD`。本实现如此设计的理由是：
    - 当定义 TestSuperB时，只有基类 TestSuperA，调用 super 的本意大部分情况下应该是调用 TestSuperA 中的方法，而不是不知道何时派生出来的兄弟类 TestSuperC
    - 当前的实现比较简单，当在通过 super 调用父类的函数中再次调用 super 时不用切换 super 的上下文

当明确知道需要跳过某个父类去查找方法时，可以通过 super 的第二个参数指定:
``` lua
function TestSuperD:appendAlter(str)
    --  skip base class TestSuperB to search function 'append'
    return super(self, TestSuperB):append(str) .. self.propertyD
end
```
这样 super 函数在查找成员函数时，就会从 class TestSuperD 的 MRO 中基类 TestSuperB 之后开始查找，调用测试代码：
``` lua
print(testSuperD:appendAlter("STRING_"))
```
输出为：
```
STRING_ACD
```
