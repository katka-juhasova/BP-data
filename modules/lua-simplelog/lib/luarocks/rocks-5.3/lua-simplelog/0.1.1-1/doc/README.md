## Overview

lua-simplelog is a logging library that aims to be performant, simple,
and capable. It exposes a log mannager which in turn is used to open
up log files in the log directory. The loggers keep up with dates and
roll to a new file when the date changes. It provides for multiple
levels out of the box. Each log can use either the default write
settings, or their own. Write settings allow for telling the logger
which level's are enabled for which output.

## Future

* Perhaps allow dynamically adding levels and/or writers?
* Perhaps allow for name formats for log files?
* Perhaps allow for each log file to have its own folder?

## Usage
    local log_config = {
      -- this directory must exist!
      -- must end in a '/'
      dir = '/tmp/simplelog/',
      daemonized = true,
      debug_info = true,
      logs = {
        default = {
          levels = {
            write = 'info',
            print = 'info'
          }
        },
        log1 = {
          levels = {
            write = 'info',
            print = 'trace'
          }
        }
      }
    }

    local log_manager = require 'simplelog' (log_config)
    local uses_default = log_manager:open 'loga'
    local log1 = log_manager:open 'log1'
    -- should not print or write to file
    uses_default:trace 'This is a message'
    -- should print and write to file
    uses_default:error('Error %s', 1000)
    -- should print but not write to file
    log1:trace 'This is a message'
    -- should print and write to file
    log1:error 'This is a message too'
    log_manager:close_all()

---

## Documentation

### Levels
These are the available log levels in order of importance with highest
importance being listed last.

* trace
* debug
* info
* warn
* error
* fatal

### Log manager
This is what's returned when you import the module.

Once you initialize a manager with a config like
`local manager = require 'simplelog' (cfg_table)`
the following functions become avaliable:

Functions:
* open(string name) - opens a log file with the name given and creates
  said file under the directory given in the configuration. Returns
  the log file object.
* close(string name) - closes a previously opened log file by name
* closeall() - closes all log files managed by this manager

**Configuration is explained below:**

Excerpt from example:

      dir = '/tmp/simplelog/',
      daemonized = true,
      debug_info = true,
      logs = {
        default = {
          levels = {
            write = 'info',
            print = 'info'
          }
        },
        log1 = {
          levels = {
            write = 'info',
            print = 'trace'
          }
        }
      }
    }

The table key `dir` is required and is the directory in which log
files will be created. The `logs.default` is also required. The rest
is optional.

Manager configuration:

* dir : The directory to which log files will be written.
* daemonized : Used to determine if it is neccessary to disable
  stdout/stderr logging.
* debug_info: If enabled, the logger will include source line info in
  the output.

Log Configuration:

Each log can be configured to only write log lines above a certain
level. If a log, specified by name in the config, exists, then that
configuration is used for determining when to write information,
otherwise the default. Currently logs only support writing to files
(`write`), or writing to the screen (`print`). Each log config is
found under the configuration table at `config.logs` and
`config.logs.default` must exist. Each log's configuration follows the
same format as `config.logs.default`. Each log config has a `levels`
table and must have 2 keys present (one for each currently supported
write situation). These keys simply must be set to one of the log
levels defined above and only levels equal or greater in importance in
relation to that log will be logged. Look to the excerpt for a
demonstration. The levels per output can be different.

### Log Object

Each log object has a method for each level defined earlier. Accessing
anything other than those methods is unsupported and may cause issues.
If a level isn't supposed to write out, then the level is aliased
basically to nop.