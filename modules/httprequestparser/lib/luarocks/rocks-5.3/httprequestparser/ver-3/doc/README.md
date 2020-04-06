# http request parser
httprequestparser is lua based parser. http parser is module for parsing http requests
Http Parser is written entirely in lua.

Users of this module can get http request data from for http request like request payload, headers, Method, URI, Host.

Note:
    Supports haproxy only for now.

----

Dependencies included:
- dkjson
- lxp.lom

Users of this module can get objects(xml/json) on basis of headers. 
If request payload is xml format then get XML object or if request payload is json format then get JSON object by functions provided.

----

Documentation:
```sh
- httprequestparser.getContentType(requestBodyBuffer):
    fetches Content-Type header from request body.
    
- httprequestparser.getAccept(requestBodyBuffer)
    fetches Accept header from request body.
    
- httprequestparser.getHost(requestBodyBuffer)
    fetches host from request body.
    
- httprequestparser.getAllHeaders(requestBodyBuffer)
    fetches All headers from request body in table form.
    
- httprequestparser.getHttpMethod(requestBodyBuffer)
    fetches Http method from request body.
    
- httprequestparser.getRequestURI(requestBodyBuffer)
    fetches http request uri from request body.

- httprequestparser.findElementFromRequestBody(requestBodyBuffer, element)
    fetches any element from request body.
    
- httprequestparser.isXMLBody(requestBodyBuffer)
    returns true or false if request body is in xml format
    
- httprequestparser.isJSONBody(requestBodyBuffer)
    returns true or false if request body is in json format
    
- httprequestparser.getRequestBodyAsString(requestBodyBuffer)
    returns request body as plain string from http request buffer.
    
- httprequestparser.handleJsonBody(requestBodyBuffer)
    returns Json Object if request body is in Json format. Can call dkjson modules function on this object.
    
- httprequestparser.handleXMLBody(requestBodyBuffer)
    returns XML Object if request body is in XML format. Can call lxp.lom modules function on this object.
    
```
----

### Todos

 - Convert Http request data to object in terms of object oriented paradigm.
 - Support for nginx server.
 
 
 License
----

MIT
