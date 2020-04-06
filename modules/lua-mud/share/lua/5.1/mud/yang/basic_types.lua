local luadate = require("date")
local url = require("socket.url")

local json = require("cjson")

local util = require("mud.yang.util")

local _M = {}

local YangNode = util.subClass("YangNode", nil)
local YangNode_mt = { __index = YangNode }
function YangNode:create(typeName, nodeName, mandatory)
  local new_inst = {}
  setmetatable(new_inst, YangNode)
  new_inst.value = nil
  new_inst.typeName = typeName
  new_inst.nodeName = nodeName
  new_inst.parent = nil
  if mandatory ~= nil then
    new_inst.mandatory = mandatory
  else
    new_inst.mandatory = true
  end
  return new_inst
end

function YangNode:getName()
  return self.nodeName
end

function YangNode:getType()
  return self.typeName
end

function YangNode:getValue()
  return self.value
end

function YangNode:hasValue(value)
  return self.value ~= nil
end

function YangNode:clearData()
  self.value = nil
end

function YangNode:setValue(value)
  error("setValue needs to be implemented in subclass")
end

function YangNode:validate()
  error("validate needs to be implemented in subclass")
end

function YangNode:isMandatory()
  return self.mandatory
end

-- tries to set data. returns true if success, fail if not
function YangNode:fromData_noerror(data)
  r,err = pcall(self.setValue, self, data)
  return r
end

-- returns the current value as native data; for simple types, this
-- is just the value itself
function YangNode:toData()
  return self.value
end

-- Returns the first node that matches the given xpath-style path
-- foo/bar[1]/value
-- returns nil+error if the path cannot be found
function YangNode:getNode(path)
  error("Cannot use getNode on a basic type")
end

-- Returns all the child nodes as a list; for simple types,
-- this returns a list with the node itself as its only content
function YangNode:getAll()
  local result = {}
  table.insert(result, self)
  return result
end

function YangNode:getParent()
  return self.parent
end

function YangNode:getRootNode()
  local curNode = self
  while curNode:getParent() ~= nil do
    curNode = curNode:getParent()
    if (curNode:getParent() == nil) then
    end
  end
  return curNode
end

function YangNode:setParent(parent, recurse)
  self.parent = parent
end

-- requester may be zero; it is passed to the getPath of the
-- parent; in some cases the result may differ depending on who's asking
-- (like, say, list indices)
function YangNode:getPath(requester)
  if requester ~= nil then
  end
  if self.parent ~= nil then
    return self.parent:getPath(self) .. "/" .. self:getName()
  else
    return self:getName()
  end
end
_M.YangNode = YangNode

local uint8 = util.subClass("uint8", YangNode)
uint8_mt = { __index = uint8 }
function uint8:create(nodeName, mandatory)
  local new_inst = YangNode:create("uint8", nodeName, mandatory)
  setmetatable(new_inst, uint8_mt)
  return new_inst
end

function uint8:setValue(value)
  if type(value) == 'number' then
    if value < 0 or value > 255 then
      error("value for " .. set.getType() .. " out of range: " .. value)
    else
      self.value = value
    end
  else
    error("type error: " .. self:getType() .. ".setValue() with type " .. type(value) .. " instead of number")
  end
end
_M.uint8 = uint8

local uint16 = util.subClass("uint16", YangNode)
uint16_mt = { __index = uint16 }
function uint16:create(nodeName, mandatory)
  local new_inst = YangNode:create("uint16", nodeName, mandatory)
  setmetatable(new_inst, uint16_mt)
  return new_inst
end

function uint16:setValue(value)
  if type(value) == 'number' then
    if value < 0 or value > 65535 then
      error("value for " .. set.getType() .. " out of range: " .. value)
    else
      self.value = value
    end
  else
    error("type error: " .. self:getType() .. ".setValue() with type " .. type(value) .. " instead of number")
  end
end
_M.uint16 = uint16

local uint32 = util.subClass("uint32", YangNode)
uint32_mt = { __index = uint32 }
function uint32:create(nodeName, mandatory)
  local new_inst = YangNode:create("uint32", nodeName, mandatory)
  setmetatable(new_inst, uint32_mt)
  return new_inst
