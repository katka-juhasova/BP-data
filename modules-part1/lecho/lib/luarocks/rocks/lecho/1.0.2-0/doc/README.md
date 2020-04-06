# lecho

A small Lua module for enabling/disabling terminal echo

## Usage:

* `local lecho = require'lecho'`

Initializes a new `lecho` object and grabs the
current state of standard input's terminal settings.

Object has the following methods:

* `ok = lecho:off()` - turns off terminal echo, returns true if successful
* `ok = lecho:on()` - turns on terminal echo, returns true if successful
* `echo_on = lecho:status()` - returns true if echo is enabled

## Example:

```lua
local lecho = require'lecho'

if lecho:status() then
  print("Terminal echo is on")
else
  print("Terminal echo is off - turning on")
  if not lecho:on() then
    print("Warning - unable to enable terminal echo")
  end
end

print("Type some data - this should be visible")
local clear_data = io.read()

print("Turning off terminal echo")

if not lecho:off() then
  print("Warning - unable to disable terminal echo")
end

print("Type some data - this should be invisible")
local invis_data = io.read()

if not lecho:on() then
  print("Warning - unable to enable terminal echo")
end

print("Data read: " .. invis_data)

```



## LICENSE

MIT - see file `LICENSE`
