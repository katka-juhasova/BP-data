JSON_CONTENT_TYPE = 'application/json'
OPENAPI_CONTENT_TYPE = 'application/vnd.coreapi+json'
KONG_CONSUMER_HEADER = 'X-Consumer-Username'
KONG_ACLS_HEADER = 'X-Consumer-Groups'


local module = {}

module.constants = {
    ['JSON_CONTENT_TYPE'] = JSON_CONTENT_TYPE,
    ['OPENAPI_CONTENT_TYPE'] = OPENAPI_CONTENT_TYPE,
    ['KONG_CONSUMER_HEADER'] = KONG_CONSUMER_HEADER,
    ['KONG_ACLS_HEADER'] = KONG_ACLS_HEADER
}

function module.get_content_type (query_params)
    local content_type = ngx.req.get_headers()['Content-Type']
    local query_format = query_params.format

    if query_format or content_type then
        if query_format then
            if query_format == 'json' then
              content_type = JSON_CONTENT_TYPE
            else
                if query_format == 'openapi' then
                    content_type = OPENAPI_CONTENT_TYPE
                end
            end
        end
    else
        content_type = JSON_CONTENT_TYPE
    end

    return content_type
end

function module.get_uuid_from_id (s)
    return s:gsub('%_', '-')
end

function module.get_consumer_id ()
    return module.get_uuid_from_id(kong.request.get_header(KONG_CONSUMER_HEADER))
end

function module.get_consumer_acls ()
    local acls_header = kong.request.get_header(KONG_ACLS_HEADER)
    local acls = {}

    if acls_header then
        for word in string.gmatch(acls_header, '([^,]+)') do
            local w = string.gsub(word, "%s+", "")
            table.insert(acls, w)
        end
    end

    return acls
end

function module.consumer_is_staff (acls)
    for k,v in pairs(acls) do
        if v == 'staff' then
            return true
        end
    end

    return false
end

function module.consumer_is_api (acls)
    for k,v in pairs(acls) do
        if v == 'api' then
            return true
        end
    end

    return false
end

return module
