# luna

luna is a wrapper to build api's based on [nginx's lua module](https://github.com/openresty/lua-nginx-module).
It provides a lean interface to integrate your custom api endpoints.

## interface

your endpoint definition file has to return a table containing an entry `routes`

    local my_endpoint = {}

    my_endpoint.routes = {
      { context = '/foo', method = 'GET', call = function(self) return my_endpoint:do_something() end }
    }

the subtables of `routes` has to provide the following entries

| entry   | description                                      |
| ------- | ------------------------------------------------ |
| context | part of the URL to this endpoint                 |
| method  | the HTTP request method                          |
| call    | the function that will be called on this request |

the function that is mapped to `call` has to return two values.
the first is the http status code the second is a table that will be send
as json to the client.

    function = my_endpoint.do_something(self)
      return ngx.HTTP_OK, { foo = { bla = true } }
    end

## example

    % > curl -X GET 127.0.0.1:8080/example/test && echo      
    {"msg":"Hi"}
    % > curl -X POST 127.0.0.1:8080/example/test/hi && echo  
    {"msg":"Hi"}
    % > curl -X DELETE 127.0.0.1:8080/example/test/bye && echo
    {"msg":"Bye"}
