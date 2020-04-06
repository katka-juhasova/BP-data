# Cookbook

Basic recipes to create 2D games in malvado game engine.

- [Game organization](#game-organization)
  - [Basic entity creation](#basic-entity-creation)
  - [Level transitions](#level-transitions)
- [Animations](#animations)
  - [Basic Animation](#basic-animation)
  - [Image animation](#image-animation)
- [Sounds and Music](#sounds-and-music)


## Game organization
### Basic entity creation

**Problem:**

I want to create many game entities: a game character, live background, etc.

**Solution:**

In malvado, a game entity is a *process*. When a process is alive, it is rendered every frame. But it also can contains only logic.

```lua
require 'malvado'

local exit_game = false

Enemy = process(function()
  -- To implement
  while not exit_game do
    -- The frame function is very important. I need to put it inside every entity loop
    frame()
  end
end)

Hero = process(function()
  -- To implement
  while not exit_game do
    -- The frame function is very important. I need to put it inside every entity loop
    frame()
  end
end)

-- A game is also a process
Level = process(function()
  -- Entities instantiation. Be careful and don't instantiate entities inside loops
  Enemy()
  Hero()

  while not exit_game do
    -- The frame function is very important. I need to put it inside every entity loop
    frame()
  end
end)

-- The game starts here
malvado.start(function()
  Level()
end)

```
### Level transitions

**Problem:**

A want many game levels.

**Solution:**

Every level is a process. In one special process (level manager) the levels are created.

```lua
require 'malvado'

local playing = false
local level = 1
local exit_game = false

Level1 = process(function()
-- To implement
-- In the end: playing = false
end)

Level2 = process(function()
-- To implement
end)

LevelManager = process(function()

  while not exit_game do
    if not playing then
      playing = true
      fade_off()

      if level = 1 then
        Level1()
      elseif level = 2 then
        Level2()
      end

      fade_on()
    end

    frame()
  end
end)

-- The game starts here
malvado.start(function()
  LevelManager()
end)
```

## Animations

### Basic Animation

**Problem:**

I want to move a game entity from 0 to the middle of the screen.

**Solution:**

I need to increment the *self.x* coord in every frame.

```lua
local game_end = false

Hero = process(function(self)
  -- I can adjust the velocity setting the frames per second of the process.
  self.fps = 15
  self.x = 0
  self.y = get_screen_height() / 2

  while not game_end do
    if self.x < (get_screen_width() / 2) then
      self.x = self.x + 1
    end

    frame()
  end
end)
```

### Image animation

**Problem:**

I want to use many images to create an animation.

**Solution:**

There are different ways, but the most simple is to use the *fpg* in directory mode. First of all i can create a directory with the images that compounds the animation. And then create a process:

```lua

-- If i have the animation in the 'assets/cat' directory

Hero = process(function(self)
  -- Directory is the default mode
  self.fpg = fpg('assets/cat')
  -- This is the counter. First initialize with the first animation
  self.fpgIndex = 0
  -- Here I can adjunt the velocity of the animation
  self.fpg = 15

  while not game_end do
    self.fpgIndex = self.fpgIndex + 1
    frame()
  end
end)

```

```


## Sounds and Music

TODO
