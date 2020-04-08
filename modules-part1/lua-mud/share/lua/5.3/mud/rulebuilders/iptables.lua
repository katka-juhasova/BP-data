local yang = require("mud.yang")

local json = require("json")

local _M = {}

local RuleBuilder = {}
local RuleBuilder_mt = { __index = RuleBuilder }

local function getAddresses(name, family)
  local result = {}
  local hostaddrs = socket.dns.getaddrinfo(name)
  if hostaddrs then
    for i,a in pairs(hostaddrs) do
      if family == nil or a.family == family then
        table.insert(result, a.addr)
      end
    end
  end
  return result
end

function getIPv6Addresses(name)
  return getAddresses(name, 'inet6')
end

function getIPv4Addresses(name)
  return getAddresses(name, 'inet')
end

-- returns true if a node was (or should have been) replaced; this
-- is so if the data contains a value for the dnsname_str in the
-- family_str, whether or not it actually resolves to an ip address
local function replaceDNSNameNode(new_nodes, node, family_str, dnsname_str, network_source_or_dest, network_source_or_dest_v)
  local nd = node:toData()
  if nd == nil then return false end
  if nd[family_str] and nd[family_str][dnsname_str] then
    local dnsname = nd[family_str][dnsname_str]
    local addrs = {}
    if family_str == 'ipv4' then
      addrs = getIPv4Addresses(dnsname)
    else
      addrs = getIPv6Addresses(dnsname)
    end
    if table.getn(addrs) == 0 then
      print("WARNING: " .. dnsname .. " does not resolve to any " .. family_str .. " addresses")
    end
    for i,a in pairs(addrs) do
      -- TODO: does this mess up older data?
      node:clearData()
      local nn = yang.util.deepcopy(node)

      nd[family_str][dnsname_str] = nil
      -- add new rule here ((TODO))
      --nd[family_str][network_source_or_dest] = {}
      if family_str == 'ipv6' then
        --nd[family_str][network_source_or_dest][network_source_or_dest_v] = a .. "/128"
        nd[family_str][network_source_or_dest_v] = a .. "/128"
      else
        nd[family_str][network_source_or_dest_v] = a .. "/32"
      end
      --nn:fromData_noerror(nd)
      nn:clearData()
      if not nn:fromData_noerror(nd) then
        error("error creating new node from data")
      end
      table.insert(new_nodes, nn)
    end
    return true
  end
  return false
end

local function ipMatchToRulePart(match_node, match)
  rulepart = ""

  if match_node:getName() == 'ietf-acldns:dst-dnsname' then
    rulepart = rulepart .. "daddr " .. match_node:toData() .. " "
  elseif match_node:getName() == 'ietf-acldns:src-dnsname' then
    rulepart = rulepart .. "saddr " .. match_node:toData() .. " "
  elseif match_node:getName() == 'protocol' then
    -- this is done by virtue of it being an ipv6 option
    if match_node:getValue() == 6 then
      rulepart = rulepart .. "-p tcp "
    elseif match_node:getValue() == 17 then
      rulepart = rulepart .. "-p udp "
    else
      error("Unsupport protocol value: " .. match_node:getValue())
    end
  elseif match_node:getName() == 'destination-port' then
    -- TODO: check operator and/or range
    rulepart = rulepart .. "--dport " .. match_node:getNode('port'):toData() .. " "
  elseif match_node:getName() == 'source-port' then
    -- TODO: check operator and/or range
    rulepart = rulepart .. "--sport " .. match_node:getNode('port'):toData() .. " "
  elseif match_node:getName() == 'destination-ipv4-network' or match_node:getName() == 'destination-ipv6-network' then
    -- TODO: check operator and/or range
    --error(json.encode(match_node:toData()))
    rulepart = rulepart .. "-d " .. match_node:toData() .. " "
  elseif match_node:getName() == 'source-ipv4-network' or match_node:getName() == 'source-ipv6-network' then
    -- TODO: check operator and/or range
    rulepart = rulepart .. "-s " .. match_node:toData() .. " "
  else
    error("NOTIMPL: unknown match type " .. match_node:getName() .. " in match rule " .. match:getName() )
  end

  return rulepart
end

function matchToRulePart(match_node, match)
  if match_node == nil then error("match_node is nil") end
  local rulepart = ""
  if match_node:hasValue() then
    if match_node:getName() == 'ietf-mud:direction-initiated' then
      -- TODO: does this have any influence on the actual rule?
      if match_node:toData() == 'from-device' then
        direction = "filter output "
      elseif match_node:toData() == 'to-device' then
        direction = "filter input "
      else
        error('unknown direction-initiated: ' .. match_node:toData())
      end
    elseif match_node:getName() == 'source-port' then
      -- TODO: check operator and/or range (i.e. other choice options)
      local case_node = match_node.active_case:getCaseNode()
      rulepart = rulepart .. "--sport " .. case_node:getNode('port'):getValue() .. " "
    elseif match_node:getName() == 'destination-port' then
      -- TODO: check operator and/or range
      local port_case = match_node.active_case:getCaseNode()
      -- TODO: chech which case it is, for now we assume operator->eq
      rulepart = rulepart .. "--dport " .. port_case:getNode("port"):getValue() .. " "
    else
      error("NOTIMPL: unknown match type " .. match_node:getName() .. " in match rule " .. match:getName() .. " type " .. match_node:getType())
    end
  end
  return rulepart
end

