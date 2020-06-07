# Altering a Queue While Iterating

While iterating over a queue created by this package, it is possible to alter the queue.

	uq = require("uni-queue")
	q = uq.new()
	q:extend({"Mercury", "Venus", "Earth", "Mars"})
	for elem in q:left_to_right() do
		q:remove("Mars")
		print(elem)
	end
	--[[
		Outputs the following 3 lines:
		Mercury
		Venus
		Earth
	--]]

While the behaviour is defined and tracked by regression tests, it is quite complicated. Users of `uni-queue` may find it advantageous to avoid the complexity by not altering queue while iterating over it. If avoidance is not an option, this page describes the situation.

## General Principles

`uni-queue` provides two iterator factories: `left_to_right` and `right_to_left`. They behave identically, except that they iterate in opposite directions. **Code that alters a queue while iterating depends critically on the direction of iteration.** All examples on this page will use `left_to_right`, so all directions of other calls will need to be switched to work with `right_to_left`.

	uq = require("uni-queue")
	q = uq.new()
	q:extend({"Mercury", "Venus", "Earth", "Mars"})
	for elem in q:left_to_right() do
		--Something with elem
	end

During each iteration, an element from `q` is exposed: `elem`. The iterators require `elem` to find the next element of the queue, so **removing `elem` from the queue and attempting the next iteration causes an error**. However, this does not extend to removing other elements of the `q`, such as `elem` from previous iterations.


	uq = require("uni-queue")
	q = uq.new()
	q:extend({"Mercury", "Venus", "Earth", "Mars"})
	local prev
	for elem in q:left_to_right() do
		q:remove(prev)
		prev = elem
	end
	for elem in q:left_to_right() do print(elem) end
	--prints "Mars"

Additionally, removing `elem` is not an error if there are no more calls to the iterator for the current loop.

	uq = require("uni-queue")
	q = uq.new()
	q:extend({"Mercury", "Venus", "Earth", "Mars"})
	for elem in q:left_to_right() do
		if elem == "Mars" then
			q:remove(elem)
			break
		end
		--"Mars" is the last value.
		--However, the iterator will still look for it.
		--So the iterator call must be prevented with break.
	end
	--Future loops will still operate.

Adding elements to a queue opposite to the direction of iteration has no effect on the iteration. However, **adding elements in the direction of iteration will cause them to be iterated over**.

	uq = require("uni-queue")
	q = uq.new()
	q:extend({"Mercury", "Venus", "Earth", "Mars"})
	i = 1
	for elem in q:left_to_right() do
		q:push_left(i) --Not printed, but pushes succeed
		--q:push(i) --Causes an infinite loop if uncommented
		print(elem)
		i = i + 1
	end

However, queues in `uni-queue` must have unique elements, so infinite looping will not occur when pushing fixed values.

	uq = require("uni-queue")
	q = uq.new()
	q:extend({"Mercury", "Venus", "Earth", "Mars"})
	for elem in q:left_to_right() do
		q:push_left("Sun") --Only succeeds once
		q:push("Jupiter") --Only succeeds once
		print(elem)
	end
	--[[
		Output:
		Mercury
		Venus
		Earth
		Mars
		Jupiter
	--]]

## clear()

Clearing a queue while iterating over it causes an error on the next iteration.

## extend(), extend\_left(), extend\_right()

Successfully extending the queue in the direction of iteration will cause the new values to be exposed during the loop. Extending in the opposite direction will not affect the loop.

## pop(), pop\_left(), pop\_right()

Popping the currently exposed element causes an error on the next iteration. Popping on the origin end of the queue has no effect on the loop unless `elem` is the first element. Popping on the destination end of the queue will prevent the popped value from being exposed during the loop, and will only cause an error if `elem` is the value popped.

## push(), push\_left(), push\_right()

Successfully pushing the queue in the direction of iteration will cause the new values to be exposed during the loop. Pushing in the opposite direction will not affect the loop.


## remove()

Removing `elem` causes an error on the next iteration. This is true even if `elem` is the final value to be exposed in the loop.

## reverse()

Reversing the queue during iteration will not affect the iterator, but will affect other functions in `uni-queue`.

	uq = require("uni-queue")
	q = uq.new()
	q:extend({"Mercury", "Venus", "Earth", "Mars"})
	for elem in q:left_to_right() do
		q:reverse()
		print(elem, q:peek())
	end
	--[[
		Output:
		Mercury	Mercury
		Venus	Mars
		Earth	Mercury
		Mars	Mars
	--]]

However, reversing the queue outside iteration definitely affects the iterator.

## rotate()

Each rotation is effectively a pop followed by a push on the other side. This applies during iteration as well.
