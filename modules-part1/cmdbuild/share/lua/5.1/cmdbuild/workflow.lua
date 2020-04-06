--
-- Created by IntelliJ IDEA.
-- User: mak
-- Date: 8/6/17
-- Time: 6:57 AM
-- Class: ${PACKAGE_NAME}
-- To change this template use File | Settings | File Templates.
--
local Workflow = {
    type = 'Workflow',
}

Workflow.__index = Workflow -- get indices from the table
Workflow.__metatable = Workflow -- protect the metatable

------------------------------------------------------------------------
-- Workflow:start
-- It starts a new instance of the workflow described in the specified "Card".
-- If the “CompleteTask” parameter takes the “true” value, the process is advanced to the following step.
-- It returns the "id" identification attribute.
-- @param classname ClassName of the first card taking part in the relation (string)
-- @param attributes_list {+DESCRIPTION+} ({+TYPE+})
-- @param metadata {+DESCRIPTION+} ({+TYPE+})
-- @param complete_task {+DESCRIPTION+} (boolean)
-- @return id (number)
------------------------------------------------------------------------
function Workflow:start(classname, attributes_list, metadata, complete_task)
    local request = {}
    request.method = "startWorkflow"
    request.entries = {
        {
            tag = "soap1:card",
            { tag = "soap1:className", classname },
        }
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
        table.insert(request.entries[1], attributes)
    end

    if metadata then
        table.insert(request.entries, {
            tag = "soap1:metadata",
            {
                tag = "soap1:metadata",
                { tag = "soap1:key", metadata.key },
                { tag = "soap1:value", metadata.value }
            }
        })
    end

    local ctask = complete_task or true
    if complete_task then
        table.insert(request.entries, { tag = "soap1:competeTask", tostring(ctask) })
    end

    local resp = self:call(request)
    return xml.eval(resp):find 'ns2:return'
end

------------------------------------------------------------------------
-- Workflow:update
-- It updates the information of the card in the specified process instance.
-- If the “CompleteTask” parameter takes the “true” value, the process is advanced to the following step.
-- It returns “true” if the operation went through
-- @param process_id - {+DESCRIPTION+} ({+TYPE+})
-- @param attributes_list - Array of "Attribute" objects containing the values of additional custom attributes in the class.
-- They correspond to additional attributes defined in the Workflow Administration Module and available in the card management.
-- The list includes also the ClassId (not the className)(table) ex.: {name='',value=''}
-- @param complete_task - boolean
-- @return boolean
------------------------------------------------------------------------
function Workflow:update(process_id, attributes_list, complete_task)
    local request = {}
    request.method = "startWorkflow"
    request.entries = {
        {
            tag = "soap1:card",
            { tag = "soap1:processId", process_id }
        }
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
        table.insert(request.entries[1], attributes)
    end

    local ctask = complete_task or true
    if complete_task then
        table.insert(request.entries, { tag = "soap1:competeTask", tostring(ctask) })
    end

    local resp = self:call(request)
    return xml.eval(resp):find 'ns2:return'
end

function Workflow:resume(process_id, attributes_list, complete_task)
    local request = {}
    request.method = "resumeWorkflow"
    request.entries = {
        {
            tag = "soap1:card",
            { tag = "soap1:processId", process_id }
        }
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
        table.insert(request.entries[1], attributes)
    end

    local ctask = complete_task or true
    if complete_task then
        table.insert(request.entries, { tag = "soap1:competeTask", tostring(ctask) })
    end

    local resp = self:call(request)
    return xml.eval(resp):find 'ns2:return'
end

return Workflow
