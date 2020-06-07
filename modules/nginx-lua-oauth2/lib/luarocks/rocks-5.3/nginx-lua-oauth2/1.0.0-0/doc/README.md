# nginx-lua-oauth2
nginx module for oauth2 authentication

1. install lua-cjson and nginx-extras

    sudo apt install lua-cjson nginx-extras

2. install this library

    sudo cp -r nginx-lua-oauth2.lua resty /usr/share/lua/5.1/ 

3. put this in your nginx config

    location /auth/ {
        resolver 8.8.8.8 8.8.4.4;
        lua_ssl_trusted_certificate /etc/ssl/certs/ca-certificates.crt;
        access_by_lua_block {
            require("nginx-lua-oauth2").auth({
                client_id = "dd9323ac-1bf8-45d1-806b-09b45e4d989f",
                client_secret = "APwi9H4yOXMJ+NGeie/n8kXVBzry2misJi1fxrFNcRk=",
                token_url = "https://login.windows.net/8371d803-6f9a-46e1-a8ae-eec4a1998cbd/oauth2/token",
                authorize_url = "https://login.windows.net/8371d803-6f9a-46e1-a8ae-eec4a1998cbd/oauth2/authorize",
                token_params = { resource = 'https://graph.windows.net/' }, # optional!
                authorize_params = { resource = 'https://graph.windows.net/' }, # optional!
                ssl_verify = true # optional
            })
        }
    }

4. enjoy.

the current access_token / refresh_token can be obtained by reading the cookie "oauth2_access_token" or "oauth2_refresh_token"

