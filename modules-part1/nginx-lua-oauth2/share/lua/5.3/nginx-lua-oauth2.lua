





local oauth_client_id = ngx.var.oauth2_client_id
local oauth_client_secret = ngx.var.oauth2_client_secret
local oauth_authorize_url = ngx.var.oauth2_authorize_url
local oauth_token_url = ngx.var.oauth2_token_url
-- local oauth_authorize_params = { resource = 'https://graph.windows.net/' }
-- local oauth_token_params = { resource = 'https://graph.windows.net/' }
local oauth_cookie_prefix = 'oauth2'
local oauth_cookie_key = ngx.var.oauth2_client_secret

local json = require('cjson')
local http = require('resty.http')
local jwt = require('resty.jwt')
local cookie = require('resty.cookie')

function fail(message)
    ngx.log(ngx.STDERR, "oauth2 error: " .. message)
    ngx.header.content_type = 'text/html'
    ngx.status = ngx.HTTP_FORBIDDEN
    ngx.print("<html><body><h1>oauth2 error: " .. message .. "</h1></body></html>")
    ngx.print('<a href="/auth/_oauth2_start">again</a>')
    ngx.exit(ngx.ERROR)
end

function table_merge(t1, t2)
    for k,v in pairs(t2) do
        t1[k] = v
    end
    return t1
end

function check_oauth_response(config)
    local redirect_uri = ngx.var.scheme..'://'..ngx.var.host..ngx.var.uri
    if ngx.req.get_uri_args()['error'] then
        fail('urlerror: '..ngx.req.get_uri_args()['error'])
    elseif ngx.req.get_uri_args()['code'] then
        local request = http.new()
        request:set_timeout(7000)
        local args = {
            code = ngx.req.get_uri_args()['code'],
            client_id = config['client_id'],
            client_secret = config['client_secret'],
            grant_type = 'authorization_code',
            redirect_uri = redirect_uri
        }
        if config['token_params'] then
            args = table_merge(args, config['token_params'])
        end
        local ssl_verify = false
        if config['ssl_verify'] then
            ssl_verify = true
        end
        local res, err = request:request_uri(config['token_url'], {
            method = 'POST',
            body = ngx.encode_args(args),
            headers = {
                ["Content-type"] = "application/x-www-form-urlencoded"
            },
            ssl_verify = ssl_verify
        })
        if err then
            fail('httperror: '..tostring(err))
        elseif res.status ~= 200 then
            fail('codeerror: '..tostring(res.body))
        else
            -- ngx.log(ngx.STDERR, 'body: '..res.body)
            token = json.decode(res.body)
            cookietoken = {
                ok = true
            }
            data = jwt:sign(config['jwt_key'], {
                header = {typ='JWT', alg='HS512'},
                payload = cookietoken
            })
            local cookies, err = cookie:new()
            cookies:set({
                key = config['cookie_prefix'] .. 'jwt',
                value = data,
                path = '/'
            })
            cookies:set({
                key = config['cookie_prefix'] .. 'access_token',
                value = token['access_token'],
                path = '/'
            })
            cookies:set({
                key = config['cookie_prefix'] .. 'refresh_token',
                value = token['refresh_token'],
                path = '/'
            })
            ngx.redirect(redirect_uri)
        end
    end
end

function redirect_to_oauth(config)
    local redirect_uri = ngx.var.scheme..'://'..ngx.var.host..ngx.var.uri
    local args = {
        client_id = config['client_id'],
        response_type = 'code',
        redirect_uri = redirect_uri,
    }
    if config['authorize_params'] then
        args = table_merge(args, config['authorize_params'])
    end
    local url = config['authorize_url']..'?'..ngx.encode_args(args)
    ngx.redirect(url)
end

function check_cookie(config)
    local cookies, err = cookie:new()
    if cookies then
        local encoded, err = cookies:get(config['cookie_prefix'] .. 'jwt')
        if encoded then
            local token = jwt:verify(config['jwt_key'], encoded)
            if token['verified'] then
                ngx.exit(ngx.OK)
            end
        end
    end
end

function auth(config)
    if not config['cookie_prefix'] then
        config['cookie_prefix'] = 'oauth2_'
    end
    if not config['jwt_key'] then
        config['jwt_key'] = config['client_secret']
    end
    check_cookie(config)
    check_oauth_response(config)
    redirect_to_oauth(config)
end

local _M = {
    auth = auth
}
return _M
 
