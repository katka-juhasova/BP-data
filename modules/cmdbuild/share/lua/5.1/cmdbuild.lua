--- vim: ts=2 tabstop=2 shiftwidth=2 expandtab

-- @todo: как только явится Света, дописать handler в соответствии со спекой CMDBuild
-- @todo: ВАЖНО! дописать описание методов и аргументов, пф, осталось чутка, а потом проверять и по новой до усеру
--

--------------------------------------------------------------------------------
require 'luarocks.loader'
require 'LuaXML'
--------------------------------------------------------------------------------

local errors = {
    ['NOTFOUND_ERROR'] = 'Element not found',
    ['AUTH_MULTIPLE_GROUPS'] = 'The user is connected with multiple groups',
    ['AUTH_UNKNOWN_GROUP'] = 'Unknown group',
    ['AUTH_NOT_AUTHORIZED'] = 'The authorizations are not enough to perform the operation',
    ['ORM_GENERIC_ERROR'] = 'An error has occurred while reading/saving data',
    ['ORM_DUPLICATE_TABLE'] = 'There is already a class with this name',
    ['ORM_CAST_ERROR'] = 'Error in the type conversion',
    ['ORM_UNIQUE_VIOLATION'] = 'Not null constraint violated',
    ['ORM_CONTAINS_DATA'] = 'You can\'t delete classes or attributes of tables or domains containing data',
    ['ORM_TYPE_ERROR'] = 'Not corresponding type',
    ['ORM_ERROR_GETTING_PK'] = 'The main key can\'t be determined',
    ['ORM_ERROR_LOOKUP_CREATION'] = 'The lookup can\'t be created',
    ['ORM_ERROR_LOOKUP_MODIFY'] = 'The lookup can\'t be modified',
    ['ORM_ERROR_LOOKUP_DELETE'] = 'The lookup can\'t be deleted',
    ['ORM_ERROR_RELATION_CREATE'] = 'The relation can\'t be created',
    ['ORM_ERROR_RELATION_MODIFY'] = 'The relation can\'t be modified',
    ['ORM_CHANGE_LOOKUPTYPE_ERROR'] = 'The lookup type can\'t be changed',
    ['ORM_READ_ONLY_TABLE'] = 'Read-only table',
    ['ORM_READ_ONLY_RELATION'] = 'Read-only relation',
    ['ORM_DUPLICATE_ATTRIBUTE'] = 'There   is   already   an   attribute   with   this name',
    ['ORM_DOMAIN_HAS_REFERENCE'] = 'Domains with reference attributes can\'t be deleted',
    ['ORM_FILTER_CONFLICT'] = 'Conflict by defining the filter',
    ['ORM_AMBIGUOUS_DIRECTION'] = 'The direction relation can\'t be automatically determined'
}

local CMDBuild = {
    type = 'CMDBuild',
    webservices = 'http://__ip__/cmdbuild/services/soap/Webservices',
    ltn12 = require 'ltn12',
    client = { http = require 'socket.http', },
}

CMDBuild.__index = CMDBuild -- get indices from the table
CMDBuild.__metatable = CMDBuild -- protect the metatable

---------------------------------------------------------------------
-- @param attr Table of object's attributes.
-- @return String with the value of the namespace ("xmlns") field.
---------------------------------------------------------------------
local function find_xmlns(attr)
    for a, v in pairs(attr) do
        if string.find(a, "xmlns", 1, 1) then
            return v
        end
    end
end

-- Iterates over the children of an object.
-- It will ignore any text, so if you want all of the elements, use ipairs(obj).
-- @param obj Table (LOM format) representing the XML object.
-- @param tag String with the matching tag of the children
--	or nil to match only structured children (single strings are skipped).
-- @return Function to iterate over the children of the object
--	which returns each matching child.

local function list_children(obj, tag)
    local i = 0
    return function()
        i = i + 1
        local v = obj[i]
        while v do
            if type(v) == "table" and (not tag or v[v.TAG] == tag) then
                return v
            end
            i = i + 1
            v = obj[i]
        end
        return nil
    end
end

