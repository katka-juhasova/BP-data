local Option = require("option")

local a = Option(15)
assert( a:is_some() )
assert( a:unwrap_or(209) == 15 )
print( a:unwrap() ) --> 15

local b = Option()
assert( b:is_none() )
assert( b:unwrap_or(209) == 209 )
-- print( b:unwrap() ) -- This fails!

-- This also fails with a custom message:
-- print( b:expect("This ain't no value!") )

-- Let's put this to use..
-- The variable "HOME" exists on POSIX systems, but not Windows.
local env = Option( os.getenv("HOME") )
env:match(
  function( home )
    -- The first function runs if the variable exists.
    print( "Your POSIX home folder is: ".. home )
  end,
  function()
    -- This function runs if the Option is none.
    print( "Are you running Windows?" )
  end
)


-- Let's make it better.
-- What if we can run a function to default to
--   if the option is none?
local new_env = Option( os.getenv("HOME") )
local home = new_env:unwrap_or_else(
  function()
    return os.getenv("USERHOME")
  end
)
print( "Your home folder is: ".. home )
-- That's much better!


-- Let's take things up one more notch.
-- We have a program with three config files: one default config
--   and two more for fallbacks. Doing .unwrap_or_else() doesn't
--   look so clean any more. What else can we do?

-- First, lets make a function to see if a file exists.
-- If it does, it returns the path. Else, nil.
local function config_exists(path)
  local fh = io.open(path, "r")
  local exists = fh ~= nil
  if exists then fh:close() end
  return (exists and path or nil)
end

-- Now, let's make it with our `home` variable we got earlier:
local conf_file = Option( config_exists(home .. "/.myconf") )
    :fallback(config_exists(home .."/.myconf_backup"))
    :fallback(config_exists(home .."/.myconf_backup_backup"))
-- This makes it so that if the previous Option is nil, then
-- it will be an Option of the next variable.

-- Let's use it:
conf_file:match(
  function(conf)
    print("Your conf file is: ".. conf)
  end,
  function()
    print("You don't have a conf file anywhere!")
  end
)
