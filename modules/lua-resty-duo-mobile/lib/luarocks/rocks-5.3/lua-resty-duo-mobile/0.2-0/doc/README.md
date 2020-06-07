Name
====

lua-resty-duo-mobile

Status
======

This library is production ready.

Description
===========

This library provides a client interface for the [Duo Mobile Auth API](https://duo.com/docs/authapi), providing strong two-factor authentication for websites or applications.

Synopsis
========

```lua
local cjson = require "cjson.safe"
local duo = require "resty.duo"


-- create a new integration object based on the application data created
-- by Duo's admin interface
local d = duo.new({
  ikey = "integation key",
  skey = "secret key",
  host = "api-XXXXXXXX.duosecurity.com",
})


-- the 'duo_request' method can be used to call various Duo Auth API endpoints
-- see https://duo.com/docs/authapi#/check
local res, err = d:duo_request('check')

if not res then
  ngx.log(ngx.ERR, "Could not contact Duo API server")
end

if res.status ~= 200 then
  ngx.log(ngx.ERR, "Duo API server returned invalid status code")
end

local body = cjson.decode(res.body)
if not body then
  ngx.log(ngx.ERR, "Could not decode Duo API server response")
end

if body.stat ~= "OK" then
  ngx.log(ngx.ERR, "Duo API server returned invalid API response")
end


-- several methods are provided to wrap API response and error checking
-- for example, enroll a new user with the application
-- see https://duo.com/docs/authapi#/enroll
local res, msg = d:enroll(username)
if not res then
  ngx.log(ngx.ERR, msg)
end


-- authenticate a user (having been previously authenticated by your application)
-- note the second param can be used to provide the IP address to Duo to identify
-- requests coming from a trusted remote address
-- if the request is successful, the 'preauth' object will be in the form noted at
-- https://duo.com/docs/authapi#/preauth
local preauth, err = d:preauth(username, ngx.var.remote_addr
if err then
  ngx.log(ngx.ERR, msg)
end


-- from here, examine the 'preauth.result' value and act accordingly. refer to the API
-- documentation for details. in the case of an 'auth' result, request should be
-- authenticated with Duo
-- see https://duo.com/docs/authapi#/auth
local auth, err = d:auth(username, factor, duo_params)
if err then
  ngx.log(ngx.ERR, msg)
end
if auth.result == "deny" then
  ngx.exit(ngx.HTTP_UNAUTHORIZED)
end
```


Usage
=====

duo.new
-------

**syntax**: *duo_object = duo.new(opts)*

Create a new `duo` object based on the Duo Application configuration options:

**opts.ikey**: The application integration key.
**opts.skey**: The application secret key.
**opts.host**: The application hostname.

duo:enroll
----------

**syntax**: *res, err = duo:enroll(username)*

Enroll a new user with the Duo application. On sucess, `err` will be nil and `res` will be a table returned from the `/enroll` Duo Auth API endpoint. If there is a failure in the HTTP transaction or an API err, `res` will be nil and `err` will be a string describing the failure. The string may be JSON-encoded data if an error is returned from the Duo Auth API.

duo:preauth
-----------

**syntax**: *preauth, err = duo:preauth(username, ipaddr)*

Pre-authenticate a user with the Duo Auth API. This method determines whether a user is authorized to log in, and (if so) returns the user's available authentication factors. On sucess, `err` will be nil and `res` will be a table returned from the `/preauth` Duo Auth API endpoint. If there is a failure in the HTTP transaction or an API err, `res` will be nil and `err` will be a string describing the failure. The string may be JSON-encoded data if an error is returned from the Duo Auth API.

The `ipaddr` param may be provided as the IP address of the client in dotted-quad notation. This will cause an "allow" response to be sent if appropriate for requests from a trusted network.

duo:auth
--------

**syntax**: *auth, err = duo:auth(username, factor, duo_params)*

Authenticate a user with the Duo Auth API. This method performs second-factor authentication for a user by sending a push notification to the user's smartphone app, verifying a passcode, or placing a phone call. It is also used to send the user a new batch of passcodes via SMS. On sucess, `err` will be nil and `res` will be a table returned from the `/auth` Duo Auth API endpoint. If there is a failure in the HTTP transaction or an API err, `res` will be nil and `err` will be a string describing the failure. The string may be JSON-encoded data if an error is returned from the Duo Auth API.

The appropriate `factor` and `duo_params` method parameters should be defined based on the response from the `preauth` call. `factor` should be a string value such as `push` or `sms`, and `duo_params` should be formatted as a table of factor-specific parameters to pass to Duo Auth. See [Duo Auth API documentation](https://duo.com/docs/authapi#/auth) for specific details.

duo:duo_request
---------------

**syntax**: *res, err = duo:duo_request(endpoint, api_params)

Low-level call to generate a Duo Auth API request based on the API endpoint and appropriate parameters. This method will sign the HTTP request with the `duo` object's `ikey`/`skey` values, and return the request of a `lua-resty-http:request_uri` call.

duo.sign
--------

**syntax**: *date, sig = duo.sign(method, host, path, params, ikey, skey)*

Static function to sign an HTTP request as defined in the [Duo Auth API documentation](https://duo.com/docs/authapi#authentication). In general this function does not need to be called as part of a typicaly request flow.

TODO
====

* Add wrapper methods around remaining Duo Auth API endpoints (`/enroll_status`, `auth_status`, etc).
* Clean up error handling a bit in `read_duo_response`.
* Validate `duo` object on creation.
* Implement native support for async auth requests.

License
=======

Copyright (c) 2018, Robert Paprocki
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

* Redistributions of source code must retain the above copyright notice, this
  list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright notice,
  this list of conditions and the following disclaimer in the documentation
  and/or other materials provided with the distribution.

* Neither the name of the copyright holder nor the names of its
  contributors may be used to endorse or promote products derived from
  this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
