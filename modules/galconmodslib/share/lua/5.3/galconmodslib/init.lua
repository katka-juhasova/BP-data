---
-- Module containing some bot utility functions.
--

local _M = {}

-- try to send an amount of ships, return the amount sent
function _M.send_exact(user, from, to, ships)
    if from.ships_value < ships then
        from:fleet_send(100, to)
        return from.ships_value
    end
    local perc = ships / from.ships_value * 100
    if perc > 100 then perc = 100 end
    from:fleet_send(perc, to)
    return ships
end

function _M.test()
  print('this is a test!')
end

return _M
