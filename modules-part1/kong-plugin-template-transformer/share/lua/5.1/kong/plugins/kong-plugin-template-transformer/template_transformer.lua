local resty_template = require 'resty.template'

_M = {}

_M.get_template = function(template)
    return resty_template.compile(template)
end

return _M
