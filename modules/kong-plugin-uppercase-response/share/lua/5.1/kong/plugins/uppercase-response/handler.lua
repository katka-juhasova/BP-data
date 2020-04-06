local UppercaseResponseHandler = {}

UppercaseResponseHandler.PRIORITY = 5
UppercaseResponseHandler.VERSION = "0.0.1"

local concat = table.concat
local upper = string.upper


function UppercaseResponseHandler:body_filter(conf)
    local chunk, eof = ngx.arg[1], ngx.arg[2]
    local ctx = ngx.ctx

    ctx.rt_body_chunks = ctx.rt_body_chunks or {}
    ctx.rt_body_chunk_number = ctx.rt_body_chunk_number or 1

    if eof then
      local body = concat(ctx.rt_body_chunks)
      ngx.arg[1] = upper(body)

    else
      ctx.rt_body_chunks[ctx.rt_body_chunk_number] = chunk
      ctx.rt_body_chunk_number = ctx.rt_body_chunk_number + 1
      ngx.arg[1] = nil
    end
end


return UppercaseResponseHandler
