
# Coat.Meta.Class

---

# Reference

## Functions

#### attributes( class )

Returns a generator of couple `(name, attr)` for `class`.

#### class( modname )

Returns the Coat class `modname` or `nil`.

#### classes()

Returns a table with all Coat classes.

#### has( class, name )

Returns the table of options of the attribute `name`
in the class `class` or `nil`.

#### methods( class )

Returns a generator of couple `(name, method)` for `class`.

#### metamethods( class )

Returns a generator of couple `(name, metamethod)` for `class`.

#### parents( class )

Returns a generator of couple `(name, parent)` for `class`.

#### roles( class )

Returns a generator of couple `(name, role)` for `class`.
