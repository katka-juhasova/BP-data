# CodeGen

---

# Manual

## For the impatient

```lua
local CodeGen = require 'CodeGen'

tmpl = CodeGen {    -- instanciation
    tarball = "${name}-${version}.tar.gz",
    name = 'lua',
}
tmpl.version = 5.1
output = tmpl 'tarball'     -- interpolation
print(output) --> lua-5.1.tar.gz
```

## The instanciation

The instanciation of a template is done by the call of `CodeGen`
with optional parameters. This first parameter is a table.
This table uses only string as key and could contains 3 kinds of value :

- chunk of template which is a string
and could contains primitives i.e. `${...}`
- data which gives access to the data model
- formatter which is a function which accepts a string
as parameter and returns it after a transformation.
The typical usage is for escape sequence.

The other parameters allow inheritance (ie. access to field)
from other templates or simple tables.

A common pattern is to put this step in an external file.

```lua
-- file: tarball.tmpl
return CodeGen {
    tarball = "${name}-${version}.tar.gz",
}
```

```lua
tmpl = dofile 'tarball.tmpl'
```

## Setting data and other alteration

After the instanciation and before the interpolation,
all member of the template are accessible and modifiable like in a table.

Typically, data from the model are added after the instanciation.

## The interpolation

The interpolation is done by calling the template with one string parameter
which is the keyname of the entry point template.

The interpolation returns a string as result
and an optional string which contains some error messages.

## The 4 primitives in template

The `data` could be in the form of `foo.bar.baz`.

### 1. Attribute reference

The syntax is `${data[; separator='sep'][; format=name]}`.

An undefined `data` produces an empty string.

The option `format` allows to specify a formatter function,
which is a value of the template referred by the key `name`.
The default behavior is given by the standard Lua function `tostring`.

When `data` is a table, the option `separator` is used
as parameter of `table.concat(data, sep)`.
This parameter could be simple quoted or double quoted,
and it handles escape sequence like Lua.
The characters `{` and `}` are forbidden,
there must be represented by a decimal escape sequence `\ddd`.

```lua
local CodeGen = require 'CodeGen'

tmpl = CodeGen {
    call = "${name}(${parameters; separator=', '});",
}
tmpl.name = 'print'
tmpl.parameters = { 1, 2, 3 }
output = tmpl 'call'
print(output) --> print(1, 2, 3);
```

### 2. Template include

The syntax is `${name()}` where `name` is the keyname of a chunk template.

If `name` is not the keyname of a valid chunk,
there are no substitution and an error is reported.

### 3. Conditional include

The _if_ syntax is `${data?name1()}`
and the _if/else_ syntax is `${data?name1()!name2()}`
where `name1` and `name2` are the keyname of a chunk template
and `data` is evaluated as a boolean.

### 4. Template application

The syntax is `${data/name()[; separator='sep']}`
where `data` must be a table.
The template `name` is called for each item of the array `data`,
and the result is concatened with an optional `separator`.

The template has a direct access in the item,
and inherits access from the caller.
If the item is not a table, it is accessible via the key `it`.

# Examples

## 99 Bottles of Beer

