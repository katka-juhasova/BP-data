--
-- Created by IntelliJ IDEA.
-- User: mak
-- Date: 8/6/17
-- Time: 7:18 AM
-- Class: ${PACKAGE_NAME}
-- To change this template use File | Settings | File Templates.
--

local Relation = {
    type = 'Relation',
}

Relation.__index = Relation -- get indices from the table
Relation.__metatable = Relation -- protect the metatable

function Relation:get(domain_name)
    local methods = {}
    ------------------------------------------------------------------------
    --  Relation:getRelationList
    --  It returns the complete list of relations of the card specified for the specified domain.
    -- @param domain_name - Domain used for the relation. (string)
    -- @param classname - ClassName of the first card taking part in the relation (string)
    -- @param id - Identifier of the first card which takes part in the relation (number)
    -- @return {+RETURNS+}
    ------------------------------------------------------------------------
    methods.list = function(classname, id)
        local request = {}
        request.method = "getRelationList"
        request.entries = {
            { tag = "soap1:domain", domain_name },
            { tag = "soap1:className", classname },
            { tag = "soap1:cardId", id },
        }

        local resp = self:call(request)
        return xml.eval(resp):find 'ns2:return'
    end

    methods.attributes = function(classname, id)
        local request = {}
        request.method = "getRelationAttributes"
        request.entries = {
            { tag = "soap1:domain", domain_name },
            { tag = "soap1:className", classname },
            { tag = "soap1:cardId", id },
        }

        local resp = self:call(request)
        return xml.eval(resp)
    end

    methods.list_ext = function(classname, id)
        local request = {}
        request.method = "getRelationListExt"
        request.entries = {
            { tag = "soap1:domain", domain_name },
            { tag = "soap1:className", classname },
            { tag = "soap1:cardId", id },
        }

        local resp = self:call(request)
        return xml.eval(resp):find 'ns2:return'
    end

    ------------------------------------------------------------------------
    --  Relation:getRelationHistory
    --  It returns the relation history of a card starting from a "Relation" object
    -- in which only "Class1Name" and "Card1Id" were defined.
    -- @param domain_name - Domain used for the relation. (string)
    -- @param class1name - ClassName of the first card taking part in the relation (string)
    -- @param card1id - Identifier of the first card which takes part in the relation (number)
    -- @param class2name - ClassName of the second card which takes part in the relation. (string)
    -- @param card2id - Identifier of the second card which takes part in the relation. (number)
    -- @param status - Relation status ('A' = active, 'N' = removed) (string)
    -- @param begin_date - Date when the relation was created (format YYYY-MM-DDThh:mm:ssZ) (date)
    -- @param end_date - Date when the relation was created (format YYYY-MM-DDThh:mm:ssZ) (date)
    -- @return table
    ------------------------------------------------------------------------
    methods.history = function(class1name, card1id, class2name, card2id, status, begin_date, end_date)
        local request = {}
        request.method = "getRelationHistory"
        request.entries = {
            { tag = "soap1:domainName", domain_name },
            { tag = "soap1:class1name", class1name },
            { tag = "soap1:card1id", card1id },
            { tag = "soap1:class2name", class2name },
            { tag = "soap1:card2id", card2id },
            { tag = "soap1:status", status },
            { tag = "soap1:begindate", begin_date },
            { tag = "soap1:enddate", end_date },
        }

        local resp = self:call(request)
        return xml.eval(resp):find 'ns2:return'
    end
    return methods
end

------------------------------------------------------------------------
--  Relation:createRelation
--  It creates in the database a new relation between the pair of cards specified in the "Relation" object.
-- It returns “true” if the operation went through.
-- @param domain_name - Domain used for the relation. (string)
-- @param class1name - ClassName of the first card taking part in the relation (string)
-- @param card1Id - Identifier of the first card which takes part in the relation (number)
-- @param class2name - ClassName of the second card which takes part in the relation. (string)
-- @param card2Id - Identifier of the second card which takes part in the relation. (number)
-- @param status - Relation status ('A' = active, 'N' = removed) (string)
-- @param begin_date - Date when the relation was created (format YYYY-MM-DDThh:mm:ssZ) (date)
-- @param end_date - Date when the relation was created (format YYYY-MM-DDThh:mm:ssZ) (date)
-- @return boolean
------------------------------------------------------------------------
function Relation:create(domain_name, class1name, card1Id, class2name, card2Id, status, begin_date, end_date)
    local request = {}
    request.method = "createRelation"
    request.entries = {
        { tag = "soap1:domainName", domain_name },
        { tag = "soap1:class1Name", class1name },
        { tag = "soap1:card1Id", card1Id },
        { tag = "soap1:class2Name", class2name },
        { tag = "soap1:card2Id", card2Id },
        { tag = "soap1:status", status },
        { tag = "soap1:beginDate", begin_date },
        { tag = "soap1:endDate", end_date },
    }

    local resp = self:call(request)
    return xml.eval(resp):find 'ns2:return'
end

function Relation:create_with_attributes(domain_name, class1name, card1Id, class2name, card2Id, status, begin_date, end_date, attributes_list)
    local request = {}
    request.method = "createRelation"
    request.entries = {
        { tag = "soap1:domainName", domain_name },
        { tag = "soap1:class1Name", class1name },
        { tag = "soap1:card1Id", card1Id },
        { tag = "soap1:class2Name", class2name },
        { tag = "soap1:card2Id", card2Id },
        { tag = "soap1:status", status },
        { tag = "soap1:beginDate", begin_date },
        { tag = "soap1:endDate", end_date },
    }
    if attributes_list then
            local attributes = {}
            for k, v in pairs(attributes_list) do
                table.insert(attributes, {
                    tag = "soap1:attributeList",
                    { tag = "soap1:name", self.Utils.escape(tostring(k)) },
                    { tag = "soap1:value", self.Utils.escape(tostring(v)) },
                })
            end
            table.insert(request.entries, attributes)
        end

    local resp = self:call(request)
    return xml.eval(resp):find 'ns2:return'
end
------------------------------------------------------------------------
--  Relation:deleteRelation
--  It deletes the existing relation between the pair of cards specified in the "Relation" object.
-- It returns “true” if the operation went through.
-- @param domain_name - Domain used for the relation. (string)
-- @param class1name - ClassName of the first card taking part in the relation (string)
-- @param card1id - Identifier of the first card which takes part in the relation (number)
-- @param class2name - ClassName of the second card which takes part in the relation. (string)
-- @param card2id - Identifier of the second card which takes part in the relation. (number)
-- @param status - Relation status ('A' = active, 'N' = removed) (string)
-- @param begin_date - Date when the relation was created (format YYYY-MM-DDThh:mm:ssZ) (date)
-- @param end_date - Date when the relation was created (format YYYY-MM-DDThh:mm:ssZ) (date)
-- @return boolean
------------------------------------------------------------------------
function Relation:delete(domain_name, class1name, card1id, class2name, card2id, status, begin_date, end_date)
    local request = {}
    request.method = "deleteRelation"
    request.entries = {
        { tag = "soap1:domainName", domain_name },
        { tag = "soap1:class1name", class1name },
        { tag = "soap1:card1id", card1id },
        { tag = "soap1:class2name", class2name },
        { tag = "soap1:card2id", card2id },
        { tag = "soap1:status", status },
        { tag = "soap1:begindate", begin_date },
        { tag = "soap1:enddate", end_date },
    }

    local resp = self:call(request)
    return xml.eval(resp):find 'ns2:return'
end

return Relation
