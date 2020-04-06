return {
  index = {
    ["end"] = function(response)
      return function() end
    end,

    send = function(response)
      return function(body)
        ngx.say(body)
      end
    end,

    flush = function(response)
      return function(body)
        ngx.say(body)
        ngx.flush(true)
      end
    end,

    status = function(response)
      return ngx.status
    end,

    headers = function(response)
      return ngx.header
    end
  },

  newindex = {
    --same as above but for newIndex
    status = function(response, value)
      ngx.status = value
    end
  }
}

