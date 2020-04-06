-- alnbox, alignment viewer based on the curses library
-- Copyright (C) 2015 Boris Nagaev
-- See the LICENSE file for terms of use

return function(names, name2text, name2description)
    local alignment = {names={}, name2text={},
        name2description={}}
    for _, name in ipairs(names) do
        assert(type(name) == 'string')
        table.insert(alignment.names, name)
        local text = name2text[name]
        assert(type(text) == 'string')
        alignment.name2text[name] = text
        local descr = ''
        if name2description then
            descr = name2description[name] or ''
        end
        assert(type(descr) == 'string')
        alignment.name2description[name] = descr
    end
    return alignment
end
