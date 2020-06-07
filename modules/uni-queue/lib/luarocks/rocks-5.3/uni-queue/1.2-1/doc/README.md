# uni-queue: double-ended queue where all elements must be unique

This is an implementation of a double-ended queue where all elements are forced to be unique. Pushing or extending the queue with an element already in the queue will fail.

Otherwise it can be used just like any double-ended queue.

## Testing

This module uses [busted](https://olivinelabs.com/busted/) for testing. Once you have that installed, navigate to the repository root directory and run:

	busted .

## Function summary

Function | Short description
---|---
clear | Clears the queue
contains | Check if item is element of queue
elements | Alias of elements\_left\_to\_right
elements\_left\_to\_right | Return all elements, left to right, without removing them
elements\_right\_to\_left | Return all elements, right to left, without removing them
extend | Alias of extend\_right
extend\_left | Add elements of list to left of queue
extend\_right | Add elements of list to right of queue
len | Count elements in queue, called by length operator
new | Create a queue
left\_to\_right | Iterate over elements from left to right
peek | Alias of peek\_right
peek\_left | Return leftmost element without removing it
peek\_right | Return rightmost element without removing it
pop | Alias of pop\_right
pop\_left | Return leftmost element and remove it
pop\_right | Return rightmost element and remove it
push | Alias of push\_right
push\_left | Add element to left side of queue
push\_right | Add element to right side of queue
remove | Remove element from queue, reorder other elements
reverse | Reverses order of elements relative to other functions
right\_to\_left | Iterate over elements from right to left
rotate | Pop elements from one side, immediately push to the other

## q:clear()

Removes all elements from the queue.

## q:contains(elem)

Returns true if `q` contains `elem`, and false otherwise.

## q:elements(), q:elements\_left\_to\_right(), q:elements\_right\_to\_left()

Returns a list containing all elements of the `q`, without altering `q`. Note that `elements` is an alias of `elements_left_to_right`.

## q:extend(list), q:extend\_left(list), q:extend\_right(list)

Attempts to add the elements of `list` to `q`, in order from `list[1]` to `list[#list]`. `extend_left` adds each element on the left, `extend_right` adds each element on the right and `extend` is an alias for `extend_right`.

If any elements of `list` are repeated, or any elements of `list` already exist in `q`, then these methods fail and return `false`. Otherwise they succeed and return `true`.

	uq = require("uni-queue")
	q = uq.new()
	q:extend_left({5, 6, 7}) --Returns true
	for elem in q:left_to_right() do print(elem) end
	--[[
		Prints the following 3 lines:
		7
		6
		5
	--]]

## q:len(), #q

Returns the number of elements in `q` as an integer.

	uq = require("uni-queue")
	q = uq.new()
	q:extend_left({5, 6, 7})
	#q --Returns 3

## new()

Creates a queue.

## q:left\_to\_right()

Iterate over the elements of `q` from left to right.

	for elem in q:left_to_right() do
		--Something
	end

Altering a queue while iterating over it causes [defined](README_iter.md), but complicated behaviour.

## q:peek(), q:peek\_left(), q:peek\_right()

Return the element from a side of the `q` without removing it from `q`. Note that `peek` is an alias of `peek_right`.

	uq = require("uni-queue")
	q = uq.new()
	q:extend_left({5, 6, 7})
	q:peek_right() --Returns 5
	q:peek_left() --Returns 7

## q:pop(), q:pop\_left(), q:pop\_right()

Return the element from a side of the `q` and remove it from `q`. Note that `pop` is an alias of `pop_right`.

	uq = require("uni-queue")
	q = uq.new()
	q:extend_left({5, 6, 7})
	q:pop_right() --Returns 5, and removes it from q
	q:pop_left() --Returns 7, and remove it from q
	#q --Returns 1, since only 1 element left in q

## q:push(elem), q:push\_left(elem), q:push\_right(elem)

Attempt to add `elem` on a side of `q`. Note that `push` is an alias of `push_right`.

If `elem` already exists in `q`, the push fails and `false` is returned. Otherwise, the push succeeds and `true` is returned.

	uq = require("uni-queue")
	q = uq.new()
	q:push_left(5) --Returns true. So do the next 2 pushes.
	q:push_left(6)
	q:push_left(7)
	q:push_left(5) --Returns false
	for elem in q:left_to_right() do print(elem) end
	--[[
		Prints the following 3 lines:
		7
		6
		5
	--]]

## q:remove(elem)

Removes `elem` from `q`. Note that `elem` occurs at most once in `q`, so after this call there will be no instances of `elem` in `q` at all.

## q:reverse()

Reverses the order of all elements of `q` relative to the other methods of this library. For example, the leftmost element becomes the rightmost, the second leftmost element becomes the second rightmost and so on.

	uq = require("uni-queue")
	q = uq.new()
	q:push_left(5)
	q:push_left(6)
	q:push_left(7) --Now 7 is leftmost, 5 is rightmost
	q:peek_left() --Returns 7
	q:peek_right() --Returns 5
	q:reverse()
	q:peek_left() --Returns 5
	q:peek_right() --Returns 7

## q:right\_to\_left()

Iterate over the elements of `q` from right to left.

	for elem in q:right_to_left() do
		--Something
	end

Altering a queue while iterating over it causes [defined](README_iter.md), but complicated behaviour.

## q:rotate(i)

If `i` is positive, moves `i` elements from the right side of `q` to the left, one by one. If `i` is negative, moves `i*-1` elements from the left side of `q` to the right, one by one.

If `i` is nil or not present, this function runs as though `i` were 1. If `i` is exactly 0, there is no effect.

In other words, if `i` is positive, `rotate(i)` is equivalent to running `q:push_left(q:pop())`, for `i` times. If `i` is negative, `rotate(i)` is equivalent to running `q:push(q:pop_left())`, for `i` times.
