local tmpl = dofile 'java.tmpl' -- load the template

-- populate with data
tmpl._name = 'Person'
tmpl._attrs = {
    { _name = 'name',       _type = 'String' },
    { _name = 'age',        _type = 'Integer' },
    { _name = 'address',    _type = 'String' },
}

print(tmpl 'class')     -- interpolation
