# lrunkit
Small library for executing commands faster

## Usage (v3)
To import the v3 part of the library, use `import command, capture, interact from require "lrunkit.v3"`
### `command = (cmd:string) -> (args:...) -> signal:number`
When you first apply it with a string, it will create a command holder, to which you can pass
arguments, when you pass arguments (or not), it runs it and returns a signal.
### `capture = (cmd:string) -> (args:...) -> result:string`
Exactly the same as `command`, but instead returns stdout in the end.
### `interact = (cmd:string) -> (args:...) -> handle:IO`
Returns a handle as if it were io.popen.
- `\open (mode:string)`
- `\read (format:string)`
- `\write (any:string)`
- `\close ()`

## Usage (v2 - default)
### `execute = (command, options={}) -> runnable:{}`
Creates a runnable command using os.execute. Run it using `runnable!` (Lua: `runnable()`)
#### Options

- `error_on_fail`: Will exit at error
- `error_on_signal`: Will exit if terminated
- `silent`_: Runs the command silently

### `immediate = (command, options={})`
Same as execute, but runs instantly.
### `interact = (command) -> streamable:{}`
Creates a streamable command using io.popen.

- Open with `streamable\open "r/w"`
- Read with `streamable\read fmt`
- Write with `streamable\write str`
- Close with `streamable\close!`

### `chain = {} -> runchain:->`
Returns a chain of runnable commands. Use it as `ch = chain runnable1, runnable2, runnable3` and run it with `ch!`

