# inline

This module provides a system for creating and serving unique classes in your web application.

## Why Inline?
The workflow for creating and serving styles typically involves creating and compiling SASS files in your `/static` folder.

These files need to be written by hand and compiled by sass either manually or as part of the build process.
They get hard to manage because they're separate from the content they're describing.

**Inline** allows you to define styles anywhere in your code!

Pass a CSS string to `inline\css(str)` and it returns a uniquely-named class.

The class selector and attributes will be appended to the head of the layout after your Widgets render,
so you can pass the class name around and use it anywhere!

## Quick Start
### Install
```
luarocks install inline
```

### Add to layout
1. Require the module
```moonscript
inline = require "inline"
```

2. Add this line to the head of your layout:
```moonscript
style inline\stylesheet!
```

### Use in Widgets
1. Import the css function
```moonscript
css = (require "inline")\css
```

2. Use `css(str)` to make a new class
```moonscript
myClass = css "
  display: flex; 
  flex-direction: column;
  justify-content: center;
  background-color: grey;
"
```

3. Apply the class to DOM elements
```moonscript
class MyWidget extends Widget
  content: =>
    div class: myClass
```

## Example

This example renders a 100x100px red square.

`views/inline_layout.moon`
```moonscript
import Widget from require "lapis.html"
-- Import inline
inline = require "inline"

class InlineLayout extends Widget
  content: =>
    html_5 ->
      head ->
        -- Just add this line!
        style inline\stylesheet!
      body ->
        @content_for "inner"
```
`views/red_square.moon`
```moonscript
import Widget from require "lapis.html"
-- Import inline
inline = require "inline"

-- Create a class outside of the Widget
redSquareClass = inline\css "width: 100px; height: 100px; background-color: red"

class RedSquare extends Widget
  content: =>
    -- Use myClass inside the Widget
    div class: redSquareClass
```
`app.moon`
```moonscript
lapis = require "lapis"

class extends lapis.Application
  -- Be sure to use your custom layout
  layout: "inline_layout"

  "/": =>
    -- Render a Widget
    render: "red_square"
```
