
local ffi = require "ffi"

ffi.cdef [[
  // typedefs
  typedef struct objc_class *Class;
  struct objc_class { Class isa; };
  struct objc_object { Class isa; };
  typedef struct objc_object *id;
  typedef struct objc_selector *SEL;
  typedef struct objc_method *Method;

  typedef signed char BOOL;
  typedef long NSInteger;
  typedef unsigned long NSUInteger;

  // function declarations
  id objc_getClass(const char *name);
  id objc_msgSend(id self, SEL op, ...);

  const char * class_getName(Class cls);
  Method class_getClassMethod(Class cls, SEL name);
  Method class_getInstanceMethod(Class cls, SEL name);

  BOOL object_isClass(id obj);
  Class object_getClass(id obj);

  char * method_copyReturnType(Method m);
  unsigned int method_getNumberOfArguments(Method m);
  char * method_copyArgumentType(Method m, unsigned int index);

  SEL sel_registerName(const char *str);
  const char * sel_getName(SEL sel);


  int sprintf(char *buf, const char *fmt, ...);

  // block abi: https://clang.llvm.org/docs/Block-ABI-Apple.html
  struct block_descriptor {
    unsigned long int reserved;
    unsigned long int size;
  };

  struct block_literal {
    struct block_literal *isa;
    int flags;
    int reserved;
    void *invoke;
    struct block_descriptor *descriptor;
  };

  struct block_literal *_NSConcreteGlobalBlock;
]]


--[[
c	- char
i	- int
s	- short
q	- long long
C	- unsigned char
I	- unsigned int
S	- unsigned short
L	- unsigned long
Q	- unsigned long long
f	- float
d	- double
B	- C++ bool or a C99 _Bool
v	- void
*	- char *
r*- const char*
@	- id
#	- Class
:	- SEL
[array type]	An array
{name=type…}	A structure
(name=type…)	A union
bnum	A bit field of num bits
^type	A pointer to type
?
]]
