# skewheap

`skewheap` is a lua library providing a self-adjusting heap. A skew heap is
notable for its ability to be quickly merged with another skew heap.

See [wikipedia](https://en.wikipedia.org/wiki/Skew_heap) for details.


# Usage

    require 'skewheap'

    a = SkewHeap.new()
    a:put(10, 30, 5, 3)
    a:take() --  5
    a:take() -- 10
    a:take() -- 30

    b = SkewHeap.new()
    b:put(45, 22)

    c = a:merge(b) -- c: [3, 22, 45]
                   -- a: [3]
                   -- b: [22, 45]


# Installation

SOON


# Methods

## new

Returns a new, empty skew heap.

## items

Returns the number of items in the heap.

## is_empty

Returns true if the heap has no items in it.

## put(...)

Adds a variable number of items to the heap. Returns the number of items in the
heap after insertion.

## take(count)

Removes and returns `count` items from the heap.

## peek

Returns the next item in the heap _without_ removing it.

## merge

Combines two heaps into a new heap containing all of the items in the other
heaps. The source heaps are not modified in any way.


# Author

Jeff Ober <sysread@fastmail.fm>


# License

[MIT](./LICENSE)
