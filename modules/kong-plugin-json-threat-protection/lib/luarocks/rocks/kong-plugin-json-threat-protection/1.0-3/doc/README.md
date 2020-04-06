# JSON Threat Protection plugin for Kong
[![][t1t-logo]][Trust1Team-url]

Kong is a scalable, open source API Layer *(also known as an API Gateway, or
API Middleware)*. Kong was originally built at [Mashape][mashape-url] to
secure, manage and extend over [15,000 APIs &
Microservices](http://stackshare.io/mashape/how-mashape-manages-over-15000-apis-and-microservices)
for its API Marketplace, which generates billions of requests per month.

Backed by the battle-tested **NGINX** with a focus on high performance, Kong
was made available as an open-source platform in 2015. Under active
development, Kong is now used in production at hundreds of organizations from
startups, to large enterprises and government departments.

[Website Trust1Team][Trust1Team-url]

[Website Kong][kong-url]

## Summary

Like XML-based services, APIs that support JavaScript object notation (JSON) are vulnerable to content-level attacks. Simple JSON attacks attempt to use structures that overwhelm JSON parsers to crash a service and induce application-level denial-of-service attacks. All settings are optional and should be tuned to optimize your service requirements against potential vulnerabilities.

Only works from Kong 0.8.0

## Roadmap

TBD

## Development

## Configuration Parameters

| key                      | default value | required | description                                                                                                                                                                                                                                                                                                                                                                                    |
|--------------------------|---------------|----------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| array_element_count      | 0             | FALSE    | Specifies the maximum number of elements allowed in an array. If you do not specify this element, or if you specify a negative integer, the system does not enforce a limit.                                                                                                                                                                                                                   |
| container_depth          | 0             | FALSE    | Specifies the maximum allowed containment depth, where the containers are objects or arrays. For example, an array containing an object which contains an object would result in a containment depth of 3. If you do not specify this element, or if you specify a negative integer, the system does not enforce any limit.                                                                    |
| object_entry_count       | 0             | FALSE    | Specifies the maximum number of entries allowed in an object. If you do not specify this element, or if you specify a negative integer, the system does not enforce any limit.                                                                                                                                                                                                                 |
| object_entry_name_length | 0             | FALSE    | Specifies the maximum string length allowed for a property name within an object. If you do not specify this element, or if you specify a negative integer, the system does not enforce any limit.                                                                                                                                                                                             |
| string_value_length      | 0             | FALSE    | Specifies the maximum length allowed for a string value. If you do not specify this element, or if you specify a negative integer, the system does not enforce a limit.                                                                                                                                                                                                                        |

## Errors

The JSONThreatProtection Policy types defines the following error messages:

| Message                                                                                                                 |
|-------------------------------------------------------------------------------------------------------------------------|
| JSONThreatProtection[ExceededContainerDepth]: Exceeded container depth, max X allowed, found Y.                         |
| JSONThreatProtection[ExceededObjectEntryCount]: Exceeded object entry count, max X allowed, found Y.                    |
| JSONThreatProtection[ExceededArrayElementCount]: Exceeded array element count, max X allowed, found Y.                  |
| JSONThreatProtection[ExceededObjectEntryNameLength]: Exceeded object entry name length, max X allowed, found Y (VALUE). |
| JSONThreatProtection[ExceededStringValueLength]: Exceeded string value length, max X allowed, found Y (VALUE)           |
| JSONThreatProtection[ExecutionFailed]: Execution failed. reason: X                                                      |

## License

```
This file is part of the Trust1Team(R) sarl project.
 Copyright (c) 2014 Trust1Team sarl
 Authors: Trust1Team development

 
This program is free software; you can redistribute it and/or modify
 it under the terms of the GNU Affero General Public License version 3
 as published by the Free Software Foundation with the addition of the
 following permission added to Section 15 as permitted in Section 7(a):
 FOR ANY PART OF THE COVERED WORK IN WHICH THE COPYRIGHT IS OWNED BY Trust1T,
 Trust1T DISCLAIMS THE WARRANTY OF NON INFRINGEMENT OF THIRD PARTY RIGHTS.

 This program is distributed in the hope that it will be useful, but
 WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
 or FITNESS FOR A PARTICULAR PURPOSE.
 See the GNU Affero General Public License for more details.
 You should have received a copy of the GNU Affero General Public License
 along with this program; if not, see http://www.gnu.org/licenses or write to
 the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 Boston, MA, 02110-1301 USA.

 The interactive user interfaces in modified source and object code versions
 of this program must display Appropriate Legal Notices, as required under
 Section 5 of the GNU Affero General Public License.

 
You can be released from the requirements of the Affero General Public License
 by purchasing
 a commercial license. Buying such a license is mandatory if you wish to develop commercial activities involving the Trust1T software without
 disclosing the source code of your own applications.
 Examples of such activities include: offering paid services to customers as an ASP,
 Signing PDFs on the fly in a web application, shipping OCS with a closed
 source product...
Irrespective of your choice of license, the T1T logo as depicted below may not be removed from this file, or from any software or other product or service to which it is applied, without the express prior written permission of Trust1Team sarl. The T1T logo is an EU Registered Trademark (n° 12943131).
```

[kong-url]: https://getkong.org/
[Trust1Team-url]: http://trust1team.com
[t1t-logo]: http://imgur.com/lukAaxx.png
[jwt-up-doc]: https://trust1t.atlassian.net/wiki/pages/viewpage.action?pageId=74547210