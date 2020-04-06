-- Notes:
  -- If you read this from top to bottom it might not make sense. If you are looking at 'Method 1' in a section,
  -- follow all the other sections that have a 'Method 1' before reading a 'Method 2'. The same goes for anywhere you see 'Method 2'.

  -- Whenever you create a class, it will create Setter and Getter functions automatically based off of your variable name choices.
  -- This keeps your variables encapsulated, creating a more secure environment. The only way to access them is with those functions.
  -- The only exception where it wont make setters and getters is if you declare functions within the table, which is absolutely acceptable.

-- Usage:

-- require class.lua somewhere in your script.

require("class")

-- Creating a class:

  -- Method 1:

  local Animal = class: Animal {
    X = 0,
    Y = 0,
    W = 32,
    H = 32,
    Name = "Default",
    Bark = false
  }

  -- Method 2:

  class: Animal {
    X = 0,
    Y = 0,
    W = 32,
    H = 32,
    Name = "Default",
    Bark = false  
  }

-- Creating an object from the class:

  -- Method 1:

  local Sparky = Animal()
  Sparky.SetX(64)
  Sparky.SetY(96)
  Sparky.SetName("Sparky")
  Sparky.SetBark(true)
  
  print(Sparky.GetX())
  print(Sparky.GetY())
  print(Sparky.GetName())
  print(Sparky.GetBark())
  
  -- Method 2:
  
  local Sparky = class("Animal")
  Sparky.SetX(64)
  Sparky.SetY(96)
  Sparky.SetName("Sparky")
  Sparky.SetBark(true)
  
  print(Sparky.GetX())
  print(Sparky.GetY())
  print(Sparky.GetName())
  print(Sparky.GetBark())
  
-- Deriving a class from another class (Inheritance):
  -- Deriving from another class is simple as passing the class name as a second argument, either as a string that will
  -- look up that class, or if you stored the class, pass it the variable you created which contains its Constructor.
  -- Any class derived from another will include all of the derived classes functions,variables,tables,etc. 
  
  -- Method 1:

  class: Base {
    X = 0,
    Y = 0,
    W = 0,
    H = 0
  }

  class: Moving({
    XVel  = 0,
    YVel  = 0,
    Speed = 256,
    Mass  = 512
  },"Base") -- Passing a string to lookup that class.
  
  -- Method 2:

  local Base = class: Base {
    X = 0,
    Y = 0,
    W = 0,
    H = 0
  }

  class: Moving({
    XVel  = 0,
    YVel  = 0,
    Speed = 256,
    Mass  = 512
  },Base)  -- Passing the variable Base that holds Base's Ctor