------------------------------------------------------------------------
-- CMDBuild:new
-- Create new instance
-- @param pid - pid string for log (string or number)
-- @param logcolor - use color log print to stdout (boolean)
-- @param verbose - verbose mode (boolean)
-- @param _debug - debug mode (boolean)
-- @return instance
------------------------------------------------------------------------
function CMDBuild:new(pid, logcolor, verbose, _debug)
    CMDBuild.Header = {}
    CMDBuild.username = nil
    CMDBuild.password = nil
    CMDBuild.url = nil
    CMDBuild.verbose = verbose or false
    CMDBuild._debug = _debug or false

    CMDBuild.Log = require 'Log'
    CMDBuild.Log.pid = pid or 'cmdbuild_soap_api'
    CMDBuild.Log.usecolor = logcolor or false
    CMDBuild.Utils = require 'Utils'
    CMDBuild.Card = require 'cmdbuild.card'
    CMDBuild.Relation = require 'cmdbuild.relation'
    CMDBuild.Attachment = require 'cmdbuild.attachment'
    CMDBuild.Lookup = require 'cmdbuild.lookup'
    CMDBuild.Workflow = require 'cmdbuild.workflow'

    setmetatable(CMDBuild.Attachment, { __index = CMDBuild })
    setmetatable(CMDBuild.Card, { __index = CMDBuild })
    setmetatable(CMDBuild.Lookup, { __index = CMDBuild })
    setmetatable(CMDBuild.Relation, { __index = CMDBuild })
    setmetatable(CMDBuild.Workflow, { __index = CMDBuild })

    return CMDBuild
end


------------------------------------------------------------------------
-- CMDBuild:set_credentials
-- Set credentials for connected to CMDBuild
-- @param `credentials` The value object
-- @field username string
-- @field password string
-- @field url string
-- @field ip string
-- @return soap header
------------------------------------------------------------------------
function CMDBuild:set_credentials(credentials)
    if not self.username then
        if credentials.username then
            self.username = credentials.username
            self.Log.debug('Added user name', self.verbose)
        else
            self.Log.warn('`credentials.username\' can\'t be empty', self.verbose)
            os.exit(-1)
        end
    end

    if not self.password then
        if credentials.password then
            self.password = credentials.password
            self.Log.debug('Added a password for the user', self.verbose)
        else
            self.Log.warn('`credentials.password\' can\'t be empty', self.verbose)
            os.exit(-1)
        end
    end

    if not self.url then
        if credentials.url then
            self.url = credentials.url
            self.Log.debug('Added url CMDBuild', self.verbose)
        elseif credentials.ip then
            self.url = self.webservices:gsub('__ip__', credentials.ip)
            self.Log.debug('CMDBuild address is formed and added', self.verbose)
        else
            self.Log.warn('`credentials.ip\' can\'t be empty', self.verbose)
            os.exit(-1)
        end
    end

    self.Header.insertHeader = function()
        local oasisopen = 'http://docs.oasis-open.org/wss/2004/01/'
        local wsse = oasisopen .. "oasis-200401-wss-wssecurity-secext-1.0.xsd"
        local wssu = oasisopen .. "oasis-200401-wss-wssecurity-utility-1.0.xsd"
        local PassText = oasisopen .. "oasis-200401-wss-username-token-profile-1.0#PasswordText"

        if self.username and self.password then
            self.Header = {
                tag = "wsse:Security",
                attr = { ["xmlns:wsse"] = wsse },
                {
                    tag = "wsse:UsernameToken",
                    attr = { ["xmlns:wssu"] = wssu },
                    { tag = "wsse:Username", self.username },
                    { tag = "wsse:Password", attr = { Type = PassText }, self.password }
                }
            }
            self.Log.info('The SOAP header is formed and added', self.verbose)
        else
            self.Log.warn('Failed to generate the SOAP header', self.verbose)
            os.exit(-1)
        end
    end

    return self.Header
end

----- end of function CMDBuild:mt:set_credentials  -----

