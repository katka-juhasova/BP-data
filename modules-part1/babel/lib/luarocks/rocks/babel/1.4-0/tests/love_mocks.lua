-- Mock Löve2D
_G.love = {
    filesystem = {
        exists = function() return false  end,
        load = function() return nil end
    }
}

