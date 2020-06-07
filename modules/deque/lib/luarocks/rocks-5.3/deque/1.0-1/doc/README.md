# Lua Deque
Double-ended queue that works under any version and environment of Lua
### Installation

Install with [LuaRocks](https://luarocks.org)

```sh
$ luarocks install --server=http://luarocks.org/dev deque
```

### Methods
| Method | Description |
| ------ | ------ |
| new | creates a new deque object |
| pushLeft | pushes an item to the left side |
| pushRight | pushes an item to the right side |
| popLeft | pops and item from the left side and returns it |
| popRight | pops and item from the right side and returns it |
| peekLeft | returns the item from the left side, but does not pop it |
| peekRight | returns the item from the right side, but does not pop it |
| iterLeft | iterates through the items, from left to right |
| iterRight | iterates through the items, from right to left |
| getIndex | returns the index of the item, or nil if it doesn't exist |
| isEmpty | returns a boolean if the deque is empty |
| reverse | reverses the items in the deque |
| clear | clears all items from the deque |

### Properties
| Property | Description |
| ------ | ------ |
| count | returns the number of items in the deque |
| objects | returns all the items in the deque in a Lua table |

### Examples

```lua
local deque = require("deque")()

--push an item to the left side of the deque
deque:pushLeft("apples")

--push an item to the right side of the deque
deque:pushRight("bananas")

--return the number of objects in the deque
print(deque.count) -- returns: 2

--pop an item from the left side
print(deque:popLeft()) -- returns: apples

--pop an item from the right side
print(deque:popRight()) -- returns: bananas
print(deque.count) -- returns: 0

--let's add 5 items to the deque and iterate through them
for i = 1, 5 do
    deque:pushLeft(i)
end

for obj in deque:iter() do --iterates through the items, from left to right
    print(obj)
end

print(deque.count) -- returns: 5

for obj in deque:iterRight() do --iterates through the items, from right to left
    print(obj)
end

--[[

other methods:
    deque:sendRight(obj) --> pops the item if it exists, and sends it to the right.
    deque:sendLeft(obj) --> pops the item if it exists, and sends it to the left.
    deque:peekLeft --> returns the item from the left side, but does not pop it
    deque:peekRight --> returns an item from the right side, but does not pop it
    deque:getIndex(obj) --> return the index of the obj if it exists in the deque
    deque:reverse() --> reverses the order of the objects
    deque:iterLeft() --> alias for deque.iter; iterates through the items, from left to right
    deque:iterRight() --> iterates through the items, from right to left
    deque:clear() --> clears all items from the deque
    deque:isEmpty() --> returns a boolean if the deque is empty


]]

```
