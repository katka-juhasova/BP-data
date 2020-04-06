# LuaJIT FFI binding for libquantum

This bindings are based on libquantum v1.1.1. The ffi.cdef were preprocessed from quantum.h:

````
$ gcc -DLINUX -C -E /usr/include/quantum.h  > preprocessed-quantum.h
````

## Test

The test is based on http://www.libquantum.de/api/1.0/Example.html

## Known issues

- quantum_density_operation() macro is not supported (see http://www.libquantum.de/api/1.0/Density-operator-formalism.html).
