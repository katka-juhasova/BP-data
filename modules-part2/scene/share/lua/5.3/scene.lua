local scene = {}

--[[
Utility functions
--]]

local function max_bounds(x, y, half_width, half_height)
  return x + half_width, y + half_height
end

local function min_bounds(x, y, half_width, half_height)
  return x - half_width, y - half_height
end

local function insert_all(src, dest)
  for _, value in ipairs(src) do
    table.insert(dest, value)
  end
end

--[[
A node representing a local transform.
--]]

local node = {}
node.__index = node

setmetatable(node, {
    __call = function(self, params)
      local new_node = setmetatable({}, self)
      self.init(new_node, params)
      return new_node
    end
  })

function node:init(params)
  self.x = (params and params.x) or 0
  self.y = (params and params.y) or 0
  self.sx = (params and params.sx) or 1
  self.sy = (params and params.sy) or 1
  self.rot = (params and params.rot) or 0
  self.halfw = (params and params.halfw) or 0
  self.halfh = (params and params.halfh) or 0
  self._id = (params and params.id) or nil
  self.listeners = {}
end

-- Adds id to id tables of all ancestors
function node:add_id(id, anode)
  self._ids = self._ids or {}
  self._ids[id] = anode
  if self.parent then self.parent:add_id(id, anode) end
end

-- Remove id from id tables of all ancestors
function node:remove_id(id)
  self._ids[id] = nil
  if self.parent then self.parent:remove_id(id) end
end

function node:attach(child)
  if not child then
    error("cannot attach nil.")
  elseif getmetatable(child) ~= scene.node then
    error("cannot attach non-node.")
  elseif child.parent == self then
    return -- already a child
  end

  child:detach()
  self.children = self.children or {}

  -- Add child to parent
  table.insert(self.children, child)
  child.parent = self
  child.pos_in_parent = #self.children

  -- Add id to id tables of all ancestors
  if child._id then
    self:add_id(child._id, child)
  end

  if child._ids then
    for id, anode in pairs(child._ids) do
      self:add_id(id, anode)
    end
  end

  self:expand_bounds(child:as_aabb())
end

function node:detach()
  if self.parent then
    table.remove(self.parent.children, self.pos_in_parent)

    -- Remove id from id tables of all ancestors
    if self._id then
      self.parent:remove_id(self._id)
    end

    if self._ids then
      for id, _ in pairs(self._ids) do
        self.parent:remove_id(id)
      end
    end

    self.parent = nil
    self.pos_in_parent = nil
  end
end

function node:get_root()
  return (self.parent and self.parent:get_root()) or self
end

function node:id()
  return self._id
end

function node:get_node(id)
  local root = self:get_root()
  return (root._id == id and root) or root._ids[id]
end

function node:apply_transform(xform)
  xform = xform or {}
  xform.x = (xform.x or 0) + self.x
  xform.y = (xform.y or 0) + self.y

  xform.sx = (xform.sx or 1) * self.sx
  xform.sy = (xform.sy or 1) * self.sy

  xform.rot = (xform.rot or 0) + self.rot
  return xform
end

function node:as_aabb()
  return self.x, self.y, self.halfw, self.halfh
end

function node:intersects(x, y, hw, hh)
  return (math.abs(self.x - x) <= (self.halfw + hw)) and
    (math.abs(self.y - y) <= (self.halfh + hh))
end

function node:contains(x, y, hw, hh)
  -- Handles case where querying with point
  if not hw or not hh then
    return (math.abs(self.x - x) <= self.halfw) and
      (math.abs(self.y - y) <= self.halfh)
  end

  local maxx, maxy = x + hw, y + hh
  local minx, miny = x - hw, y - hh
  return self:contains(maxx, maxy) and self:contains(minx, miny)
end

-- Expands the node bounds to encompass the given AABB or point.
function node:expand_bounds(x, y, hw, hh)
  hw = hw or 0
  hh = hh or 0
  local maxx, maxy = max_bounds(self:as_aabb())
  local minx, miny = min_bounds(self:as_aabb())
  local cmaxx, cmaxy = max_bounds(x, y, hw, hh)
  local cminx, cminy = min_bounds(x, y, hw, hh)

  if maxx < cmaxx then
    maxx = cmaxx
    self.halfw = maxx - self.x
  end

  if maxy < cmaxy then
    maxy = cmaxy
    self.halfh = maxy - self.y
  end

  if minx > cminx then
    minx = cminx
    self.halfw = self.x - minx
  end

  if miny > cminy then
    miny = cminy
    self.halfh = self.y - miny
  end
end

-- A helper function to recalculate the node bounds when positions have changed.
function node:calc_bounds()
  self.halfw = 0
  self.halfh = 0
  for _, child in ipairs(self.children) do
    self:expand_bounds(child:as_aabb())
  end
end

function node:on(event_type, listener)
  self.listeners[event_type] = self.listeners[event_type] or {}
  table.insert(self.listeners[event_type], listener)
  return listener
end

function node:off(event_type, listener)
  if listener == nil then
    self.listeners[event_type] = nil
  else
    local pos = nil
    for i, value in ipairs(self.listeners[event_type]) do
      if value == listener then
        pos = i
        break
      end
    end

    if pos ~= nil then
      table.remove(self.listeners[event_type], pos)
    end
  end
end

-- Sends event to current node only
function node:fire(event_type, ...)
  for _, listener in ipairs(self.listeners[event_type]) do
    local stopLocal, stopGlobal = listener(...)
    if stopGlobal then
      return false
    elseif stopLocal then
      break
    end
  end

  return true
end

-- Sends event to root
function node:emit(event_type, ...)
  if not self:fire(event_type, ...) then
    return
  end

  if self.parent then
    self.parent:emit(event_type, ...)
  end
end

-- Sends event to descendents
function node:broadcast(event_type, ...)
  if not self:fire(event_type, ...) then
    return
  end

  if not self.children then
    return
  end

  -- Breadth first traversal of scene tree
  local queue = {}
  local qpos = 1
  insert_all(self.children, queue)
  while qpos <= #queue do
    local next = queue[qpos]
    if not next:fire(event_type, ...) then
      return
    end

    if next.children then
      insert_all(next.children, queue)
    end

    qpos = qpos + 1
  end
end

scene.node = node

-----------------------------------------------

return scene
