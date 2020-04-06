lusty-mustache
==============

mustache rendering for lusty

```lua
local config = {
  render = {
    { ['lusty-mustache.render.mustache'] = {
        -- set defaults here
        template {
          name = 'templates/layout',

          partials = {
            content = 'templates/home'
          }
        }
    } }
  }
}
```

In your request handler:

```lua
context.template = {
  name = 'template/somethingelse',

  partials = {
    content = 'templates/404'
  },

  -- don't forget to set your context.template.type to mustache or this won't
  -- fire!

  type = 'mustache'
}

```
