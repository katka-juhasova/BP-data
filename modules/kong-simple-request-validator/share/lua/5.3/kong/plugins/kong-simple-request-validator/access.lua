local _M = {}

local validation = require "resty.validation"
local cjson = require "cjson"
local jsonschema = require 'jsonschema'

local function mysplit (inputstr, sep)
    if sep == nil then
        sep = "%s"
    end
    local t = {}
    for str in string.gmatch(inputstr, "([^" .. sep .. "]+)") do
        table.insert(t, str)
    end
    return t
end

local function check(rule, result, query_arg, name)
    local type = rule.type
    local required = rule.required
    local empty, e = validation.null(query_arg)
    local len_eq = rule.len_eq
    local len_min = rule.len_min
    local len_max = rule.len_max
    local max = rule.max
    local min = rule.min
    local eq = rule.eq
    local un_eq = rule.un_eq
    local email = rule.email
    local oneof = rule.oneof
    local noneof = rule.noneof
    local oneofTable = rule.oneofTable
    local noneofTable = rule.noneofTable

    if required then
        if empty then
            table.insert(result, name .. " is required")
        end
    end
    if type then
        if not empty and type == "string" then
            local ok, e = validation.string(query_arg)
            if ok == false then
                table.insert(result, name .. "must be string")
            end
        end
        if not empty and type == "number" then
            local ok, e = validation.number(tonumber(query_arg))
            if ok == false then
                table.insert(result, name .. " must be number")
            end
        end
        if not empty and type == "integer" then
            local ok, e = validation.integer(tonumber(query_arg))
            if ok == false then
                table.insert(result, name .. " must be integer")
            end
        end
        if not empty and type == "float" then
            local ok, e = validation.float(tonumber(query_arg))
            if ok == false then
                table.insert(result, name .. " must be float")
            end
        end
    end
    if len_eq then
        if not empty and type == "string" then
            local ok, e = validation.optional:len(len_eq, len_eq)(query_arg)
            if ok == false then
                table.insert(result, name .. " length must = " .. tostring(len_eq))
            end
        end
    end
    if len_min then
        if not empty and type == "string" then
            local ok, e = validation.optional:minlen(len_min)(query_arg)
            if ok == false then
                table.insert(result, name .. " length must >= " .. tostring(len_min))
            end
        end
    end
    if len_max then
        if not empty and type == "string" then
            local ok, e = validation.optional:maxlen(len_max)(query_arg)
            if ok == false then
                table.insert(result, name .. " length must <= " .. tostring(len_max))
            end
        end
    end
    if min then
        if not empty and type == "number" then
            local ok, e = validation.optional:min(min)(tonumber(query_arg))
            if ok == false then
                table.insert(result, name .. " must >= " .. tostring(min))
            end
        end
    end
    if max then
        if not empty and type == "number" then
            local ok, e = validation.optional:max(max)(tonumber(query_arg))
            if ok == false then
                table.insert(result, name .. " must <= " .. tostring(max))
            end
        end
    end
    if eq then
        if not empty then
            local ok, e = validation.optional:equals(eq)(query_arg)
            if ok == false then
                table.insert(result, name .. " must == " .. tostring(eq))
            end
        end
    end
    if un_eq then
        if not empty then
            local ok, e = validation.optional:unequals(eq)(query_arg)
            if ok == false then
                table.insert(result, name .. " must unequal " .. tostring(un_eq))
            end
        end
    end
    if email then
        if not empty and type == "string" and email then
            local ok, e = validation.optional:email()(query_arg)
            if ok == false then
                table.insert(result, name .. " must be email")
            end
        end
    end
    if oneof then
        if not empty and oneof then
            kong.log.err(oneof)
            local ok, e = validation.optional:oneof(table.unpack(oneofTable))(query_arg)
            if ok == false then
                table.insert(result, name .. " must be oneof " .. oneof)
            end
        end
    end
    if noneof then
        if not empty and noneof then
            local ok, e = validation.optional:noneof(table.unpack(noneofTable))(query_arg)
            if ok == false then
                table.insert(result, name .. " must be noneof " .. noneof)
            end
        end
    end
end

local function get_schema(schema)
    local result = nil
    if schema then
        result = cjson.decode(schema)
        for i, v in ipairs(result) do
            if v.oneof then
                v.oneofTable = mysplit(v.oneof, ',')
            end
            if v.noneof then
                v.noneofTable = mysplit(v.noneof, ',')
            end
        end
    end
    return result
end

local function isTableEmpty(t)
    return t == nil or next(t) == nil
end

local function getOpts()
    return {
        ttl = 600,
        neg_ttl = 600
    }
end

local function request_validator(conf)
    local result = {}
    local cache = kong.cache
    local content_type = kong.request.get_header("Content-Type")
    local cache_prefix = tostring(conf.updated_at)

    local res, err = cache:get_bulk(
            {
                cache_prefix .. 'query_schema', getOpts(), get_schema, conf.query_schema,
                cache_prefix .. 'form_schema', getOpts(), get_schema, conf.form_schema,
                cache_prefix .. 'json_schema', getOpts(), get_schema, conf.json_schema,
                n = 3 -- specify the number of operations
            }
    , { concurrency = 3 })

    local query_schema = res[1]
    local form_schema = res[4]
    local json_schema = res[7]

    --kong.log.err('1111')
    --kong.log.err(cjson.encode(res))
    --kong.log.err(cjson.encode(query_schema))
    --kong.log.err(cjson.encode(form_schema))
    --kong.log.err(cjson.encode(json_schema))

    if conf.query_schema then
        if query_schema then
            for i, v in ipairs(query_schema) do
                local name = v.name
                local query_arg = kong.request.get_query_arg(name)
                check(v, result, query_arg, name)
                if table.getn(result) > 0 then
                    break
                end
            end
        end
    end

    if conf.form_schema then
        if isTableEmpty(result) and (content_type == 'application/x-www-form-urlencoded' or content_type == 'multipart/form-data') and form_schema then
            local body, err, mimetype = kong.request.get_body()
            if body then
                for i, v in ipairs(form_schema) do
                    local name = v.name
                    local body_arg = body[name]
                    check(v, result, body_arg, name)
                    if not isTableEmpty(result) then
                        break
                    end
                end
            end
        end
    end
    if conf.json_schema then
        if isTableEmpty(result) and content_type == 'application/json' and json_schema then
            local body, err, mimetype = kong.request.get_body()
            if body then
                local validator = jsonschema.generate_validator(json_schema)
                local res, message = validator(body)
                if not res then
                    table.insert(result, message)
                end
            end
        end
    end

    if not isTableEmpty(result) then
        return kong.response.exit(400, { message = result })
    end
end

function _M.execute(conf)
    request_validator(conf)
end

return _M
