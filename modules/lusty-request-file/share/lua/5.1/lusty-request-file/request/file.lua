local util = require 'lusty.util'

return {
  handler = function(context)
    util.inline(config, {config=config, context=context})
  end
}