local function aceToRulesIPTables(ace_node)
  local nodes = ace_node:getAll()
  -- small trick, use getParent() so we can have a path request on the entire list
  local nodes = yang.findNodes(ace_node:getParent(), "ace[*]/matches")
  local paths = {}

  --
  -- pre-processing
  --

  -- IPTables does not support hostname-based rules, so in the case of
  -- a dnsname rule, we look up the address(es), and duplicate the rule
  -- for each (v4 or v6 depending on match type)
  local new_nodes = {}
  for i,n in pairs(nodes) do
    local nd = n:toData()
    table.insert(paths, n:getPath())
    -- need to make it into destination-ipv4-network, destination-ipv6-network,
    -- source-ipv4-network or source-ipv6-network, depending on what it was
    -- (ipv6/destination-dnsname, etc.)
    local node_replaced = false

    if replaceDNSNameNode(new_nodes, n, "ipv6", "ietf-acldns:src-dnsname", 'source-network', 'source-ipv6-network') then
      node_replaced = true
    end
    if replaceDNSNameNode(new_nodes, n, "ipv6", "ietf-acldns:dst-dnsname", 'destination-network', 'destination-ipv6-network') then
      node_replaced = true
    end
    if replaceDNSNameNode(new_nodes, n, "ipv4", "ietf-acldns:src-dnsname", 'source-network', 'source-ipv4-network') then
      node_replaced = true
    end
    if replaceDNSNameNode(new_nodes, n, "ipv4", "ietf-acldns:dst-dnsname", 'destination-network', 'destination-ipv4-network') then
      node_replaced = true
    end

    if not node_replaced then
      table.insert(new_nodes, n)
    end
  end

  --
  -- conversion to actual rules
  --
  local rules = {}

  for i,ace in pairs(new_nodes) do
    local rule = ""
    local chain = "-A FORWARD"
    local cmd = "iptables "
    local rulematches = ""

    for j,aceNode in pairs(ace.yang_nodes) do
      if aceNode:hasValue() then
        local choice = aceNode.active_case
        if choice:getName() == 'ipv4' then
          cmd = "iptables"
          for j,match_node in pairs(choice:getCaseNode().yang_nodes) do
            if match_node:hasValue() then
              rulematches = rulematches .. ipMatchToRulePart(match_node, ace_node)
            end
          end
        elseif choice:getName() == 'ipv6' then
          cmd = "ip6tables"
          for j,match_node in pairs(choice:getCaseNode().yang_nodes) do
            if match_node:hasValue() then
              rulematches = rulematches .. ipMatchToRulePart(match_node, ace_node)
            end
          end
        elseif choice:getName() == 'tcp' then
          for j,match_node in pairs(choice:getCaseNode().yang_nodes) do
            if match_node:hasValue() then
              rulematches = rulematches .. matchToRulePart(match_node, ace_node)
            end
          end
        elseif choice:getName() == 'udp' then
          for j,match_node in pairs(choice:getCaseNode().yang_nodes) do
            if match_node:hasValue() then
              rulematches = rulematches .. matchToRulePart(match_node, ace_node)
            end
          end
        else
          error("notimpl: " .. choice:getName())
        end
      end
    end

    local name = ace:getParent():getNode('name'):getValue()

    -- note: do we have the action type correctly defined?
    local action = "<undefined action>"
    local action_d = ace:getParent():getNode('actions'):getNode('forwarding'):getValue()
    if action_d == "accept" then
      action = "-j ACCEPT"
    end

    local rule = cmd .. " " .. chain .. " " .. rulematches .. action
    table.insert(rules, rule)
  end

  return rules
end

function _M.create_rulebuilder()
  local new_inst = {}
  new_inst.name = "iptables"
  setmetatable(new_inst, RuleBuilder_mt)
  return new_inst
end

function RuleBuilder:build_rules(mud, settings)
  local rules = {}
  -- find out which incoming and which outgoiing rules we have
  local from_device_acl_nodelist = mud.mud_container:getNode("ietf-mud:mud/from-device-policy/access-lists/access-list")
  -- maybe add something like findNodes("/foo/bar[*]/baz/*/name")?
  for i,node in pairs(from_device_acl_nodelist:getValue()) do
    local acl_name = node:getNode('name'):toData()
    -- find with some functionality is definitely needed in types
    -- but xpath is too complex. need to find right level.
    local found = false
    local acl = yang.findNodeWithProperty(mud.mud_container, "acl", "name", acl_name)
    yang.util.table_extend(rules, aceToRulesIPTables(acl:getNode('aces'):getNode('ace')))
  end

  local to_device_acl_nodelist = mud.mud_container:getNode("ietf-mud:mud/to-device-policy/access-lists/access-list")
  -- maybe add something like findNodes("/foo/bar[*]/baz/*/name")?
  for i,node in pairs(to_device_acl_nodelist:getValue()) do
    local acl_name = node:getNode('name'):toData()
    -- find with some functionality is definitely needed in types
    -- but xpath is too complex. need to find right level.
    local found = false
    local acl = yang.findNodeWithProperty(mud.mud_container, "acl", "name", acl_name)
    yang.util.table_extend(rules, aceToRulesIPTables(acl:getNode('aces'):getNode('ace')))
  end
  return rules
end

function _M:apply_rules()
  error("notimpl")
end

function _M:remove_rules()
  error("notimpl")
end

_M.RuleBuilder = RuleBuilder

return _M
