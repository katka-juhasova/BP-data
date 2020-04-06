# lua-ref

a value reference operation module.


## Installation

```sh
luarocks install ref --from=http://mah0x211.github.io/rocks/
```


## Functions


### k = ref.get( v )

create reference of the `v` into `LUA_REGISTRYINDEX` and return a reference number.

- **Parameters**
    - `v`: value to be referenced by `k`.
- **Returns**
    - `k:integer`: reference number.


### v = ref.val( k )

get value of reference `k`.

- **Parameters**
    - `k:integer`: reference number of value `v`.
- **Returns**
    - `v`: value referenced by `k`.


### v = ref.del( k [, retval] )

releases reference `k` from `LUA_REGISTRYINDEX`.

- **Parameters**
    - `k:integer`: reference number.
    - `retval:boolean`: set to `true` if value is required.
- **Returns**
    - `v`: value referenced by `k`.


