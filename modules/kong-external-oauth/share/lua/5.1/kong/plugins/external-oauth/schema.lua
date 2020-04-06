
-- Copyright 2016 Niko Usai
-- Modifications Copyright (C) 2019 wanghaoyu@agora.io

--    Licensed under the Apache License, Version 2.0 (the "License");
--    you may not use this file except in compliance with the License.
--    You may obtain a copy of the License at

--        http://www.apache.org/licenses/LICENSE-2.0

--    Unless required by applicable law or agreed to in writing, software
--    distributed under the License is distributed on an "AS IS" BASIS,
--    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
--    See the License for the specific language governing permissions and
-- limitations under the License.

local typedefs = require "kong.db.schema.typedefs"

return {
  name = "external-oauth",
  fields = {
    {
      config = {
        type = "record",
        fields = {
          { authorize_url = typedefs.url{required = true}, },
          { token_url = typedefs.url{required = true}, },
          { user_url = typedefs.url{required = true}, },
          { client_id = {type = "string", required = true}, },
          { client_secret = {type = "string", required = true}, },
          { scope = {type = "string"}, },
          { user_keys = {type = "array",
            default = {"username", "email"},
          elements = {type = "string", }, }, },
          { user_info_periodic_check = {type = "integer", default = 600}, },
          { auth_token_expire_time = {type = "integer", default = 259200}, },
          { hosted_domain = {type = "string"}, },
          { email_key = {type = "string"}, },
          { callback_schema = typedefs.protocol, },
          { callback_port = typedefs.port, },
        },
      },
    },
  },
}
