pash
====

*pash* is a text processor that allows lua to be executed in 
the context of page generation. Developed as a static website 
generator that uses [templet](https://colberg.org/lua-templet) for templating.

*pash* adds execution of `_context.pash` to the environment 
when processing the contents of a directory (and child directories inherit
the environment of their parents).

Files and directories that begin with `_` or `.` are ignored.

She understands two kinds of tags inside source files :

Code
----
Starting a line with the **|** character indicates that what follows is lua code
``` lua
| for i = 1,5 do
  <br />
| end
```
  
Value
-----
When the **${...}** is encountered in a source file the results of the code within elipses is inserted into the source 
``` lua
| for i = 1,5 do %]
  <li>Item ${ i }</li>
| end
```
    
There is one built-in function provided:

``` lua
  ${ include( '_snippet/menu.html' ) }
```
      
*pash* could certainly process any filetype but we usually have her
chew on HTML, CSS and JS template files.
      
A common need when using pash as a static site generator
is the use of a _layout_ inside which to embed the
content of a page. Specifying a layout can be done in a `_context.pash`
file so that all pages in that directory and any of its child directories 
use a particular layout. Specifying the layout template can of course
also be done inside the page itself.
      
```lua
page.layout = '_layout/site.html'
```
      
**avoid** doing something like the following :
```lua
page = { layout = '_layout/site.html' }
```
because you will be clobbering the page table contents created elsewhere.
      
When specifying a layout the page is rendered to the variable `page.content`.
      
So with a layout like this :
      
```
_layouts/
  site.html
_snippets/
  menu.html
_context.pash
index.html
```
          
we could have :
```
--- _context.pash
page.layout = '_layout/site.html'

          
--- _layout/site.html
<html>
  <head>
    <title>${ page.title }</title>
  </head>
  <body>
${ page.content }
  </body>
</html>
              
              
--- index.html
| page.title = 'The truth about Pashlicks'
              
Pashlicks loves her sisters Josie and Marmite
```
              
to produce an index.html file containing :
```html
<html>
  <head>
    <title>The truth about Pashlicks</title>
  </head>
  <body>

Pashlicks loves her sisters Josie and Marmite
  </body>
</html>

```

Every page has some *special* variables availabe in its environment:

```lua
page.file      -- filename of file being processed
page.directory -- directory of the file being processed
page.path      -- path to file from root of site
page.level     -- level in the tree at which this page sits

site.tree      -- tree of site

pash           -- a lua table available for user data and functions
```
                
Calling pash should be as simple as :

```bash
pash <src> <dest>
```