end

function uint32:setValue(value)
  if type(value) == 'number' then
    if value < 0 or value > 4294967295 then
      error("value for " .. set.getType() .. " out of range: " .. value)
    else
      self.value = value
    end
  else
    error("type error: " .. self:getType() .. ".setValue() with type " .. type(value) .. " instead of number")
  end
end
_M.uint32 = uint32

local boolean = util.subClass("boolean", YangNode)
boolean_mt = { __index = boolean }
function boolean:create(nodeName, mandatory)
  local new_inst = YangNode:create("boolean", nodeName, mandatory)
  setmetatable(new_inst, boolean_mt)
  return new_inst
end

function boolean:setValue(value)
  if type(value) == 'boolean' then
    self.value = value
  else
    error("type error: " .. self:getType() .. ".setValue() with type " .. type(value) .. " instead of boolean")
  end
end
_M.boolean = boolean

local inet_uri = util.subClass("inet_uri", YangNode)
inet_uri_mt = { __index = inet_uri }
function inet_uri:create(nodeName, mandatory)
  local new_inst = YangNode:create("inet_uri", nodeName, mandatory)
  setmetatable(new_inst, inet_uri_mt)
  return new_inst
end

function inet_uri:setValue(value)
  if type(value) == 'string' then
    self.uri_parts = url.parse(value, nil)
    if self.uri_parts == nil or self.uri_parts['host'] == nil then
      error("value for " .. self:getType() .. ".setValue() is not a valid URI: " .. value)
    end
    self.value = value
  else
    error("type error: " .. self:getType() .. ".setValue() with type " .. type(value) .. " instead of string")
  end
end
_M.inet_uri = inet_uri

local date_and_time = util.subClass("date_and_time", YangNode)
date_and_time_mt = { __index = date_and_time }
function date_and_time:create(nodeName, mandatory)
  local new_inst = YangNode:create("yang:date-and-time", nodeName, mandatory)
  setmetatable(new_inst, date_and_time_mt)
  return new_inst
end

function date_and_time:setValue(value)
  if type(value) == 'string' then
    local success, result = pcall(luadate, value)
    if not success then
      error("value for " .. self:getType() .. ".setValue() is not a valid datetime: " .. result)
    end
    self.date = result
    self.value = value
  else
    error("type error: " .. self:getType() .. ".setValue() with type " .. type(value) .. " instead of string")
  end
end
_M.date_and_time = date_and_time

local mac_address = util.subClass("mac_address", YangNode)
mac_address_mt = { __index = mac_address }
function mac_address:create(nodeName, mandatory)
  local new_inst = YangNode:create("mac_address", nodeName, mandatory)
  setmetatable(new_inst, mac_address_mt)
  return new_inst
end

function mac_address:setValue(value)
  if type(value) == 'string' then
    if not string.match(value, "^%x%x:%x%x:%x%x:%x%x:%x%x:%x%x$") then
      error("value for " .. self:getType() .. ".setValue() is not a valid MAC address: " .. value)
    end
    self.value = value
  else
    error("type error: " .. self:getType() .. ".setValue() with type " .. type(value) .. " instead of string")
  end
end
_M.mac_address = mac_address

local eth_ethertype = util.subClass("eth_ethertype", YangNode)
eth_ethertype_mt = { __index = eth_ethertype }
function eth_ethertype:create(nodeName, mandatory)
  local new_inst = YangNode:create("eth_ethertype", nodeName, mandatory)
  setmetatable(new_inst, eth_ethertype_mt)
  return new_inst
end

function eth_ethertype:setValue(value)
  error("NOTIMPL: eth:ethertype not implemented yet")
end
_M.eth_ethertype = eth_ethertype

local inet_dscp = util.subClass("inet_dscp", YangNode)
inet_dscp_mt = { __index = inet_dscp }
function inet_dscp:create(nodeName, mandatory)
  local new_inst = YangNode:create("inet_dscp", nodeName, mandatory)
  setmetatable(new_inst, inet_dscp_mt)
  return new_inst
end

