# RockSolver

_Dependency resolver library for LuaDist packages._

- Author: Martin Šrank, [hello@smasty.net](mailto:hello@smasty.net)
- License: MIT
- **Part of the [LuaDist project](http://luadist.org)**

## Basic usage

```lua

-- 1. Require library
local DependencySolver = require "rocksolver.DependencySolver"


-- 2. Prepare the manifest, platform info and a list of installed packages
local manifest = load_manifest_file()
local platforms = {"unix", "linux"}
local installed = {}

-- 3. Initialize dependency resolver
local solver = DependencySolver(manifest, platforms)

-- 5. Resolve package dependencies
local packages_to_install, err = solver:resolve_dependencies("busted", installed)

```


## Manifest

This library requires a manifest table for it's usage. For proper manifest format,
see the current [LuaDist manifest file](https://gist.github.com/LunaCI/efe9312e64d0e492282e) gist.


## Package

Part of this library is a Package class, which is a representation of a LuaDist package.
Among other things, it supports comparison and equality operations.
