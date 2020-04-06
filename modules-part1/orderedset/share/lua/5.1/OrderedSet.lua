--[[

Copyright (C) 2016 Ivan Baidakou

Licence: Artistic License 2.0

]]--

local OrderedSet = {}
OrderedSet.__index = OrderedSet

function OrderedSet.new(items)
  local o = {
    node_for = {}, -- k: object, v: node
    head     = nil,
    tail     = nil,
    capacity = 0,
  }
  setmetatable(o, OrderedSet)
  if (items) then
    local prev = o.head
    for idx, item in pairs(items) do
      o:insert(item)
    end
  end
  return o
end


function OrderedSet:_find_node(index)
  local current = self.head
  local i = 1
  while (current) do
    if (i == index) then break end
    i = i + 1
    current = current._next
  end
  return current
end


function OrderedSet:insert(item, index)
  if (self.node_for[item]) then
    error(string.format('Set already contains "%s" key', tostring(item)))
  end

  local prev
  if (not index) then
    prev = self.tail
  else
    if (index > self.capacity + 1) then
      error("index " .. index .. " can't be greater than " .. self.capacity + 1)
    end
    if (index < 1) then
      error("index " .. index .. " can't be used (shoudl be > 1)")
    end
    prev = (index == self.capacity + 1)
          and self.tail
          or (index == 1)
          and nil
          or self:_find_node(index)._prev
  end

  local node = {
    _item = item,
    _next = nil,
    _prev = prev,
  }

  if (prev) then
    local prev_next = prev._next
    prev._next = node
    node._next = prev_next
  end

  if (not self.head) then
    self.head = node
    self.tail = node
  end
  if ((index == 1) and (self.head)) then
    self.head._prev = node
    node._next = self.head
    self.head = node
  end

  if (not node._next) then
    self.tail = node
  end

  self.node_for[item] = node
  self.capacity = self.capacity + 1
end

function OrderedSet:remove(item)
  local node = self.node_for[item]
  if (not node) then
    error(string.format('Set does not contain "%s" key, cannot remove it', tostring(item)))
  end

  local _prev = node._prev
  local _next = node._next

  if (_prev) then
    _prev._next = _next
  else
    self.head = _next
  end

  if (_next) then
    _next._prev = _prev
  else
    self.tail = _prev
  end

  self.capacity = self.capacity - 1
  self.node_for[item] = nil
end

function OrderedSet:pairs(reverse)
  local i, node, next_prop, step

  if (not reverse) then
    step = 1
    i = 0
    node = self.head
    next_prop = '_next'
  else
    step = -1
    i = self.capacity
    node = self.tail
    next_prop = '_prev'
  end

  local iterator = function(state, value) -- ignored
    if (node) then
      i = i + step
      local item = node._item
      node = node[next_prop]
      return i, item
    end
  end
  return iterator, nil, true
end


return OrderedSet
