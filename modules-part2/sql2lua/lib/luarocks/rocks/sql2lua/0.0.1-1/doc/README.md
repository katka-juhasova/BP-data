## `sql2lua`

A lua library for transforming SQL queries into lua functions.

## Installation

### via [luarocks](http://luarocks.org/)

    luarocks install sql2lua

## Usage

```lua
local sql2lua = require "sql2lua"

local sql = [[
-- name: select_foo
select *
  from foo

-- name: select_bar
select *
  from bar
 where name = :name
]]

local queries = sql2lua(sql)

print(queries.select_foo())
-- Output: select * from foo

print(queries.select_bar({ name = "bar" }))
-- Output: select * from bar where name = 'bar'
```
