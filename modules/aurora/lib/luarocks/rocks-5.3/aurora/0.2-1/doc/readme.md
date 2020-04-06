# AURORA

A Lua function library to fill your tool set.

* On demand method loader
* Missing Lua functions implemented from other languages
* Some abstraction over tiny and very useful 3rd party code

## Basics

### On Demand method loader

On `your/awful/proj/init.lua` put just this:

```Lua
	require('lunar')
	ondemand('my.awful.proj')
```

And just create a bunch of files inside `your/awful/proj` folder,
like... hmmm... `implode.lua`

```Lua
	return function(t,glue) 
		return table.concat(t,glue)
	end
```
Now, in your works you just `require "your.awful.proj"` and use
any of the files inside your `proj` folder, like this:

```Lua
	local p = require("your.awful.proj")
	p.concat({'just this'},'-')
```


## Templating

Templating system is prepared for use with Lua 5.3.3. Can handle different
instances with different configurations, and with a sandboxed environment
to control what can be accomplished from inside template.

```Lua
local t = require('lunar.template'):new({
	conf = {
		cache = true, -- stores compiled templates,
		compilePath = './cached/', -- where find compiled ones,
		templatePath = './tpl/', -- where find templates,
	}
})

local html = t:render('index.html', { t = "title", c="content" })
print html;

```

Example index.html
```HTML
<h1>{%= t %}</h1>
{% if c then %}
	<p>{%= c %}</p>
{% end %}
<footer>{%include: footer.html %}</footer>

```


# 3rd party credit

Below, a list with 3rd party snippets mixed in Aurora code.
Some of these were changed and adapted.

* Template: build upon SLT (https://github.com/henix/slt2)
* HTTP Server: using Pegasus
