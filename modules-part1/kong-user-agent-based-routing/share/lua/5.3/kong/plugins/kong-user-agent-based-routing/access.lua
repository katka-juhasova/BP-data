local _M = {}

function _M.execute(conf)
  local is_mweb = kong.request.get_header(conf.user_agent_header)
  if is_mweb then
    local ok, err = kong.service.set_upstream(conf.destination)
    if not ok then
      kong.log.err(err)
      return
    end
  end
  kong.service.request.clear_header(conf.user_agent_header)
end

return _M
