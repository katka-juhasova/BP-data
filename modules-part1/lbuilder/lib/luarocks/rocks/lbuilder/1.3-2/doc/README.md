# lbuilder
lbuilder is a Lua library to aid creating and building patterns. It uses operator overloading based on Lpeg.

## Reference

| **Unions**       | **Use**                                             |
| ------------ | ----------------------------------------------- |
| lbuilder.P   | Creates a new pattern                           |

| **Particles**    | **Use**                                             |
| ------------ | ----------------------------------------------- |
| lbuilder.c   | Creates a new capture                           |
| lbuilder.s   | Creates a new character set                     |
| lbuilder.l   | Creates a new literal                           |

| **Operators**       | **Use**                                                                   |
| --------------- | --------------------------------------------------------------------- |
| P + P           | Combines two patterns                                                 |
| P .. P          | Combines two patterns with brackets                                   |
| p + p           | Combines two particles                                                |
| -s              | Negates a set                                                         |
| s/"\*"          | Equivalent to \*                                                      |
| s/"+"           | Equivalent to +                                                       |
| s/"-"           | Equivalent to -                                                       |
| s/"?"           | Equivalent to ?                                                       |
| p/n             | Repeats the particle n times                                          |
| p/-n            | Repeats the particle n-1 times and negates the nth particle           |
| #p              | Creates a pattern from a particle                                     |
| P % str         | Tests a pattern                                                       |
| P * str         | Matches a pattern and returns captures                                | 
| P /str/rep/n    | Replaces the pattern in a string n times and returns str              |
| P /str/fn/n     | Passes a function to the replace and replaces n times and returns str |
| P /str/rep/bool | Replaces the pattern in a string if bool and returns str              |
| P /str/fn/bool  | Passes a function to the replace and replaces if bool, returns str    |

## License
This project is licensed under the MIT License.

## Documentation
You can find the documentation at the [wiki](http://lbuilder.daelvn.ga/wiki)

## Installation
You can install this library using LuaRocks
```
$ sudo luarocks install lbuilder
```
