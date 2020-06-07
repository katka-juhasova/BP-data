local yang = require("mud.yang")

--
-- currently, we assume the following initialization
-- # nft flush ruleset
--
-- Add a table:
--
-- # nft add table inet filter
--
-- Add the input, forward, and output base chains. The policy for input and forward will be to drop. The policy for output will be to accept.
--
-- # nft add chain inet filter input { type filter hook input priority 0 \; policy drop \; }
-- # nft add chain inet filter forward { type filter hook forward priority 0 \; policy drop \; }
-- # nft add chain inet filter output { type filter hook output priority 0 \; policy accept \; }
--
-- Add two regular chains that will be associated with tcp and udp:
--
-- # nft add chain inet filter TCP
-- # nft add chain inet filter UDP
--
-- Related and established traffic will be accepted:
--
-- # nft add rule inet filter input ct state related,established accept
--

--
-- Helper functions
--

local function ipMatchToRulePart(match_node)
  rulepart = ""

  if match_node:getName() == 'ietf-acldns:dst-dnsname' then
    rulepart = rulepart .. "daddr " .. match_node:toData() .. " "
  elseif match_node:getName() == 'ietf-acldns:src-dnsname' then
    rulepart = rulepart .. "saddr " .. match_node:toData() .. " "
  elseif match_node:getName() == 'protocol' then
    -- this is done by virtue of it being an ipv6 option
  elseif match_node:getName() == 'destination-port' then
    -- TODO: check operator and/or range
    rulepart = rulepart .. "dport " .. match_node:getActiveCase():getNode('port'):getValue() .. " "
  else
    error("NOTIMPL: unknown match type " .. match_node:getName() .. " in match rule " .. match:getName() )
  end

  return rulepart
end

local function aceToRules(ace_node)
  local rules = {}
  for i,ace in pairs(ace_node:getValue()) do
    local rulestart = "nft add rule inet "
    local v6_or_v4 = nil
    local direction = nil
    local rulematches = ""
    for i,match_choice in pairs(ace:getNode('matches').yang_nodes) do
      if match_choice.active_case ~= nil then
        local match = match_choice.active_case:getCaseNode()
        if match ~= nil then
          if match:getName() == 'ipv4' then
            v6_or_v4 = "ip "
            for j,match_node in pairs(match.yang_nodes) do
              if match_node:hasValue() then
                rulematches = rulematches .. ipMatchToRulePart(match_node)
              end
            end
          elseif match:getName() == 'ipv6' then
            v6_or_v4 = "ip6 "
            for j,match_node in pairs(match.yang_nodes) do
              if match_node:hasValue() then
                rulematches = rulematches .. ipMatchToRulePart(match_node)
              end
            end
            -- TODO
            -- TODO
          elseif match:getName() == 'tcp' then
            rulematches = rulematches .. "tcp "
            for j,match_node in pairs(match.yang_nodes) do
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
                  -- TODO: check operator and/or range
                  rulematches = rulematches .. "sport " .. match_node.active_case:getCaseNode():getNode('port'):getValue() .. " "
                elseif match_node:getName() == 'destination-port' then
                  -- TODO: check operator and/or range

                  local port_case = match_node.active_case:getCaseNode()
                  -- TODO: chech which case it is, for now we assume operator->eq

                  rulematches = rulematches .. "dport " .. port_case:getNode("port"):getValue() .. " "
                else
                  error("NOTIMPL: unknown match type " .. match_node:getName() .. " in match rule " .. match:getName() .. " type: " .. match:getType() )
                end
              end
            end
          else
            error('unknown match type: ' .. match:getName() .. " type: " ..match:getType())
          end
        end
      end
    end

    local rule_action = ace:getNode("actions/forwarding"):getValue()
    if v6_or_v4 == nil then
      error('currently, we need either an ipv4 or ipv6 rule')
    end
    if direction == nil then
      -- TODO: how to determine chain/
      direction = "forward "
    end
    rule = rulestart .. direction .. v6_or_v4 .. rulematches .. rule_action
    table.insert(rules, rule)
  end
  return rules
end

local function makeRules(mud)
  -- first do checks, etc.
  -- TODO ;)

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
    yang.util.table_extend(rules, aceToRules(acl:getNode('aces'):getNode('ace')))
  end

  local to_device_acl_nodelist = mud.mud_container:getNode("ietf-mud:mud/to-device-policy/access-lists/access-list")
  -- maybe add something like findNodes("/foo/bar[*]/baz/*/name")?
  for i,node in pairs(to_device_acl_nodelist:getValue()) do
    local acl_name = node:getNode('name'):toData()
    -- find with some functionality is definitely needed in types
    -- but xpath is too complex. need to find right level.
    local found = false
    local acl = yang.findNodeWithProperty(mud.mud_container, "acl", "name", acl_name)
    yang.util.table_extend(rules, aceToRules(acl:getNode('aces'):getNode('ace')))
  end
  return rules
end

--
-- The rulebuilder object
--
local _M = {}

local RuleBuilder = {}
local RuleBuilder_mt = { __index = RuleBuilder }

function _M.create_rulebuilder()
  local new_inst = {}
  new_inst.name = "iptables"
  setmetatable(new_inst, RuleBuilder_mt)
  return new_inst
end

function RuleBuilder:build_rules(mud, settings)
  return makeRules(mud)
end

function _M:apply_rules()
  error("notimpl")
end

function _M:remove_rules()
  error("notimpl")
end

_M.RuleBuilder = RuleBuilder

return _M
