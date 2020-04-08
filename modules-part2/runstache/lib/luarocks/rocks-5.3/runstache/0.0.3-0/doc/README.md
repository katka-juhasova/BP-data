# runstache.lua

A standalone template instantiation script for [mustache](http://mustache.github.io/) templates in Lua.

## Usage

```
./runstache.lua [<config filename>] [<template filename>] [<output filename>]
```

All arguments are optional, providing sensible defaults.

Values set in `<config>` can be overridden on the command line by specifying `-e positional_value` or `-e key=value`.

### Config filename

The file `config filename` is executed as a Lua script and is expected to return a table that is used as the context of the template.

It may return a second value, which shall be a preprocessing function. This function is called with `config` as its argument and is expected to return a (modified) `config`. See below for examples.

Defaults to: Name of the script (`arg[0]`) with `.lua` replaced with `.cfg`.

### Template filename

The template file to instantiate.

Defaults to: stdin

### Output filename

Defaults to: stdout

## Example

### Config file (`example.cfg`)

```lua
return {
  example = {
    value = 1,
  },
},
function(config)
  config.additional = assert(config[1])
  return config
end
```

### Template (`example.yaml`)

```yaml
example:
  value: {{example.value}}
  additional: {{additional}}
  template: |
    {{>example.template}}
```

### Nested template (`example.template`)

```
Template
With
{{additional}}
Value
```

### Command line and output

The first line is the command that was run and not part of the output.

```yaml
# ./runstache.lua example.cfg example.yaml -e "much more"
example:
  value: 1
  additional: much more
  template: |
    Template
    With
    much more
    Value
```

## Advanced example

### Config

```lua
local merge = require "std.table".merge

return {
  hosts = {
    orange = {
      ip = "10.0.0.1",
    },
    blue = {  
      ip = "10.0.0.2",
    },
  },
},
function(config)
  for hostname, host in pairs(config.hosts) do
    host.hostname = hostname
  end
  return merge(config, config.hosts[config.hostname])
end
```

### Template

```yaml
some-service:
  hostfile: {{hostname}}.cfg
  ip: {{ip}}
```

### Command line and output

The first line is the command that was run and not part of the output.

```yaml
# ./runstache.lua example.cfg example.yaml -e hostname=orange
some-service:
  hostfile: orange.cfg
  ip: 10.0.0.1
```
