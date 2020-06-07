-- alnbox, alignment viewer based on the curses library
-- Copyright (C) 2015 Boris Nagaev
-- See the LICENSE file for terms of use

return function(file)
    local names = {}
    local name2text = {}
    local name2description = {}
    local name
    for line in file:lines() do
        line = line:gsub('\n', '')
        if line:sub(1, 1) == '>' then
            if not line:match(' ') then
                -- append ' ' if line contains no spaces
                line = line .. ' '
            end
            local n, d = assert(line:match('>(%S+) (.*)'))
            name = n
            name2description[name] = d
            table.insert(names, name)
            name2text[name] = {}
        else
            assert(name)
            table.insert(name2text[name], line)
        end
    end
    for _, name in ipairs(names) do
        name2text[name] = table.concat(name2text[name])
    end
    return {
        names = names,
        name2text = name2text,
        name2description = name2description,
    }
end
