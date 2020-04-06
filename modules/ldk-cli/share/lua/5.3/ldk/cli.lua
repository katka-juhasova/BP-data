--- @module ldk.cli
-- A DSL for command-line applications.
local M = {}

local cmd = require 'ldk.cli.cmd'
local flag = require 'ldk.cli.flag'
local schema = require 'ldk.cli.schema'
local util = require 'ldk.cli.util'

local io_stdout = io.stdout
local io_stderr = io.stderr

local _ENV = M

--- Contains the customization options for a CLI application.
-- @table AppOpts
-- @tfield[opt] function action function invoked when the program is executed (see @{Action}).
-- @tfield[opt] string description description of the application.
-- @tfield[opt] function exit the function used to handle termination (see @{Exit}).
-- @tfield[opt] string footer the text appended at the end of the application's help.
-- @tfield[opt] boolean disable_suggestions disables the suggestions based on Levenshtein distance.
-- @tfield[opt] integer suggestion_mininum_distance defines minimum levenshtein distance to display suggestions.
-- @tfield[opt] boolean hide_help whether to hide or not the built-in help commands.
-- @tfield[opt] boolean hide_version whether to hide or not the built-in version option.
-- @tfield[opt] boolean show_groups whether to group or not the commands and xs into groups.
-- @tfield[opt] string summary the text displayed at the beginning of the application's help.
-- @tfield[opt] string usage the short description of the application.
-- @tfield[opt] string version version of the application.
-- @tfield[opt] function validate function invoked before executing the command (see @{Validate}).
-- @tfield[opt] function writer function used to write the output of the application (see @{Write}).
local AppOpts = {
  -- 'action', -- same a command
  -- 'description', -- same a command
  -- 'examples', -- same a command
  -- 'summary', -- same a command
  -- 'usage', -- same a command
  -- 'validate', -- same a command
  'disable_suggestions',
  'exit',
  'footer',
  'hide_help',
  'hide_version',
  'show_groups',
  'suggestion_mininum_distance',
  'version',
  'writer',
  'error_writer'
}

