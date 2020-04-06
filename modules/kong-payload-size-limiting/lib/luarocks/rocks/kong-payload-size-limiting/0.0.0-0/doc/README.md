# kong-payload-size-limiting | <sub><sup>A better request size limiting plugin for Kong</sup></sub>
[![version](http://img.shields.io/badge/version-v0.0.0-blue.svg)](#)  [![versioning](http://img.shields.io/badge/versioning-semver-blue.svg)](http://semver.org/) [![branching](http://img.shields.io/badge/branching-github%20flow-blue.svg)](https://guides.github.com/introduction/flow/)
[![license](http://img.shields.io/badge/license-apache-blue.svg)](LICENSE.md)

## Features

* Ability to limit differently by `Content-Type` pattern

## Installation

Clone the repo and then:

```bash
$ make install
```

Edit `kong.conf`:

```
custom_plugins: payload-size-limiting
```

Restart Kong.