function inet_dscp:setValue(value)
  error("NOTIMPL: inet:dscp not implemented yet")
end
_M.inet_dscp = inet_dscp

local bits = util.subClass("bits", YangNode)
bits_mt = { __index = bits }
function bits:create(nodeName, mandatory)
  local new_inst = YangNode:create("bits", nodeName, mandatory)
  setmetatable(new_inst, bits_mt)
  return new_inst
end

function bits:setValue(value)
  error("NOTIMPL: bits not implemented yet")
end
_M.bits = bits

local string = util.subClass("string", YangNode)
string_mt = { __index = string }
function string:create(nodeName, mandatory)
  local new_inst = YangNode:create("string", nodeName, mandatory)
  setmetatable(new_inst, string_mt)
  return new_inst
end

function string:setValue(value)
  if type(value) == 'string' then
    self.value = value
  else
    error("type error: " .. self:getType() .. ".setValue() with type " .. type(value) .. " instead of string")
  end
end
_M.string = string

local notimplemented = util.subClass("notimplemented", YangNode)
notimplemented_mt = { __index = notimplemented }
function notimplemented:create(nodeName, mandatory)
  local new_inst = YangNode:create("notimplemented", nodeName, mandatory)
  setmetatable(new_inst, notimplemented_mt)
  return new_inst
end

function notimplemented:setValue(value)
  error("Not implemented")
end
_M.notimplemented = notimplemented

-- a container is the general-purpose holder of data that is not of any specific type
-- essentially, it's the 'main' holder of definitions and data
local container = util.subClass("container", _M.YangNode)
container_mt = { __index = container }
function container:create(nodeName, mandatory, unnamed)
  local new_inst = _M.YangNode:create("container", nodeName, mandatory)
  setmetatable(new_inst, container_mt)
  new_inst.yang_nodes = {}
  -- a container's value is contained in its yang nodes
  new_inst.value = nil
  new_inst.unnamed = unnamed
  return new_inst
end

function container:add_node(node_type_instance)
  if node_type_instance == nil then error("container:add_node() called with nil node_type_instance") end
  self.yang_nodes[node_type_instance:getName()] = node_type_instance
  node_type_instance:setParent(self)
end

function container:setParent(parent, recurse)
  self.parent = parent
  if recurse then
    for i,n in pairs(self.yang_nodes) do n:setParent(self, recurse) end
  end
end

function container:fromData_noerror(data)
  if type(data) ~= 'table' then
    return false
  end
  local any_match = false
  for node_name, node in pairs(self.yang_nodes) do
    if node:fromData_noerror(data[node_name]) then
      any_match = true
    end
  end
  return any_match
end

function container:clearData()
  for node_name, node in pairs(self.yang_nodes) do
    node:clearData()
  end
end

function container:hasValue()
  for i,node in pairs(self.yang_nodes) do
    if node:hasValue() then
      return true
    end
  end
  return false
end

function container:toData()
  local result = {}
  for name,node in pairs(self.yang_nodes) do
    local node_data = node:toData()
    --if node_data ~= nil and node:isa(_M.choice) then
    -- print("[XX] container child choice name '" .. name .. "' data: " .. json.encode(node_data))
    -- -- choice nodes don't show up in result data (case is already filtered out by choice
    -- for sname,sdata in pairs(node_data) do
    -- result[sname] = sdata
    -- end
    --else
    if node_data ~= nil then
      result[name] = node_data
    end
  end
  --print("[XX] TODATA RESULT: " .. json.encode(result))
  -- TODO: keep track instead of looking here? if still looking here,
  -- don't use json.encode
  if json.encode(result) == "{}" then return nil end
  return result
end

function container:getNodeNames()
  local result = {}
  for n,_ in pairs(self.yang_nodes) do
    table.insert(result, n)
  end
  return result
end

