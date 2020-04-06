--
-- Created by IntelliJ IDEA.
-- User: mak
-- Date: 8/6/17
-- Time: 6:58 AM
-- Class: ${PACKAGE_NAME}
-- To change this template use File | Settings | File Templates.
--
local Lookup = {
    type = 'Lookup',
}

Lookup.__index = Lookup -- get indices from the table
Lookup.__metatable = Lookup -- protect the metatable

------------------------------------------------------------------------
-- List methods: list, by_id, translation_by_id
--@usage cmdbuild.Lookup:get().list(your_args)
------------------------------------------------------------------------
function Lookup:get(lookup_type)
    ------------------------------------------------------------------------
    --@table methods
    --@field list
    -- It returns a complete list of Lookup values corresponding to the specified "type".
    -- If the "value" parameter is specified, only the related heading is returned.
    -- If “parentList” takes the “True” value, it returns the complete hierarchy available for the multilevel Lookup lists.
    --@field by_id
    --  It returns the Lookup heading which shows the specified "Id" identification
    --@field translate_by_id
    --  Only model from DBIC
    local methods = {}
    ------------------------------------------------------------------------
    -- It returns a complete list of Lookup values corresponding to the specified "type".
    -- If the "value" parameter is specified, only the related heading is returned.
    -- If “parentList” takes the “True” value, it returns the complete hierarchy available for the multilevel Lookup lists.
    -- @param lookup_type - Name of the Lookup list which includes the current heading(string)
    -- @param value - {+DESCRIPTION+} ({+TYPE+})
    -- @param need_parent_list - {+DESCRIPTION+} ({+TYPE+})
    -- @return {+RETURNS+}
    ------------------------------------------------------------------------
    methods.list = function(value, need_parent_list)
        local request = {}
        request.method = "getLookupList"
        request.entries = {
            { tag = "soap1:type", lookup_type },
        }

        if value then
            table.insert(request.entries, { tag = "soap1:value", value })
        end

        if need_parent_list then
            table.insert(request.entries, { tag = "soap1:parentList", true })
        end

        local resp = self:call(request)
        return xml.eval(resp):find 'ns2:return'
    end

    methods.list_by_code = function(code, need_parent_list)
        local request = {}
        request.method = "getLookupListByCode"
        request.entries = {
            { tag = "soap1:type", lookup_type },
        }

        if code then
            table.insert(request.entries, { tag = "soap1:code", code })
        end

        if need_parent_list then
            table.insert(request.entries, { tag = "soap1:parentList", true })
        end

        local resp = self:call(request)
        return xml.eval(resp):find 'ns2:return'
    end

    ------------------------------------------------------------------------
    --  It returns the Lookup heading which shows the specified "Id" identification
    -- @param lookup_id - {+DESCRIPTION+} ({+TYPE+})
    -- @return {+RETURNS+}
    ------------------------------------------------------------------------
    methods.by_id = function(lookup_id)
        local request = {}
        request.method = "getLookupById"
        request.entries = {
            { tag = "soap1:id", lookup_id },
        }

        local resp = self:call(request)
        return xml.eval(resp):find 'ns2:return'
    end

    ------------------------------------------------------------------------
    --  Only model from DBIC
    -- @param lookup_id - {+DESCRIPTION+} ({+TYPE+})
    -- @return {+RETURNS+}
    ------------------------------------------------------------------------
    methods.translation_by_id = function(lookup_id)
        local request = {}
        request.method = "callFunction"
        request.entries = {
            { tag = "soap1:functionName", "dbic_get_lookup_trans_by_id" },
            {
                tag = "soap1:params",
                { tag = "soap1:name", "itid" },
                { tag = "soap1:value", lookup_id }
            }
        }

        local resp = self:call(request)
        return xml.eval(resp):find 'ns2:return'
    end

    return methods
end