---------------------------------------------------------------------
-- CMDBuild.call
-- Call a remote method.
-- @table args Table with the arguments which could be
-- @field url String with the location of the server
-- @field namespace String with the namespace of the elements
-- @field method String with the method's name
-- @field entries Table of SOAP elements (LuaExpat's format)
-- @field header Table describing the header of the SOAP-ENV (optional)
-- @field internal_namespace String with the optional namespace used as a prefix for the method name (default = "")
-- @return String with namespace, String with method's name and Table with SOAP elements (LuaExpat's format)
---------------------------------------------------------------------
function CMDBuild:call(args)
    local header_template = { tag = "soap:Header", }
    local xmlns_soap = "http://schemas.xmlsoap.org/soap/envelope/"
    local xmlns_soap12 = "http://www.w3.org/2003/05/soap-envelope"

    ------------------------------------------------------------------------
    -- encode
    -- Converts a LuaXml table into a SOAP message
    -- @table args Table with the arguments, which could be (table)
    -- @field namespace String with the namespace of the elements.
    -- @field method String with the method's name
    -- @field entries Table of SOAP elements (LuaExpat's format)
    -- @field header Table describing the header of the SOAP envelope (optional)
    -- @field internal_namespace String with the optional namespace used as a prefix for the method name (default = "")
    -- @return String with SOAP envelope element
    ------------------------------------------------------------------------
    self.encode = function(args)
        local serialize

        -- Template SOAP Table
        local envelope_templ = {
            tag = "soap:Envelope",
            attr = {
                "xmlns:soap", "xmlns:soap1",
                ["xmlns:soap1"] = "http://soap.services.cmdbuild.org", -- to be filled
                ["xmlns:soap"] = "http://schemas.xmlsoap.org/soap/encoding/",
            },
            {
                tag = "soap:Body",
                [1] = {
                    tag = "soap1", -- must be filled
                    attr = {}, -- must be filled
                },
            }
        }

        ------------------------------------------------------------------------
        -- contents
        -- Serialize the children of an object
        -- @param obj - Table with the object to be serialized (table)
        -- @return String string.representation of the children
        ------------------------------------------------------------------------
        local function contents(obj)
            if not obj[1] then
                return ""
            else
                local c = {}
                for i = 1, #obj do
                    c[i] = serialize(obj[i])
                end
                return table.concat(c)
            end
        end

        ------------------------------------------------------------------------
        -- serialize
        -- Serialize an object
        -- @param obj - Table with the object to be serialized (table)
        -- @return String with string.representation of the object
        ------------------------------------------------------------------------
        serialize = function(obj)
            ------------------------------------------------------------------------
            -- attrs
            -- Serialize the table of attributes
            -- @param a - Table with the attributes of an element (table)
            -- @return String string.representation of the object
            ------------------------------------------------------------------------
            local function attrs(a)
                if not a then
                    return "" -- no attributes
                else
                    local c = {}
                    if a[1] then
                        for i = 1, #a do
                            local v = a[i]
                            c[i] = string.format("%s=%q", v, a[v])
                        end
                    else
                        for i, v in pairs(a) do
                            c[#c + 1] = string.format("%s=%q", i, v)
                        end
                    end
                    if #c > 0 then
                        return " " .. table.concat(c, " ")
                    else
                        return ""
                    end
                end
            end


            local tt = type(obj)
            if tt then
                if tt == "string" then
                    return self.Utils.escape(self.Utils.unescape(obj))
                elseif tt == "number" then
                    return obj
                elseif tt == "table" then
                    local t = obj.tag
                    if not t then return end
                    assert(t, "Invalid table format (no `tag' field)")
                    return string.format("<%s%s>%s</%s>", t, attrs(obj.attr), contents(obj), t)
                else
                    return ""
                end
            end
        end

        ------------------------------------------------------------------------
        -- insert_header
        -- Add header element (if it exists) to object
        -- Cleans old header element anywat
        -- @tparam obj - Object for insert new header (table)
        -- @tparam header - template header (table)
        -- @return header_template (table)
        ------------------------------------------------------------------------
        self.insert_header = function(obj, header)
            -- removes old header
            if obj[2] then
                table.remove(obj, 1)
            end
            if header then
                header_template[1] = header
                table.insert(obj, 1, header_template)
            end
        end

        if tonumber(args.soapversion) == 1.2 then
            envelope_templ.attr["xmlns:soap"] = xmlns_soap12
        else
            envelope_templ.attr["xmlns:soap"] = xmlns_soap
        end

        local xmlns = "xmlns"
        if args.internal_namespace then
            xmlns = xmlns .. ":" .. args.internal_namespace
            args.method = args.internal_namespace .. ":" .. args.method
        else
            xmlns = xmlns .. ":soap1"
            args.method = "soap1:" .. args.method
        end

        -- Cleans old header and insert a new one (if it exists).
        self.insert_header(envelope_templ, args.header or self.Header)

        -- Sets new body contents (and erase old content).
        local body = (envelope_templ[2] and envelope_templ[2][1]) or envelope_templ[1][1]
        for i = 1, math.max(#body, #args.entries) do
            body[i] = args.entries[i]
        end

        -- Sets method (actually, the table's tag) and namespace.
        body.tag = args.method
        body.attr[xmlns] = args.namespace

        return serialize(envelope_templ)
    end

    local soap_action, content_type_header
    if (not args.soapversion) or tonumber(args.soapversion) == 1.1 then
        content_type_header = "text/xml;charset=UTF-8"
    else
        content_type_header = "application/soap+xml"
    end
    local xml_header_template = '<?xml version="1.0"?>'
    local xml_header = xml_header_template
    if args.encoding then
        xml_header = xml_header:gsub('"%?>', '" encoding="' .. args.encoding .. '"?>')
    end

    local request_body = xml_header .. self.encode(args)
    self.Log.debug('SOAP Request: ' .. tostring(xml.eval(request_body)), self._debug)

    local request_sink, tbody = self.ltn12.sink.table()
    local headers = {
        ["Content-Type"] = content_type_header,
        ["Content-Length"] = tostring(request_body:len()),
        ["SOAPAction"] = soap_action,
    }

    if args.headers then
        for h, v in pairs(args.headers) do
            headers[h] = v
        end
    end

    local mandatory_url = "Field `url' is mandatory"
    local url = {
        url = assert(args.url or self.url, mandatory_url),
        method = "POST",
        source = self.ltn12.source.string(request_body),
        sink = request_sink,
        headers = headers,
    }

    local suggested_layers = { http = "socket.http", https = "ssl.https", }
    local protocol = url.url:match "^(%a+)" -- protocol's name
    local mod = assert(self.client[protocol], '"'
            .. protocol
            .. '" protocol support unavailable. Try soap.CMDBuild.'
            .. protocol
            .. ' = require"'
            .. suggested_layers[protocol]
            .. '" to enable it.')
    local request = assert(mod.request, 'Could not find request function on module soap.CMDBuild.' .. protocol)
    request(url)

    ------------------------------------------------------------------------
    -- retriveMessage
    -- The function truncates the additional information in the SOAP response
    -- @param response - SOAP response (table)
    -- @return resp - (string)
    ------------------------------------------------------------------------
    local function retriveMessage(response)
        ------------------------------------------------------------------------
        -- jtr
        -- Create lua table from SOAP response table
        -- @param text_array - SOAP (table)
        -- @return ret - (string)
        ------------------------------------------------------------------------
        local function jtr(text_array)
            local ret = ""
            for i = 1, #text_array do if text_array[i] then ret = ret .. text_array[i]; end end
            return ret;
        end

        local resp = jtr(response)
        local istart, iend = resp:find('<soap:Envelope.*</soap:Envelope>');
        if (istart and iend) then
            return resp:sub(istart, iend);
        else
            return nil
        end
    end

    local error_handler = function(response)
        local _response = xml.eval(response)

        if _response:find 'soap:Fault' then
            local fault = _response:find 'soap:Fault':find 'faultstring'[1]
            if fault then
                self.Log.error('SOAP Error: ' .. fault, self.verbose)
                os.exit(-1)
            end
        end
        return _response
    end

    local response =  retriveMessage(tbody)
    if response then
      self.Log.debug('SOAP Response: ' .. tostring(xml.eval(response)), self._debug)
    else
      return
    end
    tbody.xml = function()
        return error_handler(response)
    end

    ---------------------------------------------------------------------
    -- Converts a SOAP message into Lua objects.
    -- @param ignoreFields
    -- @param onCardLoad
    -- @return String with namespace, String with method's name and
    -- Table with SOAP elements (LuaExpat's format).
    ---------------------------------------------------------------------
    tbody.decode = function(ignoreFields, onCardLoad)
        local obj = assert(error_handler(response))
        local ns = obj[obj.TAG]:match("^(.-):")
        assert(obj[obj.TAG] == ns .. ":Envelope", "Not a SOAP Envelope: " .. tostring(obj[obj.TAG]))
        local lc = list_children(obj)
        local o = lc()
        -- Skip SOAP:Header
        while o and (o[o.TAG] == ns .. ":Header" or o.tag == "SOAP-ENV:Header") do
            o = lc()
        end
        if o and (o[o.TAG] == ns .. ":Body" or o.tag == "SOAP-ENV:Body") then
            obj = list_children(o)()
        else
            error("Couldn't find SOAP Body!")
        end
        local method = obj[obj.TAG]:match("%:([^:]*)$") or obj[obj.TAG]
        local response = {
            namespace = find_xmlns(obj),
            method = method, --obj[obj.TAG]:match("%:([^:]*)$") or obj[obj.TAG],
            entries = { Id = {} }
        }

        local ns = obj[obj.TAG]:match("^(.-):")
        obj = list_children(obj, ns .. ':return')()
        if not obj then return end
        if method ~= 'createCardResponse' and method ~= 'updateCardResponse' and method ~= 'deleteCardResponse' and obj[2] and obj[2][1]:find(ns .. ':attributeList') then
            for i = 1, #obj
            do
                local id = obj[i]:find(ns .. ":id")
                if id ~= nil then
                    id = id[1]
                    if obj[i][1]:find(ns .. ':attributeList') then
                        for j = 1, #obj[i]
                        do
                            local attrList = obj[i][j]:find(ns .. ":attributeList")
                            if attrList ~= nil then
                                local key = attrList:find(ns .. ":name")
                                local value = attrList:find(ns .. ":value") or ""
                                local code = attrList:find(ns .. ":code") or ""
                                if key ~= nil and not self.Utils.isin(ignoreFields, key[1]) then
                                    key = key[1]
                                    value = value[1]
                                    code = code[1]
                                    if response.entries.Id[tostring(id)] == nil then
                                        response.entries.Id[tostring(id)] = {}
                                    end
                                    if code == nil then
                                        response.entries.Id[tostring(id)][key] = value
                                    else
                                        response.entries.Id[tostring(id)][key] = { value = value, code = code }
                                    end
                                end
                            end
                        end
                        if onCardLoad ~= nil then
                            onCardLoad(response.entries, tostring(id))
                        end
                    end
                end
            end
        else
            if method == 'getCardListResponse' or method == 'getCardResponse' then
                local id
                if not id then
                    if obj[1]:find(ns..':id') then
                        id= obj[1]:find(ns..':id')[1]
                    elseif obj:find(ns..':id') then
                        id = obj:find(ns..':id')[1]
                    else
                        id = 0
                    end
                end
                if obj[1]:find(ns..':cards') then
                    obj = obj[1]:find(ns..':cards')
                end
                for i = 1, #obj do
                    if id then
                        local attrList = obj[i]:find(ns .. ":attributeList")
                        if attrList then
                            local key = attrList:find(ns .. ":name")
                            local value = attrList:find(ns .. ":value") or ""
                            local code = attrList:find(ns .. ":code") or ""
                            if key ~= nil and not self.Utils.isin(ignoreFields, key[1]) then
                                key = key[1]
                                value = value[1]
                                code = code[1]
                                if response.entries.Id[tostring(id)] == nil then
                                    response.entries.Id[tostring(id)] = {}
                                end
                                if code == nil then
                                    response.entries.Id[tostring(id)][key] = value
                                else
                                    response.entries.Id[tostring(id)][key] = { value = value, code = code }
                                end
                            end
                        end
                    end
                end
            elseif method == 'createCardResponse' or method == 'updateCardResponse' then
                if response.entriesId == nil then
                    response.entries.Id = {}
                end
                response.entries.Id['cardId'] = obj[1]
            elseif method == 'deleteCardResponse' then
                if response.entries.Id == nil then
                    response.entries.Id = {}
                end
                response.entries.Id['status'] = obj[1]
            else
                for i=1, #obj do
                    local key = obj[i][obj.TAG]
                    local value = obj[i][1]
                    if response.entries.Id == nil then
                        response.entries.Id = {}
                    end
                    response.entries.Id[key] = value
                end
            end
        end

        ------------------------------------------------------------------------
        -- response.tprint
        -- Recursively print arbitrary data
        -- @param l - Set limit (default 100000) to stanch infinite loops (number)
        -- @param i - Indents tables as [KEY] VALUE, nested tables as [KEY] [KEY]...[KEY] VALUE (string)
        -- Set indent ("") to prefix each line:    Mytable [KEY] [KEY]...[KEY] VALUE
        -- @return
        ------------------------------------------------------------------------
        response.tprint = function(l, i) -- recursive Print (structure, limit, indent)
            local function rPrint(s, l, i)
                l = (l) or 100000;
                i = i or ""; -- default item limit, indent string
                if (l < 1) then
                    print "ERROR: Item limit reached.";
                    return l - 1
                end;
                local ts = type(s);
                if (ts ~= "table") then
                    print(i, ts, s);
                    return l - 1
                end
                print(i, ts); -- print "table"
                for k, v in pairs(s) do -- print "[KEY] VALUE"
                    if k ~= 'tprint' then
                        l = rPrint(v, l, i .. "\t[" .. tostring(k) .. "]");
                    end
                    if (l < 0) then break end
                end
                return l
            end

            return rPrint(response, l, i)
        end

        return response
    end

    return tbody
end

return CMDBuild
