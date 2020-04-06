# Changelog

All changes made on any release of this project should be commented on high level of this document.

Document model based on [Semantic Versioning](http://semver.org/).
Examples of how to use this _markdown_ cand be found here [Keep a CHANGELOG](http://keepachangelog.com/).

## [0.13.0](https://github.com/stone-payments/kong-plugin-template-transformer/tree/v0.13.0) - 2020-01-17

### Added

- [Allow json objects in template](https://dev.azure.com/stonepagamentos/frt-portal/_workitems/edit/108772)

## [0.12.3](https://github.com/stone-payments/kong-plugin-template-transformer/tree/v0.12.3) - 2019-10-23

### Fixed

- No Content handling.

## [0.12.2](https://github.com/stone-payments/kong-plugin-template-transformer/tree/v0.12.2) - 2019-08-15

### Fixed

- Escape carriages and end of lines.

## [0.12.1](https://github.com/stone-payments/kong-plugin-template-transformer/tree/v0.12.1) - 2019-07-19

### Added

- JSON examples folder and validator.

## [0.12.0](https://github.com/stone-payments/kong-plugin-template-transformer/tree/v0.12.0) - 2019-07-10

### Fixed

- Escape tabs.

## [0.11.1](https://github.com/stone-payments/kong-plugin-template-transformer/tree/v0.11.1) - 2019-06-21

### Fixed

- Escape bars.

## [0.11.0](https://github.com/stone-payments/kong-plugin-template-transformer/tree/v0.11.0) - 2019-05-22

### Fixed

- Remove luajit and set lua version to 5.1.

## [0.10.1](https://github.com/stone-payments/kong-plugin-template-transformer/tree/v0.10.1) - 2019-05-17

### Fixed

- Special characters scaped in body_filter.

## [0.10.0](https://github.com/stone-payments/kong-plugin-template-transformer/tree/v0.10.0) - 2019-04-15

### Added

- Add Kong 1 support by removing kong.errors.dao

## [0.9.0](https://github.com/stone-payments/kong-plugin-template-transformer/tree/v0.9.0) - 2019-01-18

### Added

- Dockerfile to simplify development
- Raw_body to template context

## [0.8.0](https://github.com/stone-payments/kong-plugin-template-transformer/tree/v0.8.0) - 2018-10-30

### Added

- Travis for CI/CD

## [0.7.2](https://github.com/stone-payments/kong-plugin-template-transformer/tree/v0.7.2) - 2018-10-10

### Fixed

- Execution of templates when they are empty strings.

## [0.7.1](https://github.com/stone-payments/kong-plugin-template-transformer/tree/v0.7.1) - 2018-10-02

### Fixed

- Read JSON only when the payload is not an empty string.

## [0.7.0](https://github.com/stone-payments/kong-plugin-template-transformer/tree/v0.7.0) - 2018-09-20

### Fixed

- Log severities to better represent information.

## [0.6.0](https://github.com/stone-payments/kong-plugin-template-transformer/tree/v0.6.0) - 2018-08-28

### Added

- Configuration variable hide fields and not log them.

## [0.5.0](https://github.com/stone-payments/kong-plugin-template-transformer/tree/v0.5.0) - 2018-07-09

### Added

- Adds ngx.ctx.custom_data to template information.

## [0.4.0](https://github.com/stone-payments/kong-plugin-template-transformer/tree/v0.4.0) - 2018-05-23

### Fixed

- Params validation that was not been called.
- Empty body with request_templates that were broken.
- Special characters in request-templates.

### Changed

- Package name in rockspec.

## [0.3.0](https://github.com/stone-payments/kong-plugin-template-transformer/tree/v0.3.0) - 2018-05-17

### Fixed

- Stops relying on content-type header and tries to parse the response from the API, returning bad request if not possible
- Passes body to the request table as a table, not string

## [0.2.2](https://github.com/stone-payments/kong-plugin-template-transformer/tree/v0.2.2) - 2018-05-10

### Added

- Status-code as an argument to templates.

### Fixed

- Only reads response body as JSON when content-type is correct.

### Removed

- Template files

## [0.2.1](https://github.com/stone-payments/kong-plugin-template-transformer/tree/v0.2.1) - 2018-05-04

### Fixed

- Template transformer import

## [0.2.0](https://github.com/stone-payments/kong-plugin-template-transformer/tree/v0.2.0) - 2018-04-24

### Added

- Can use regex uri patterns inside the templates.
- VSTS support.

## [0.1.0](https://github.com/stone-payments/kong-plugin-template-transformer/tree/v0.1.0) - 2018-04-16

### Added

- First version of the template transformer plugin
