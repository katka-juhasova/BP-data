local util = require("mud.yang.util")
local basic_types = require("mud.yang.basic_types")

-- Types based on other types
--
-- Note: the complex_types subclass is provisionary; we should probably have namespaced
-- complex types, possibly directly derived from yang files
--
-- For now, we are still in the process of discovery regarding the best way to interface this
-- in Lua, so we hard-define the types we need.

local _M = {}

-- TODO
local acl_type = util.subClass("acl_type", basic_types.YangNode)
acl_type_mt = { __index = acl_type }
function acl_type:create(nodeName, mandatory)
  local new_inst = basic_types.YangNode:create("acl-type", nodeName, mandatory)
  setmetatable(new_inst, acl_type_mt)
  return new_inst
end

function acl_type:setValue(value)
  if type(value) == 'string' then
    -- TODO: rest of types. do we need to keep enumeration lists centrally?
    if value == "ipv4-acl-type" or
    value == "ipv6-acl-type" then
      self.value = value
    else
      error("type error: " .. self:getType() .. ".setValue() with unknown acl type: '" .. value .. "'")
    end
  else
    error("type error: " .. self:getType() .. ".setValue() with type " .. type(value) .. " instead of string")
  end
end
_M.acl_type = acl_type

function splitfoo(value)
  return
end

-- based on https://tools.ietf.org/html/rfc6021
local inet_ipv4_prefix = util.subClass("inet:ipv4-prefix", basic_types.string)
inet_ipv4_prefix_mt = { __index = inet_ipv4_prefix }
function inet_ipv4_prefix:create(nodeName, mandatory)
  local new_inst = basic_types.YangNode:create("inet:ipv4-prefix", nodeName, mandatory)
  setmetatable(new_inst, inet_ipv4_prefix_mt)
  return new_inst
end

