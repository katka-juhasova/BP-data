# Filament

A small library to make handling threads in Love easier. Combines the concepts
of a thread and two channels for input and output into a single object.

## Usage

Call with a function to run it in a thread. The function will be passed a table
of arguments containing at a minimum, `input` and `output` channels, and `fn`
(which is itself as a FileData object).

```
local Filament = require "filament"
local thread = Filament(function(args) args.output:push("A threaded hi!") end)
thread\start!
print(thread\demand!) -- waits for a message to be pushed, and grabs it
```

Alternately, pass an options table to add options to be passed along, and/or
specify modules to be loaded:

- `fn`: The function to run. By itself, its the same thing as calling with just
  that function.
- `modules`: A comma-separated list of modules to require before running the
  specified function.
- `input`: A channel to be used to input data to the thread.
- `output`: A channel the thread will use to output data.

And finally, to have a thread run immediately, you can call `Filament.run()`
instead of creating a filament object and calling `start` on it.
