# underscore-dot-lua

[![Build Status](https://travis-ci.org/AlberTajuelo/underscore-dot-lua.svg)](https://travis-ci.org/AlberTajuelo/underscore-dot-lua)
[![codecov](https://codecov.io/gh/AlberTajuelo/underscore-dot-lua/branch/master/graph/badge.svg)](https://codecov.io/gh/AlberTajuelo/underscore-dot-lua)
[![License](https://img.shields.io/badge/License-MIT-brightgreen.svg)](LICENSE)

## Contents

* [Overview](#overview)
* [Origin](#origin)
* [Requirements](#requirements)
* [Basic usage](#basic-usage)
* [Documentation](#documentation)
* [Development](#development)
* [References](#references)

## Overview

A Lua version of http://documentcloud.github.com/underscore/, see http://mirven.github.com/underscore.lua/ for more information.

This fork contains three additions to the core underscore.lua:
simple_reduce, multi_map and table_iterator.

simple_reduce doesn't require a base case,
it uses the first yield of an iterator passed to it instead.

multi_map can be used on a list of lists of indefinite length,
with a callback given having a number of arguments equal
to the number of iterators in the list of iterators.
This function caters to the iterator with the least amount of yields.

table_iterator is a simple iterator to run through a table,
it yields a key-value pair as a table.

## Origin

This repository is a fork from [this repo](https://github.com/ashe-dolinsky-old/underscore.lua). Repository name has changed from `underscore.lua` to `underscore-dot-lua`.

## Requirements

None.

## Basic Usage

If using LuaRocks:
```
luarocks install underscore-dot-lua
```

Otherwise, download <https://github.com/AlberTajuelo/underscore-dot-lua/zipball/master>.

Alternately, if using GIT:

```
git clone git://github.com/AlberTajuelo/underscore-dot-lua.git

cd underscore-dot-lua 

luarocks make
```


## Documentation


## Development


## References


