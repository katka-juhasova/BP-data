## [0.8.0-3] - 2017-12-12
### Added:
- New `openString()` semantics to read directly from a string buffer

## [0.8.0-2] - 2017-12-09
### Added:
- Port `ParquetEnvelopeReader` `decodeDataPage()`, `decodeDataPageV2()`, `readRowGroup()`, and `readColumnChunk()`
- Registration of compression adapters

### Fixed:
- [issue-19](https://github.com/BixData/lua-parquet/issues/19) ParquetReader `decodeSchema()` was skipping last nested element
- [issue-26](https://github.com/BixData/lua-parquet/issues/26) Non-determinism in `materializeRecords()`
- Fixed rowcounts by upgrading to [thrift](https://github.com/BixData/lua-thrift) 0.10.0-4 (zigzag decode was missing)

## [0.8.0-1] - 2017-12-02
### Added:
- Port `ParquetReader` `decodeSchema()`
- Port `ParquetEnvelopeReader` `openFile()`, `readHeader()`, and `readFooter()`

## [0.8.0-0] - 2017-11-24
### Added:
- Port `ParquetSchema`
- Port `ParquetShredder`
- Port `codec/plain` decoding
- LuaRocks packaging

<small>(formatted per [keepachangelog-1.1.0](http://keepachangelog.com/en/1.0.0/))</small>
