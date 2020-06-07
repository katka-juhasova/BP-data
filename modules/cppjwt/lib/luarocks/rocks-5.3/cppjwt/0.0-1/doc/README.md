# lua-cpp-jwt
A small wrapper arround [jwt-cpp](https://github.com/Thalhammer/jwt-cpp) (to decode and verify jwt).

### Why

We couldn't find any jwt verification library for lua for the algorithm we use, and we chose [jwt-cpp](https://github.com/Thalhammer/jwt-cpp) because it supports many verification algorithms, besides being a single header library with an elegant api.

### Note
Currently, only decoding/verification are implemented (also, tailored for a specific algorithm).

As noted above, this wrapper is created for a speicifc use case!

### Building
A simple `Makefile` is created to build the lua library using [luarocks](https://luarocks.org/).
Doing `luarocks make` would build and copy shared library and lua files to correct destinations, you should have build essentials e.g. g++ with c++11 support, also jwt-cpp itself depends on libcrypto (openssl).

### Installation
The easiest way to use this library is to install via [luarocks](https://luarocks.org/)

`luarocks install cppjwt`

### Usage

Only decoding and verification are implemented for now, you can simply do:

```lua
jwt.decode_raw(token) -- returns a string
jwt.decode(token) -- returns a json object
jwt.verify(token, key) -- returns a boolean
````


```lua
local jwt = require('cpp.jwt')

local token = 'jwt_token_here'
local pubkey = [[public_key_here]]
-- decode_raw returns a json string
print(jwt.decode_raw(token))
-- decode returns a json object
local header = jwt.decode(token).header
print(header.alg)

if jwt.verify(token, pubkey) then
    print('verified')
else
    ...
end
```