function container:getNode(path, given_list_index)
  -- get and remove the first section of the path
  local first, rest = util.str_split_one(path, "/")
  local list_name, list_index = get_path_list_index(first)
  if list_name ~= nil then
    first = list_name
  end

  local name_to_find, rest = util.str_split_one(path, "/")
  if name_to_find == nil then
    name_to_find = rest
    rest = nil
  end
  local list_index = nil
  local list_name, list_index = get_path_list_index(name_to_find)
  if list_name ~= nil then
    name_to_find = list_name
  end

  if self.yang_nodes[name_to_find] ~= nil then
    if given_list_index ~= nil then
      error("list index specified in path on non-list element " .. self:getType() .. " (" .. path .. ")")
    end
    if self.yang_nodes[name_to_find] == nil then error("node " .. name_to_find .. " not found in " .. self:getType()) end
    if rest == nil then
      return self.yang_nodes[name_to_find]
    else
      return self.yang_nodes[name_to_find]:getNode(rest, list_index)
    end
  end
  error("node " .. name_to_find .. " not found in " .. self:getType() .. " subnodes: [ " .. util.str_join(", ", self:getNodeNames()) .. " ]")
end

-- returns the child of the container. If there are more than one
-- returns the first one it finds
function container:getChild()
  for n,node in pairs(self.yang_nodes) do
    return node
  end
end

function container:getAll()
  local result = {}
  table.insert(result, self)
  for i,n in pairs(self.yang_nodes) do
    if n:hasValue() then
      util.table_extend(result, n:getAll())
    end
  end
  return result
end

function container:hasNode(node_name)
  return self.yang_nodes[node_name] ~= nil
end
_M.container = container

-- we implement lists by making them lists of containers, with
-- an interface that skips the container part (mostly)
local list = util.subClass("list", _M.YangNode)
list_mt = { __index = list }
function list:create(nodeName)
  local new_inst = _M.YangNode:create("list", nodeName)
  setmetatable(new_inst, list_mt)
  new_inst.entry_nodes = {}
  -- value is a table of entries, each of which should conform to
  -- the specification of entry_nodes
  new_inst.value = {}
  return new_inst
end

-- Add a node definition for the list entries
-- Note: this is NOT to add list elements, use create_list_element()
-- for that. This is to define what those elements should look like
function list:add_list_node(node_type_instance)
  self.entry_nodes[node_type_instance:getName()] = node_type_instance
  node_type_instance:setParent(self)
end

function list:setParent(parent, recurse)
  self.parent = parent
  if recurse then
    for i,n in pairs(self.entry_nodes) do n:setParent(self, recurse) end
    for i,n in pairs(self.value) do n:setParent(self, recurse) end
  end
end

-- Create a new entry in the list, based on the specification
-- of earlier add_list_node calls, without any value
-- the new entry is returned so the caller can add values
-- TODO: add optional data argument to immediately fill it?
function list:create_list_element()
  local new_node = _M.container:create('list_entry')
  -- TODO: should this be a deep copy?
  new_node.yang_nodes = util.deepcopy(self.entry_nodes)
  --new_node.value = nil
  table.insert(self.value, new_node)
  new_node:setParent(self, true)
  for i,n in pairs(new_node.yang_nodes) do
    n:setParent(new_node)
  end
  return new_node
end
-- TODO: should we error on attempts to use getValue and setValue?

-- Returns true if the list contains one or more elements
function list:hasValue()
  return table.getn(self.value) > 0
end

function list:fromData_noerror(data)
  local any_match = false
  for i,data_el in pairs(data) do
    local new_el = self:create_list_element()
    if new_el:fromData_noerror(data_el) then
      any_match = true
    end
  end
  --if any_match then
  --end
  return any_match
end

function list:clearData()
  self.value = {}
end

-- Returns the list elements as raw data
function list:toData()
  local result = {}
  local have_result = false
  for i,value in pairs(self.value) do
    have_result = true
    table.insert(result, value:toData())
  end
  if have_result then
    return result
  else
    return nil
  end
end

function list:getNode(path, given_list_index)
  if given_list_index ~= nil then
    if self.value[given_list_index] == nil then error("Element " .. given_list_index .. " not found in " .. self.getType()) end
    if path ~= nil then
      return self.value[given_list_index]:getNode(path)
    else
      return self.value[given_list_index]
    end
  else
    local list_name, list_index = get_path_list_index(path)
    if list_name == nil then
      error("getNode() on list must specify list index (" .. path .. ")")
    end
  end