function inet_ipv4_prefix:setValue(value)
  if type(value) == 'string' then
    local m = {}
    m = {string.match(value, "^([0-9]+).([0-9]+).([0-9]+).([0-9]+)/([0-9]+)$")}
    if #m ~= 5 then
      error("value for " .. self:getType() .. ".setValue() is not a valid IPv4 prefix: " .. #m)
    end
    for i,n in pairs(m) do
      v = tonumber(n)
      if i < 5 then
        if v == nil or v < 0 or v > 255 then error("IPv4 value out of range: " .. value) end
      else
        if v == nil or v < 0 or v > 32 then error("IPv4 bitmask out of range: " .. value) end
      end
    end
    self.value = value
  else
    error("type error: " .. self:getType() .. ".setValue() with type " .. type(value) .. " instead of string")
  end
end
_M.inet_ipv4_prefix = inet_ipv4_prefix

local inet_ipv6_prefix = util.subClass("inet:ipv6-prefix", basic_types.string)
inet_ipv6_prefix_mt = { __index = inet_ipv6_prefix }
function inet_ipv6_prefix:create(nodeName, mandatory)
  local new_inst = basic_types.YangNode:create("inet:ipv6-prefix", nodeName, mandatory)
  setmetatable(new_inst, inet_ipv6_prefix_mt)
  return new_inst
end

function inet_ipv6_prefix:setValue(value)
  if type(value) == 'string' then
    -- IPv6 addresses are too complex for a basic matcher, and we don't want to pull in a full RE parser.
    -- So we use a bit of custom code

    -- split up in address and bitmast
    local parts = util.str_split(value, "/")
    if #parts ~= 2 then
      error("value for " .. self:getType() .. ".setValue() is not a valid ipv6 prefix (no bitmask part): " .. value)
    else
      if tonumber(parts[2]) == nil then
        error("value for " .. self:getType() .. ".setValue() is not a valid ipv6 prefix (bitmask not a number): " .. value)
      end
      if tonumber(parts[2]) < 0 or tonumber(parts[2]) > 128 then
        error("value for " .. self:getType() .. ".setValue() is not a valid ipv6 prefix (bitmask out of range): " .. value)
      end
      local addr_parts = util.str_split(parts[1], ":")
      if #addr_parts > 8 then
        error("value for " .. self:getType() .. ".setValue() is not a valid ipv6 prefix (IP address has too many parts): " .. value)
      end
      local double_count = table.getn(util.str_split(parts[1], "::")) - 1
      for i,n in pairs(addr_parts) do
        if #n > 4 then error("too large") end
        if not n:match("^[a-fA-F0-9]*$") then error("non-hex") end
      end
      if double_count > 1 then
        error("value for " .. self:getType() .. ".setValue() is not a valid ipv6 prefix (two or more ::): " .. value)
      end
      if #addr_parts < 8 and double_count == 0 then
        error("value for " .. self:getType() .. ".setValue() is not a valid ipv6 prefix (IP address has too few parts): " .. value)
      end
    end
    self.value = value
  else
    error("type error: " .. self:getType() .. ".setValue() with type " .. type(value) .. " instead of string")
  end
end
_M.inet_ipv6_prefix = inet_ipv6_prefix

-- ietf-access-control-list is a specialized type; the base of it is a container
local ietf_access_control_list = util.subClass("ietf_access_control_list", basic_types.container)
ietf_access_control_list_mt = { __index = ietf_access_control_list }
function ietf_access_control_list:create(nodeName, mandatory)
  local new_inst = basic_types.container:create(nodeName, mandatory)
  -- additional step: add the type name
  new_inst.typeName = "acl"
  setmetatable(new_inst, ietf_access_control_list_mt)
  new_inst:add_definition()
  return new_inst
end

function ietf_access_control_list:add_definition()
  local acl_list = basic_types.list:create('acl')
  acl_list:add_list_node(basic_types.string:create('name', true))
  acl_list:add_list_node(acl_type:create('type', false))

  local aces = basic_types.container:create('aces')
  local ace_list = basic_types.list:create('ace')
  ace_list:add_list_node(basic_types.string:create('name'))
  --local matches = basic_types.choice:create('matches')
  local matches = basic_types.container:create('matches')

  local matches_eth = basic_types.container:create('eth')
  matches_eth:add_node(basic_types.mac_address:create('destination-mac-address'))
  matches_eth:add_node(basic_types.mac_address:create('destination-mac-address-mask'))
  matches_eth:add_node(basic_types.mac_address:create('source-mac-address'))
  matches_eth:add_node(basic_types.mac_address:create('source-mac-address-mask'))
  matches_eth:add_node(basic_types.eth_ethertype:create('ethertype'))

  local matches_ipv4 = basic_types.container:create('ipv4')
  matches_ipv4:add_node(basic_types.inet_dscp:create('dscp', false))
  matches_ipv4:add_node(basic_types.uint8:create('ecn', false))
  matches_ipv4:add_node(basic_types.uint16:create('length', false))
  matches_ipv4:add_node(basic_types.uint8:create('ttl', false))
  matches_ipv4:add_node(basic_types.uint8:create('protocol', false))
  matches_ipv4:add_node(basic_types.uint8:create('ihl', false))
  matches_ipv4:add_node(basic_types.bits:create('flags', false))
  matches_ipv4:add_node(basic_types.uint16:create('offset', false))
  matches_ipv4:add_node(basic_types.uint16:create('identification', false))
  -- TODO: -network
  local ipv4_destination_network_choice = basic_types.choice:create('destination-ipv4-network', false, true)
  ipv4_destination_network_choice:add_case_container('destination-ipv4-network', inet_ipv4_prefix:create('destination-ipv4-network', false))
  matches_ipv4:add_node(ipv4_destination_network_choice, false)

  local ipv4_source_network_choice = basic_types.choice:create('source-ipv4-network', false, true)
  ipv4_source_network_choice:add_case_container('source-ipv4-network', inet_ipv4_prefix:create('source-ipv4-network', false))
  matches_ipv4:add_node(ipv4_source_network_choice, false)

  -- mud augmentation
  matches_ipv4:add_node(basic_types.string:create('ietf-acldns:dst-dnsname', false))
  matches_ipv4:add_node(basic_types.string:create('ietf-acldns:src-dnsname', false))

  local matches_ipv6 = basic_types.container:create('ipv6')
  matches_ipv6:add_node(basic_types.inet_dscp:create('dscp', false))
  matches_ipv6:add_node(basic_types.uint8:create('ecn', false))
  matches_ipv6:add_node(basic_types.uint16:create('length', false))
  matches_ipv6:add_node(basic_types.uint8:create('ttl', false))
  matches_ipv6:add_node(basic_types.uint8:create('protocol', false))
  matches_ipv6:add_node(basic_types.string:create('ietf-acldns:dst-dnsname', false))
  matches_ipv6:add_node(basic_types.string:create('ietf-acldns:src-dnsname', false))

  local ipv6_destination_network_choice = basic_types.choice:create('destination-ipv6-network', false)
  ipv6_destination_network_choice:add_case_container('destination-ipv6-network', inet_ipv6_prefix:create('destination-ipv6-network', false))
  matches_ipv6:add_node(ipv6_destination_network_choice)

  local ipv6_source_network_choice = basic_types.choice:create('source-ipv6-network', false, true)
  ipv6_source_network_choice:add_case_container('source-ipv6-network', inet_ipv6_prefix:create('source-ipv6-network', false))
  matches_ipv6:add_node(ipv6_source_network_choice)
  -- TODO: flow-label

  local matches_tcp = basic_types.container:create('tcp')
  matches_tcp:add_node(basic_types.uint32:create('sequence-number', false))
  matches_tcp:add_node(basic_types.uint32:create('acknowledgement-number', false))
  matches_tcp:add_node(basic_types.uint8:create('offset', false))
  matches_tcp:add_node(basic_types.uint8:create('reserved', false))

  -- new choice realization
  -- todo: is this mandatory?
  -- todo: can we refactor this into a type?
  local source_port = basic_types.container:create('source-port', false)
  local source_port_choice = basic_types.choice:create('source-port', false, true)

  local source_port_range = basic_types.container:create('port-range', false)
  source_port_range:add_node(basic_types.uint16:create('lower-port'))
  source_port_range:add_node(basic_types.uint16:create('upper-port'))
  source_port_choice:add_case_container('range', source_port_range)

  local source_port_operator = basic_types.container:create('port-operator', false, true)
  source_port_operator:add_node(basic_types.string:create('operator', false))
  source_port_operator:add_node(basic_types.uint16:create('port'))
  source_port_choice:add_case_container('operator', source_port_operator)

  --source_port:add_node(source_port_choice)
  matches_tcp:add_node(source_port_choice)

  local destination_port = basic_types.container:create('destination-port', false)
  local destination_port_choice = basic_types.choice:create('destination-port', false, true)

  local destination_port_range = basic_types.container:create('port-range', false)
  destination_port_range:add_node(basic_types.uint16:create('lower-port'))
  destination_port_range:add_node(basic_types.uint16:create('upper-port'))
  destination_port_choice:add_case_container('range', destination_port_range)

  local destination_port_operator = basic_types.container:create('port-operator', false, true)
  destination_port_operator:add_node(basic_types.string:create('operator', true))
  destination_port_operator:add_node(basic_types.uint16:create('port'), true)
  destination_port_choice:add_case_container('operator', destination_port_operator)

  --destination_port:add_node(destination_port_choice)
  matches_tcp:add_node(destination_port_choice)

  -- this is an augmentation from draft-mud
  -- TODO: type 'direction' (enum?)
  matches_tcp:add_node(basic_types.string:create('ietf-mud:direction-initiated', false))

  local matches_udp = basic_types.container:create('udp')
  matches_udp:add_node(basic_types.uint16:create('length', false))
  matches_udp:add_node(util.deepcopy(source_port_choice))
  matches_udp:add_node(util.deepcopy(destination_port_choice))

  -- TODO: once we refactor the one for tcp, we should be able to replace this as well
  local udp_source_port = basic_types.container:create('source-port', false)
  local udp_source_port_choice = basic_types.choice:create('source-port', false, true)

  local udp_source_port_range = basic_types.container:create('port-range', false)
  udp_source_port_range:add_node(basic_types.uint16:create('lower-port'))
  udp_source_port_range:add_node(basic_types.uint16:create('upper-port'))
  udp_source_port_choice:add_case_container('range', udp_source_port_range)

  local udp_source_port_operator = basic_types.container:create('port-operator', false, true)
  udp_source_port_operator:add_node(basic_types.string:create('operator'))
  udp_source_port_operator:add_node(basic_types.uint16:create('port'))
  udp_source_port_choice:add_case_container('operator', udp_source_port_operator)

  --udp_source_port:add_node(udp_source_port_choice)
  matches_udp:add_node(udp_source_port_choice)

  local udp_destination_port = basic_types.container:create('destination-port', false, true)
  local udp_destination_port_choice = basic_types.choice:create('destination-port', false, true)

  local udp_destination_port_range = basic_types.container:create('port-range', false)
  udp_destination_port_range:add_node(basic_types.uint16:create('lower-port'))
  udp_destination_port_range:add_node(basic_types.uint16:create('upper-port'))
  udp_destination_port_choice:add_case_container('range', udp_destination_port_range)

  local udp_destination_port_operator = basic_types.container:create('port-operator', false, true)
  udp_destination_port_operator:add_node(basic_types.string:create('operator', false))
  udp_destination_port_operator:add_node(basic_types.uint16:create('port'))
  udp_destination_port_choice:add_case_container('operator', udp_destination_port_operator)

  --udp_destination_port:add_node(udp_destination_port_choice)
  matches_udp:add_node(udp_destination_port_choice)

  local matches_l1_choice = basic_types.choice:create('eth', false)
  local matches_l2_choice = basic_types.choice:create('ipv4', false)
  local matches_l3_choice = basic_types.choice:create('tcp', false)
  local matches_l4_choice = basic_types.choice:create('udp', false)
  local matches_l5_choice = basic_types.choice:create('ipv6', false)

  matches_l1_choice:add_case_container('eth', matches_eth)
  matches_l2_choice:add_case_container('ipv4', matches_ipv4)
  matches_l3_choice:add_case_container('tcp', matches_tcp)
  matches_l4_choice:add_case_container('udp', matches_udp)
  matches_l5_choice:add_case_container('ipv6', matches_ipv6)

  matches:add_node(matches_l1_choice)
  matches:add_node(matches_l2_choice)
  matches:add_node(matches_l3_choice)
  matches:add_node(matches_l4_choice)
  matches:add_node(matches_l5_choice)

  ace_list:add_list_node(matches)
  aces:add_node(ace_list)

  local actions = basic_types.container:create('actions')
  -- todo identityref
  actions:add_node(basic_types.string:create('forwarding'))
  actions:add_node(basic_types.string:create('logging', false))

  ace_list:add_list_node(actions)
  acl_list:add_list_node(aces)

  -- report: discrepancy between example and definition? (or maybe just tree)
  -- TODO: look up what to do with singular/plural, maybe that is stated somewhere
  self:add_node(acl_list)
end
_M.ietf_access_control_list = ietf_access_control_list
-- class ietf_access_control_list

return _M