------------------------------------------------------------------------
--  Lookup:create
--  It creates in the database a new heading of a data Lookup list
-- containing information inserted in the “Lookup” object.
-- It returns the "id" identification attribute.
-- @param lookup_type - Name of the Lookup list which includes the current heading (string)
-- @param code - Code of the Lookup heading (one single heading of a Lookup list).(string)
-- @param description - Description of the Lookup heading (one single heading of a Lookup list) (string)
-- @param id - Lookup identification, it is automatically assigned by the database (number)
-- @param notes - Notes connected with the Lookup heading (string)
-- @param parent_id - Identification of the parent Lookup in the current heading (if applicable) (number)
-- @param position - Location of the Lookup heading in the related Lookup list (number)
-- @return id (integer)
------------------------------------------------------------------------
function Lookup:create(lookup_type, code, description, id, notes, parent_id, position)
    local request = {}
    request.method = "createLookup"
    request.entries = {
        {
            tag = "soap1:lookup",
            { tag = "soap1:code", code },
            { tag = "soap1:description", description }
        }
    }

    if id then
        table.insert(request.entries[1], { tag = "soap1:id", id })
    end

    if notes then
        table.insert(request.entries[1], { tag = "soap1:notes", notes })
    end

    if parent_id and position then
        table.insert(request.entries[1], { tag = "soap1:parent" })
        table.insert(request.entries[1], { tag = "soap1:parentId", parent_id })
        table.insert(request.entries[1], { tag = "soap1:position", position })
    end
    table.insert(request.entries[1], { tag = "soap1:type", lookup_type })

    local resp = self:call(request)
    return xml.eval(resp):find 'ns2:return'
end

------------------------------------------------------------------------
--  Lookup:delete
--  It deletes logically - in the identified class -
-- the pre-existing card with the identified "id".
-- It returns “true” if the operation went through.
-- @param lookup_id - {+DESCRIPTION+} (number)
-- @return boolean
------------------------------------------------------------------------
function Lookup:delete(lookup_id)
    local request = {}
    request.method = "deleteLookup"
    request.entries = {
        {
            tag = "soap1:lookup",
            { tag = "soap1:lookupId", lookup_id },
        }
    }

    local resp = self:call(request)
    return xml.eval(resp):find 'ns2:return'
end

------------------------------------------------------------------------
--  Lookup:update - table
--  It updates the pre-existing Lookup heading.  It returns “true” if the operation went through.
-- @param lookup_type - Name of the Lookup list which includes the current heading (string)
-- @param code - Code of the Lookup heading (one single heading of a Lookup list).(string)
-- @param description - Description of the Lookup heading (one single heading of a Lookup list).(string)
-- @param id - Lookup identification, it is automatically assigned by the database (number)
-- @param notes - Notes connected with the Lookup heading (string)
-- @param parent_id - Identification of the parent Lookup in the current heading (if applicable) (number)
-- @param position - Location of the Lookup heading in the related Lookup list (number)
-- @return id (integer)
-- @return {+RETURNS+}
------------------------------------------------------------------------
function Lookup:update(lookup_type, code, description, id, notes, parent_id, position)
    local request = {}
    request.method = "updateLookup"
    request.entries = {
        {
            tag = "soap1:lookup",
            { tag = "soap1:code", code },
            { tag = "soap1:description", description }
        }
    }

    if id then
        table.insert(request.entries[1], { tag = "soap1:id", id })
    end

    if notes then
        table.insert(request.entries[1], { tag = "soap1:notes", notes })
    end

    if parent_id and position then
        table.insert(request.entries[1], { tag = "soap1:parent" })
        table.insert(request.entries[1], { tag = "soap1:parentId", parent_id })
        table.insert(request.entries[1], { tag = "soap1:position", position })
    end
    table.insert(request.entries[1], { tag = "soap1:type", lookup_type })

    local resp = self:call(request)
    return xml.eval(resp):find 'ns2:return'
end


return Lookup