end

-- Returns all the elements in the list (as container YangNodes)
function list:getAll()
  local result = {}
  table.insert(result, self)
  for i,n in pairs(self.value) do
    util.table_extend(result, n:getAll())
  end
  return result
end

function list:getPath(requester)
  --if requester ~= nil then
  --end
  local index_str = ""
  local parent_str = ""
  if self.parent ~= nil then
    parent_str = self.parent:getPath(self) .. "/"
  end
  if requester ~= nil then
    index_str = "[?]"
    for i,n in pairs(self.value) do
      if n == requester then
        index_str = "[" .. i .. "]"
      end
    end
  end
  return parent_str .. self:getName() .. index_str
end
_M.list = list

-- TODO: remove
function tablelength(T)
  local count = 0
  for _ in pairs(T) do count = count + 1 end
  return count
end

--
-- New Choice implementation
--

-- YANG allows the data model to segregate incompatible nodes into
-- distinct choices using the "choice" and "case" statements. The
-- "choice" statement contains a set of "case" statements that define
-- sets of schema nodes that cannot appear together. Each "case" may
-- contain multiple nodes, but each node may appear in only one "case"
-- under a "choice".

-- When an element from one case is created, all elements from all other
-- cases are implicitly deleted. The device handles the enforcement of
-- the constraint, preventing incompatibilities from existing in the
-- configuration.

-- The choice and case nodes appear only in the schema tree, not in the
-- data tree or NETCONF messages. The additional levels of hierarchy
-- are not needed beyond the conceptual schema.

local case = util.subClass("case", _M.container)
case_mt = { __index = case }

-- a case is simply a wrapper for a container; it can contain multiple child
-- nodes, or just one. The difference is that the container name will not show up in
-- the data
-- We use a separate type for safety
function case:create(nodeName)
  local new_inst = _M.container:create(nodeName, mandatory)
  new_inst.typeName = "case"
  setmetatable(new_inst, case_mt)
  return new_inst
end

function case:fromData_noerror(data)
  -- can we have multiple cases? do they all need to match? (yes)
  for name,node in pairs(self.yang_nodes) do
    if node:fromData_noerror(data) then return true end
  end
  return false
end

-- TODO: this only works for single cases
function case:toData()
  for name, node in pairs(self.yang_nodes) do
    return node:toData()
  end
end

function case:getCaseNode()
  for name, node in pairs(self.yang_nodes) do
    return node
  end
end

function case:clearData()
  for name, node in pairs(self.yang_nodes) do
    node:clearData()
  end
end
_M.case = case

local choice = util.subClass("choice", _M.YangNode)
choice_mt = { __index = choice }

function choice:create(nodeName, mandatory)
  local new_inst = _M.YangNode:create("choice", nodeName, mandatory)
  setmetatable(new_inst, choice_mt)
  new_inst.cases = {}
  self.active_case = nil
  return new_inst
end

-- todo: rename to add_case when done?
-- this function adds any given type as a case with the given name
function choice:add_case_container(case_name, case_node)
  -- wrap it in a case type with a fixed name?
  local case_instance = _M.case:create(case_name, false)
  case_instance:add_node(case_node)
  self.cases[case_name] = case_instance
  case_instance:setParent(self)
end

function choice:fromData_noerror(data)
  -- go through each case; if we find one, clear all the others
  -- should back up the active case here and put it back if nothing is found
  -- (or keep ref and unset if it is a different one than the new one)
  for casename, casenode in pairs(self.cases) do
    if casenode:fromData_noerror(data) then
      if self.active_case ~= nil and self.active_case ~= casenode then
        self.active_case:clearData()
      end
      self.active_case = casenode
      return true
    end
  end
  return false
end

function choice:hasValue()
  return self.active_case ~= nil
end

function choice:toData()
  if self.active_case ~= nil then
    return self.active_case:toData()
  end
  return nil
end

function choice:clearData()
  if self.active_case ~= nil then
    self.active_case:clearData()
  end
  self.active_case = nil
end

_M.choice = choice

return _M

