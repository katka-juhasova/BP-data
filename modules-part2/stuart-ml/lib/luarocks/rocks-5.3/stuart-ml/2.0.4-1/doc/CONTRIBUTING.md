<img align="right" src="stuart.png" width="70">

# Contributing to Stuart ML

## Guidelines

* [Busted](https://olivinelabs.com/busted/)-based [TDD](https://en.wikipedia.org/wiki/Test-driven_development)
* Class modules begin with an uppercase letter, and end up in their own file that begins with an uppercase letter (e.g. `RDD.lua`)
* Two spaces for indents.
* The `_` global variable is the unused variable stand-in.
* Alphabetized functions within a module.

## Strict Rules for Encapsulation

In Apache Spark source codes, some RDD-based ML model source codes such as `KMeans.scala` have introduced dependencies on DataFrame based modules; i.e. code sharing within a monolithic application where individual jar files are not actually usable without all the others. This is unacceptable in an edge environment where end users will depend heavily on the Lua Amalgamator's or Transpiler's ability to strip out unused modules.

For example, if an end user's Spark job uses RDD-based ML models, and never references DataFrames, then the underlying RDD-based models MUST not reference them or Stuart SQL. In such cases, there is a need to forensically comb through the commits that introduced the unwanted dependency, and unwind it by reconstructing and then duplicating the required code.
