-- alnbox, alignment viewer based on the curses library
-- Copyright (C) 2015 Boris Nagaev
-- See the LICENSE file for terms of use

return function(foreground, background)
    return background * 8 + 7 - foreground
end
