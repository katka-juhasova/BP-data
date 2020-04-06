--
-- Created by IntelliJ IDEA.
-- User: mak
-- Date: 8/6/17
-- Time: 7:03 AM
-- Class: ${PACKAGE_NAME}
-- To change this template use File | Settings | File Templates.
--
-- Подключаем библиотеку для работы с base64, нужна для работы с аттачментами
local base64 = require'base64'

local Attachment = {
    type = 'Attachment',
}

Attachment.__index = Attachment -- get indices from the table
Attachment.__metatable = Attachment -- protect the metatable

------------------------------------------------------------------------
-- Attachment:upload
--  It uploads the specified file in the DMS Alfresco and the relating connection
-- to the Attachment card belonging to the “className” class and having the “id” identification.
-- It returns “true” if the operation went through.
-- @param classname - Class name which includes the card.  It corresponds to the table name in the database. (string)
-- @param card_id - {+DESCRIPTION+} (number)
-- @param file - {+DESCRIPTION+} (string)
-- @param filename - Attachment name with extension (string)
-- @param category - Category which the attachment belongs to (from proper Lookup list). (string)
-- @param description - Description related to the attachment (string)
-- @return result - boolean
------------------------------------------------------------------------
function Attachment:upload(classname, card_id, file, filename, category, description)
    local request = {}
    request.method = "uploadAttachment"
    request.entries = {
        { tag = "soap1:className", classname },
        { tag = "soap1:cardId", card_id },
        { tag = "soap1:fileName", filename },
        { tag = "soap1:category", category },
        { tag = "soap1:description", description },
    }

    if file then
        local i = io.open(file)
        table.insert(request.entries, { tag = "soap1:file", base64.encode(i.read '*a') })
        i:close()
    end

    -- todo: добавить открытие и конвертирование файла в base64
    local resp = self:call(request)
    return xml.eval(resp):find 'ns2:return'
end

------------------------------------------------------------------------
--  Attachment:download
--  It returns the file enclosed in the specified card, which has the specified name.
-- @param classname - Class name which includes the card.  It corresponds to the table name in the database. (string)
-- @param card_id - {+DESCRIPTION+} (number)
-- @param filename - {+DESCRIPTION+} ({+TYPE+})
-- @return base64 (string)
------------------------------------------------------------------------
function Attachment:download(classname, card_id, filename)
    local request = {}
    request.method = "downloadAttachment"
    request.entries = {
        { tag = "soap1:className", classname },
        { tag = "soap1:cardId", card_id },
        { tag = "soap1:fileName", filename },
    }

    local resp = self:call(request)
    return xml.eval(resp):find 'ns2:return'
end

------------------------------------------------------------------------
--  Attachment:delete
--  It removes from the DMS Alfresco the file enclosed in the specified card, which has the specified name.
-- It returns “true” if the operation went through.
-- @param classname - Class name which includes the card.  It corresponds to the table name in the database. (string)
-- @param card_id - {+DESCRIPTION+} (number)
-- @param filename - {+DESCRIPTION+} ({+TYPE+})
-- @return boolean
------------------------------------------------------------------------
function Attachment:delete(classname, card_id, filename)
    local request = {}
    request.method = "deleteAttachment"
    request.entries = {
        { tag = "soap1:className", classname },
        { tag = "soap1:cardId", card_id },
        { tag = "soap1:fileName", filename },
    }

    local resp = self:call(request)
    return xml.eval(resp):find 'ns2:return'
end

------------------------------------------------------------------------
--  Attachment:update
--  It updates the description of the file enclosed in the specified card, which has the specified name.
-- It returns “true” if the operation went through.
-- @param classname - Class name which includes the card.  It corresponds to the table name in the database. (string)
-- @param card_id - {+DESCRIPTION+} (number)
-- @param filename - {+DESCRIPTION+} ({+TYPE+})
-- @param description - {+DESCRIPTION+} ({+TYPE+})
-- @return boolean
------------------------------------------------------------------------
function Attachment:update(classname, card_id, filename, description)
    local request = {}
    request.method = "updateAttachment"
    request.entries = {
        { tag = "soap1:className", classname },
        { tag = "soap1:cardId", card_id },
        { tag = "soap1:fileName", filename },
        { tag = "soap1:description", description },
    }

    local resp = self:call(request)
    return xml.eval(resp):find 'ns2:return'
end

return Attachment
