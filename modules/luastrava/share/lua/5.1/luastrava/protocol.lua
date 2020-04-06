local requests=require('requests')
local encode =require('luastrava.encode') 

local ApiV3 = { 
    server='www.strava.com',
    server_webhook_events='api.strava.com',
    api_base='/api/v3'
    }



function ApiV3:new (o) -- args (access_token,requests_session,rate_limiter)
    o= o or {}
    
    setmetatable(o,self)
    self.__index=self

    return o
end


function ApiV3:authorization_url(client_id,redirect_uri,approval_prompt,scope,state) 
    approval_prompt=approval_prompt or 'auto'
    local a_prompt={ auto=true, force=true}


    assert(a_prompt[approval_prompt],"APPROVAL PROMPT MUST BE EITHER 'AUTO' OR 'FORCE'")

    params={
        client_id=client_id,
        redirect_uri=redirect_uri,
        approval_prompt=approval_prompt,
        response_type='code'

        }
    if type(scope)=='table' then 
        scope=table.concat(scope,',')
    end

    
       
    if scope~=nil then
        params.scope=scope
    end


    if state~=nil then 
        params.scope=state

    end

    return 'https://' .. self.server .. '/oauth/authorize?' .. encode.table(params)
end

function ApiV3:exchange_code_for_token(client_id,client_secret,code)
  
    local response= self:_request{url='https://'..  self.server ..'/oauth/token',params={client_id=client_id,client_secret=client_secret,code=code},method='POST'}


   local token=response['access_token']
   self.access_token=token

   return token

end

function ApiV3:_resolve_url(url,use_webhook_server)
    server=use_webhook_server and self.server_webhook_events or self.server
    if string.find(url,'http')==nil then 
        url='https://' .. server .. self.api_base .. url
    end
    return url


end

function ApiV3:_request(o) --(url,params,method,files,check_for_errors,use_webhook_server)

    local http_methods={
        GET=requests.get,
        POST=requests.post,
        PUT=requests.put,
        DELETE=requests.delete
    
    }

    o.method=o.method or 'GET'

    o.check_for_errors= o.check_for_errors or true
    o.use_webhook_server=o.use_webhook_server or false

    o.url=self:_resolve_url(o.url,o.use_webhook_server)
    --log here
    
    if not o.params  then  o.params={} end

    if self.access_token then o.params.access_token=self.access_token
    end
    
    print("REQUEST URL=" .. o.url)

    local requester=http_methods[o.method]

    assert(requester~=nil,'INVALID HTTP REQUEST')

    local raw=requester{url=o.url,params=o.params}
    print("REQUEST DETAILS")
    print(raw.status_code)


    if o.check_for_errors== true then
        self:_handle_protocol_error(raw)
    end
    local resp
    if raw.status_code == 204 then 
         resp={}
    else 
        resp,err=raw.json()

        
    end

    return resp
end

function ApiV3:_handle_protocol_error(res)
    print(res.status_code)
    if 400 <= res.status_code and res.status_code <500 then
       error("Client Error :" .. res.status_code)

    elseif 500<= res.status_code and res.status_code< 600 then
        error("Server Error:" .. res.status_code)

    end--]]-- 

    return res
    
end


function ApiV3:get(url,check_for_errors,use_webhook_server,params)
    use_webhook_server=use_webhook_server or false
    return self:_request{url=url,params=params,check_for_errors=true,use_webhook_server=use_webhook_server}
end


function ApiV3:post(args) --(url,files=None,check_for_errors,use_webhook_server,params)
    args.check_for_errors=args.check_for_errors or true

    args.use_webhook_server=args.use_webhook_server or false

    args.files=args.files or nil

    return self:_request{url=args.url,params=args.params,files=args.files,method='POST',check_for_errors=args.check_for_errors,use_webhook_server=args.use_webhook_server}

end


function ApiV3:put(args) --(url,files=None,check_for_errors,use_webhook_server,params)
    args.check_for_errors=args.check_for_errors or true

    args.use_webhook_server=args.use_webhook_server or false

    args.files=args.files or nil

    return self:_request{url=args.url,params=args.params,files=args.files,method='PUT',check_for_errors=args.check_for_errors,use_webhook_server=args.use_webhook_server}

end


function ApiV3:delete(args) --(url,files=None,check_for_errors,use_webhook_server,params)
    args.check_for_errors=args.check_for_errors or true

    args.use_webhook_server=args.use_webhook_server or false

    args.files=args.files or nil

    return self:_request{url=args.url,params=args.params,files=args.files,method='DELETE',check_for_errors=args.check_for_errors,use_webhook_server=args.use_webhook_server}

end



return {
    ApiV3=ApiV3

}
