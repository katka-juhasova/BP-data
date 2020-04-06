# Domotest

## What is it?

Domotest is a small library to assist with testing
[file-system-based Lua scripts](https://www.domoticz.com/wiki/Domoticz_and_Scripting#File_System_Based) used by [Domoticz](https://www.domoticz.com).

## Why is it a thing?

I wanted to ensure that my home automation scripts were working correctly, and any changes would not break anything. That meant I wanted to have tests that could confirm the correct behaviour of the event scripts.

It turns out that getting data into a Domoticz-compatible Lua script (such as the `devicechanged`, `otherdevices` tables) requires a reasonable amount of boilerplate that would clutter the tests and make them harder to understand.

Enter Domotest.

## Installation

## Luarocks (Recommended)

Install the [domotest rock](http://luarocks.org/modules/nxsoftware/domotest):

```
luarocks install domotest
```

Require the domotest library in your test `.lua` file(s):

```
require 'domotest'
```

### Manual

Clone the git repository:

```
git clone https://github.com/NxSoftware/domotest.git
```

Require the domotest source as a relative path from your test `.lua` file(s):

```
require 'src/domotest'
```

## Usage

Use Domotest to load the appropriate Domoticz event script, passing in whatever data you need to test:

```
commandArray = domotest('script_device_bathroommotion.lua', {
  devicechanged = { ['Bathroom Motion'] = 'On' },
  timeofday = { ['Nighttime'] = true }
})
```

The return value is the `commandArray` table as returned from your Domoticz event script.

Have a look at the [examples](./examples) for a more detailed look and how it can be used with the [Busted](http://olivinelabs.com/busted/) test framework.

Please note that the examples are not necessarily good/recommended ways of writing event scripts and are simply intended to show how Domotest is used.