local AppSchema = {
  -- action = 'nil|function', -- same a command
  -- description = 'nil|string', -- same a command
  -- examples = 'nil|string+', -- same a command
  -- summary = 'nil|string', -- same a command
  -- usage = 'nil|string', -- same a command
  -- validate = 'nil|function', -- same a command
  disable_suggestions = 'nil|boolean',
  exit = 'nil|function',
  footer = 'nil|string',
  hide_help = 'nil|boolean',
  hide_version = 'nil|boolean',
  name = function(s)
    return schema.validate(s, 'string') or (#s == 0 and "string too short")
  end,
  show_groups = 'nil|boolean',
  suggestion_mininum_distance = 'nil|integer',
  version = 'nil|string',
  writer = 'nil|function',
  error_writer = 'nil|function'
}

--- Initialize a new command line application.
-- @tparam string name the name of the application; must be non empty
-- @tparam[opt] table opts a table with the customization options (see @{AppOpts}); the array part of the table can
-- contain flags defining the program commands, options, and arguments.
-- @treturn table a table describing the CLI application.
-- @raise if any field of the returned table is not of the right type.
-- @usage
-- cli.app('hello', {
--   action = function()
--     print("Hello")
--   end
-- })
function app(name, opts)
  local a = flag.command(name, opts)
  util.merge(opts, a, AppOpts)
  schema.validate(a, AppSchema)
  a.writer = a.writer or function(...)
    io_stdout:write(...)
  end
  a.error_writer = a.error_writer or function(...)
    io_stderr:write(...)
  end
  return a
end

--- Contains customizations for a given command.
-- @table CommandOpts
-- @tfield[opt] function action function executed when the command is invoked (see @{Action}); if not specified
-- the field `command` in the application context will be set to the name of the command.
-- @tfield[opt] {string} aliases alternative names of the command.
-- @tfield[opt] string description the description of the command.
-- @tfield[opt] boolean hidden hides the command from any help text.
-- @tfield[opt] string summary text displayed at the beginning of the help text of the command.
-- @tfield[opt] function validate function invoked before executing the command (see @{Validate}).

--- Creates an command flag.
-- @function command
-- @tparam string name the name used to invoke the command.
-- @tparam table opts the command customization (see @{CommandOpts}).
-- @treturn table the new command flag.
-- @usage
-- local build_cmd = flag.command('build', {
--   action = function(ctx)
--     ...
--   end
-- })
-- @raise if any field of the returned table is not of the right type.
command = flag.command

--- Contains customizations for a given option.
-- @table OptionOpts
-- @tfield[opt] function action function invoked after the option has been parsed (see @{Action}); if not specified
-- a field in the application context named after the option will be set to the value of the option .
-- @tfield[opt] {string} aliases the aliases of the option.
-- @tfield[opt] string argname the name of the argument to the option shown in the usage text.
-- @tfield[opt] string conflicts a space-separated list of options that conflict with the option.
-- @field[opt] default the default value of the option.
-- @tfield[opt] string description the description of the option shown in the usage text.
-- @tfield[opt=false] boolean global defines whether this option is global or not; a global option will be available
-- to all child commands.
-- @tfield[opt] string group the name of the optoin group the option belongs to.
-- @tfield[opt=false] boolean hidden hides the option in any usage text.
-- @tfield[opt=0] integer mincount the minimum number of times the option must appear in the command line.
-- @tfield[opt] integer maxcount the maximum number of times the option can appear in the command line.
-- @tfield[opt] boolean once the option must appear at most once in the command line.
-- @tfield[opt=false] boolean required the option must appear at least once in the command line.
-- @tfield[opt='string'] string type the type of the option.
-- @tfield[opt] boolean unbound whether the option is unbound or not.
-- @tfield[opt] function validate function invoked after the option has been parsed, but before `action` is invoked
-- (see @{Validate}).

--- Creates an option flag.
-- @function option
-- @tparam string long the name used to set the option value in the context
-- @tparam[opt] string short the shor name for the option.
-- @tparam[opt] table opts the option customization (see @{OptionOpts}).
-- @treturn table the new option flag.
-- @usage
-- local verbose = flag.option('verbose', 'v', {
--   action = function(ctx)
--     ctx.verbose = true
--   end
-- })
-- @raise if any field of the returned table is not of the right type.
option = flag.option

local function mkfunc(t)
  return function(long, short, opts)
    if type(short) == 'table' then
      opts, short = short, nil
    end
    opts = opts or {}
    opts.type = t
    return option(long, short, opts)
  end
end

--- Creates an option flag accepting integer values (see @{option}).
-- @function int_option
-- @tparam string long the name used to set the option value in the context
-- @tparam[opt] string short the shor name for the option.
-- @tparam[opt] table opts the option customization (see @{OptionOpts}).
-- @treturn table the new option flag.
int_option = mkfunc 'integer'

--- Creates an option flag accepting string values (see @{option}).
-- @function str_option
-- @tparam string long the name used to set the option value in the context
-- @tparam[opt] string short the shor name for the option.
-- @tparam[opt] table opts the option customization (see @{OptionOpts}).
-- @treturn table the new option flag.
str_option = mkfunc 'string'

--- Creates an option flag accepting number values (see @{option}).
-- @function num_option
-- @tparam string long the name used to set the option value in the context
-- @tparam[opt] string short the shor name for the option.
-- @tparam[opt] table opts the option customization (see @{OptionOpts}).
-- @treturn table the new option flag.
num_option = mkfunc 'number'

--- Creates an option flag accepting char values (see @{option}).
-- @function chr_option
-- @tparam string long the name used to set the option value in the context
-- @tparam[opt] string short the shor name for the option.
-- @tparam[opt] table opts the option customization (see @{OptionOpts}).
-- @treturn table the new option flag.
chr_option = mkfunc 'char'

--- Creates an option flag accepting boolean values (see @{option}).
-- @function bool_option
-- @tparam string long the name used to set the option value in the context
-- @tparam[opt] string short the shor name for the option.
-- @tparam[opt] table opts the option customization (see @{OptionOpts}).
-- @treturn table the new option flag.
bool_option = mkfunc 'bool'

--- Contains customizations for a given argument.
-- @table ArgumentOpts
-- @tfield[opt] function action function invoked after the argument has been parsed (see @{Action}); if not specified
-- a field in the application context named after the argument will be set to the value of the argument .
-- @tfield[opt] string default the default value of the argument.
-- @tfield[opt='boolean'] string type the type of the argument.
-- @tfield[opt] integer maxcount the maximum number of times the argument can appear in the command line.
-- @tfield[opt] integer mincount the minimum number of times the argument must appear in the command line.
-- @tfield[opt] boolean once the argument must appear at most once in the command line.
-- @tfield[opt] boolean required the argument must appear at least once in the command line.
-- @tfield[opt='boolean'] string required the argument must appear at least once in the command line.
-- @tfield[opt='string'] string type the type of the argument.
-- @tfield[opt] boolean unbound whether the argument is unbound or not.
-- @tfield[opt] function validate function invoked after the argument has been parsed, but before `action`
-- (see @{Validate}).

--- Creates an argument flag.
-- @function argument
-- @tparam string name the name used to set the argument value in the context.
-- @tparam table opts the argument customization (see @{ArgumentOpts}).
-- @treturn table the new argument flag.
-- @usage
-- local files = flag.argument('files', {
--   unbound = true,
--   action = function(ctx, files)
--     ctx.files = files
--   end
-- })
-- @raise if any field of the returned table is not of the right type.
argument = flag.argument

--- Runs an application with the specified arguments.
-- @function run
-- @tparam table app a CLI application table returned by @{app}.
-- @tparam {string} args an array containing the command-line arguments to the application.
run = cmd.run

return M

--- The command-line application context.
--
-- The table is passed to each `validate` and `action` function.
-- @table AppContext
-- @tfield table _ contains the unparsed command-line arguments.

--- Function Types
-- @section ftypes

--- Represents a function used to convert a string into an option value.
-- @function Read
-- @tparam string s the string to be converted.
-- @return the converted value if the conversion succeeds; otherwise `nil`.
-- @treturn string an error message if the conversion fails; otherwise `nil`.

--- Represents the function used to validate the context before executing an `action`.
-- @function Validate
-- @tparam table ctx the program context (see @{AppContext}).
-- @treturn[opt] string `nil` if the context is valid; otherwise an error message.

--- Represents the function containing the logic of a command or option.
-- @function Action
-- @tparam table ctx the program context (see @{AppContext}).
-- @treturn[opt] string an error message if the action fails.

--- Writes a series of values.
-- @function Write
-- @param ... the values to be written.
-- @treturn[opt] string an error message if an error occurs while writing the values.

--- Handles the termination of the application.
-- @function Exit
-- @tparam integer exit_code the application exit code.
