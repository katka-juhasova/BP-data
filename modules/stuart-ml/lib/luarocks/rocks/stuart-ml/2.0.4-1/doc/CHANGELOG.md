## [2.0.4] - 2019-04-20
### Added
- `linalg:` Ported `BLAS` `spr()`
- `linalg:` Ported `Matrix` `copy()` and `toString()`, and implemented `clone()` to make matrices usable within RDD functions as a zero value parameter
- `linalg:` Ported `RowMatrix` `computeCovariance()`, `computeGramianMatrix()` and `triuToFull()`
- `util:` New utility equivalent to `scala.collection.Iterator` `fill()`
- `stat:` Ported `corr()` and `PearsonCorrelation` class

### Changed
- `linalg:` Use native Lua 1-based `colPtrs` indexes in `SparseMatrix`

### Fixed
- [#56](https://github.com/BixData/stuart-ml/issues/56) Java array `binarySearch()` claimed to use 1-based index params and an exclusive end-index, but used 0-based index params and an inclusive end-index

### Changed
- `linalg:` `DenseVector` and `SparseVector` are now clonable, making them usable as a zero value in RDD functions; required by `RowMatrix`

## [2.0.2] - 2019-02-23
### Added
- Document how to train a K-means model within Redis at [examples/redis-kmeans](./examples/redis-kmeans/)
- Document how to run test suites within Redis at [spec-redis](./spec-redis/)
- [#43](https://github.com/BixData/stuart-ml/issues/43) Support loading LIBSVM files from `MLUtils`
- `DenseMatrix` and `SparseMatrix` map() and update() support
- `DenseMatrix` diag() and eye() support

### Fixed
- [#47](https://github.com/BixData/stuart-ml/issues/47) Cannot train a K-means model within Redis due to unnecessary os.date() dependency (Redis interop)

## [2.0.1] - 2019-01-16
### Added
- [#31](https://github.com/BixData/stuart-ml/issues/31) `[linalg:]` Support `DenseMatrix`, `Matrices`, `Matrix`, and `SparseMatrix` modules
- [regression:] Support LabeledPoint class

### Changed
- DenseVector and SparseVector toString() format changed to conform to Apache Spark (instead of Lua conventions), now that LabeledPoint unit test coverage requires compatibility

## [2.0.0] - 2018-12-16
### Changed
- Upgraded to Stuart 2.0.0

## [1.0.1] - 2018-11-17
### Fixed
- [#38](https://github.com/BixData/stuart-ml/issues/38) Vectors.dense(...) with varargs error: no table.pack() function (eLua interop)

## [1.0.0] - 2018-11-08
### Changed
- Upgrade to Stuart 1.0.0 with changes to class framework

## [0.1.9] - 2018-11-02
### Added
- [#28](https://github.com/BixData/stuart-ml/issues/28) Train a K-means model

### Changed
- [#34](https://github.com/BixData/stuart-ml/issues/34) Remove all use of module upvalues, so that modules can be more easily transpiled to C then burned into ROM and chipsets (eLua [LTR](http://www.eluaproject.net/doc/v0.9/en_arch_ltr.html) interop)

### Fixed
- [#23](https://github.com/BixData/stuart-ml/issues/23) K-means cluster centers load in a non-deterministic sort order due to missing sort
- [#25](https://github.com/BixData/stuart-ml/issues/25) VectorWithNorm initializer fails to compute norm when not explicitly provided

## [0.1.8] - 2018-10-14
### Added
- Lua 5.3 support
- [#17](https://github.com/BixData/stuart/issues/17) `stat:` Ported `MultivariateOnlineSummarizer` class, `RowMatrix` numCols(), numRows(), computeColumnSummaryStatistics(), and updateNumRows(), and `statistics` colStats()
- [#20](https://github.com/BixData/stuart/issues/20) Package and deploy releases to [npmjs.com](https://www.npmjs.com/package/lua-stuart-ml) and [jsDelivr](https://www.jsdelivr.com/package/npm/lua-stuart-ml)

### Changed
- [#15](https://github.com/BixData/stuart-ml/issues/15) Remove stuart-sql LuaRocks dependency. It is still used when present, but no longer required.

## [0.1.7] - 2018-10-12
### Changed
- Upgrade to Stuart 0.1.7

## [0.1.5] - 2017-12-12
### Added
- `clustering:` Ported `KMeansModel`
- `util:` Ported `Loader`, which can load a `KMeansModel` from a Parquet file or directory of files, whether local or WebHDFS
- `util:` Ported `NumericParser`
- `util:` Ported `StringTokenizer`

## [0.1.3] - 2017-11-11
### Added
- `clustering:` Ported `KMeans` `fastSquaredDistance()`, `findClosest()` and `pointCost()`
- `linalg:` Ported `BLAS` `axpy()`, `dot()`, and `scal()`
- `linalg:` Ported `Vectors` `sqdist()`
- `linalg:` Implement `VectorWithNorm` equality (`__eq`)
- `util:` Ported `MLUtils` `EPSILON` and `fastSquaredDistance()`

### Changed
- `clustering:` Fixed KMeans getters and setters to match RDD API, not DataFrame API
- `linalg:` Vector types are now 0-based like Apache Spark
- Consolidate Apache Spark and Stuart unit tests into a single unified folder hierarchy

### Fixed
- `linalg:` Vector `numActives` and `numNonzeros` fields were not updating after changes to vector. `BLAS` functions mutate vectors. Changed fields to functions so that they're computed each time.

## [0.1.0] - 2017-10-28
### Added
- `clustering:` Ported `VectorWithNorm` datatype
- `linalg:` Ported `DenseVector` and `SparseVector` datatypes, plus their `Vectors` factory

<small>(formatted per [keepachangelog-1.1.0](http://keepachangelog.com/en/1.0.0/))</small>