Yet another generation of the song
[99 Bottles of Beer](http://99-bottles-of-beer.net/).

```lua
local CodeGen = require 'CodeGen'

local function bootle (n)
    if n == 0 then
        return 'No more bottles of beer'
    elseif n == 1 then
        return '1 bottle of beer'
    else
        return tostring(n) .. ' bottles of beer'
    end
end

local function action (n)
    if n == 0 then
        return 'Go to the store and buy some more'
    else
        return 'Take one down and pass it around'
    end
end

local function populate ()
    local t = {}
    for i = 99, 0, -1 do
        table.insert(t, i)
    end
    return t
end

local tmpl = CodeGen {
    numbers = populate(),       -- { 99, 98, ..., 1, 0 }
    lyrics = [[
${numbers/stanza(); separator='\n'}
]],
    stanza = [[
${it; format=bootle} on the wall, ${it; format=bootle_lower}.
${it; format=action}, ${it; format=bootle_next} on the wall.
]],
    bootle = bootle,
    bootle_lower = function (n)
        return bootle(n):lower()
    end,
    bootle_next = function (n)
        return bootle((n == 0) and 99 or (n - 1)):lower()
    end,
    action = action,
}

print(tmpl 'lyrics')            -- let's sing the song
```

## Java class

Java getter/setter generation with external template:

```lua
-- file: java.tmpl

return require'CodeGen'{
    class = [[
public class ${_name} {
    ${_attrs/decl()}

    ${_attrs/getter_setter(); separator='\n'}
}
]],
    decl = [[
private ${_type} ${_name};
]],
    getter_setter = [[
public void set${_name; format=firstuc}(${_type} ${_name}) {
    this.${_name} = ${_name};
}
public ${_type} get${_name; format=firstuc}() {
    return this.${_name};
}
]],
    firstuc = function (s)
        return s:sub(1, 1):upper() .. s:sub(2)
    end,
}
```

```lua
local tmpl = dofile 'java.tmpl' -- load the template

-- populate with data
tmpl._name = 'Person'
tmpl._attrs = {
    { _name = 'name',       _type = 'String' },
    { _name = 'age',        _type = 'Integer' },
    { _name = 'address',    _type = 'String' },
}

print(tmpl 'class')     -- interpolation
```

The output is :

```java
public class Person {
    private String name;
    private Integer age;
    private String address;

    public void setName(String name) {
        this.name = name;
    }
    public String getName() {
        return this.name;
    }

    public void setAge(Integer age) {
        this.age = age;
    }
    public Integer getAge() {
        return this.age;
    }

    public void setAddress(String address) {
        this.address = address;
    }
    public String getAddress() {
        return this.address;
    }
}
```

## Rockspec

A generic template for rockspec.

```lua
-- file: rockspec.tmpl
return CodeGen {
    rockspec = [[
package = '${name}'
version = '${version}-${revision}'
${_source()}
${_description()}
${_dependencies()}
]],
    _source = [[
source = {
    url = ${_url()},
    md5 = '${md5}',
    dir = '${name}-${version}',
},
]],
    _description = [[
description = {
    ${desc.summary?_summary()}
    ${desc.homepage?_homepage()}
    ${desc.maintainer?_maintainer()}
    ${desc.license?_license()}
},
]],
    _summary = 'summary = "${desc.summary}",',
    _homepage = 'homepage = "${desc.homepage}",',
    _maintainer = 'maintainer = "${desc.maintainer}",',
    _license = 'license = "${desc.license}",',
    _dependencies = [[
dependencies = {
${dependencies/_depend()}
}
]],
    _depend = [[
    '${name} >= ${version}',
]],
}
```

A specialization for all my projects.

```lua
-- file: my_rockspec.tmpl
local parent = dofile 'rockspec.tmpl'

return CodeGen({
    lower = string.lower,
    _tarball = "${name; format=lower}-${version}.tar.gz",
    _url = "'https://framagit.org/fperrad/${name}/raw/releases/${_tarball()}'",
    _homepage = 'homepage = "https://fperrad.frama.io/${name}",',
    desc = {
        homepage = true,
        maintainer = "Francois Perrad",
        license = "MIT/X11",
    },
}, parent)
```

And finally, an use for this project.

```lua
CodeGen = require 'CodeGen'

local rs = dofile 'my_rockspec.tmpl'
rs.name = 'lua-CodeGen'
rs.version = '0.1.0'
rs.revision = 1
rs.md5 = 'XxX'
rs.desc.summary = "a template engine"
rs.dependencies = {
    { name = 'lua', version = 5.1 },
    { name = 'lua-testmore', version = '0.2.1' },
}
print(rs 'rockspec')
```

The output is :

```lua
package = 'lua-CodeGen'
version = '0.1.0-1'
source = {
    url = 'https://framagit.org/fperrad/lua-CodeGen/raw/releases/lua-codegen-0.1.0.tar.gz',
    md5 = 'XxX',
    dir = 'lua-CodeGen-0.1.0',
},
description = {
    summary = "a template engine",
    homepage = "https://fperrad.frama.io/lua-CodeGen",
    maintainer = "Francois Perrad",
    license = "MIT/X11",
},
dependencies = {
    'lua >= 5.1',
    'lua-testmore >= 0.2.1',
}
```
