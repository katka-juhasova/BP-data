--[[
  Simple help system for Lua modules

  Author: Julio M. Fernandez-Diaz
  Date:   Feb, 2010
  (For Lua 5.1)

  It is not intended to be complete, instead to be `enough'.

  Error messages are displayed in stderr
--]]

-- Change the name of this file for other name if you wish
-- other name for querying help
local NAME = ...

module(NAME, package.seeall)

-- saving global names  -------------------------------------------

local format, rep, gsub, sub = string.format, string.rep, string.gsub, string.sub
local find, char, byte, setlocale = string.find, string.char, string.byte, os.setlocale
local type, io, os, table, ipairs, pairs = type, io, os, table, ipairs, pairs
local _G, setmetatable, require, pcall, error = _G, setmetatable, require, pcall, error
local print = print

-- default css if not provided
local CSS = [[
<style type="text/css">
body {
   font-family: Verdana, Helvetica, Arial, sans-serif;
   font-size: 11pt; color: black; background-color: #fbfbfb;
}
#content {
   top: 120px; margin-left: 225px;
}
#navigate {
   position: fixed; top: 10px; width: 210px; float: left;
	padding: 0 0 0 5px; background-color: #e6e6f2; line-height: 170%;
}
#navigate h1 {
   font-size: large; text-align: left;  
}
#navigate ul {
	margin-left: 5px; padding-left: 10px;
}
#navigate ul ul {
   font-size: 10pt; margin-left: 5px; padding-left: 10px; line-height: 130%;
}
#navigate ul ul ul {
   font-size: 90%; margin-left: 5px; padding-left: 10px; line-height: 110%;
}
#navigate a:link {
	color: #000099; text-decoration: none;
}
#navigate a:visited {
	color: #000099; text-decoration: none;
}
#navigate a:hover {
   color: #996633; text-decoration: none;
}
h1 {
   text-align: center; color: #000000; width: auto;
}
h2 {
   color: #006600; background-color: #ccffff; padding: 10px;
}
h3 {
   color: #000099; background-color: #ffffcc; padding: 5px;
}
h4 {
   font-size: normal; color: #990099;
}
h5 {
   border-top: 1px solid; font-size: medium; color: #990000;
}
h6 {
   font-size: medium; font-style: italic;
}
a:hover {
   color: #996633;
}
p.listoffun {
   word-spacing: 2em;
}
pre {
   font-size: 90%; border: 1px dotted #888888;
   background-color: #f9f9f9; padding: 5pt;
}
code {
   font-size: 95%; color: #006666;
}
var {
   color: #008040; font-style: italic; font-weight: normal;
}
</style>]]

-- private functions    -------------------------------------------

-- returns "utf-8" if detected, nil otherwise
local function detectutf8 ()
   local c = setlocale(nil, "ctype"):lower()
   local e = c:find("utf-8", 1, true) or c:find("utf8", 1, true)
   return e and "utf-8"
end

-- convert utf8 to iso
-- http://lua-users.org/lists/lua-l/2003-10/msg00281.html
local function utf8toiso (s)
   if s:find("[\224-\255]") then error("non-ISO char") end
   s = s:gsub("([\192-\223])(.)", function (c1, c2)
         c1 = byte(c1) - 192
         c2 = byte(c2) - 128
         return char(c1 * 64 + c2)
       end)
   return s
end

-- convert iso to utf8
-- the inverse of
-- http://lua-users.org/lists/lua-l/2003-10/msg00281.html
local function isotoutf8 (s)
   s = s:gsub("([\128-\255])", function (c)
         local b = c:byte()
         return b < 192 and "\194"..c or "\195"..char(b-64)
       end)
   return s
end

-- convert iso-8859 <-> utf-8
local function convertcs (s, cs, uft8)
	if cs == "utf-8" and not utf8 then -- convert to iso
 		return utf8toiso(s)     
   elseif cs ~= "utf-8" and utf8 then -- convert to utf-8
 		return isotoutf8(s)     
   end
	return s
end

-- for formatted writing in a file
local function fprintf (filehandler, fmt, ...)
   filehandler:write(format(fmt, ...))
end

-- print a line of s with n characters in stderr
local function line (s, n)
   n = n or 72
   io.stderr:write(rep(s, n).."\n")
end

-- Prints the file with name filename in the filehandler
local function printcss (filehandler, filename)
   local data
   local f = io.open(filename, "rb")
   if f == nil then
     data = CSS 
   else
     data = f:read("*all")
     f:close()
   end
   filehandler:write(data)
end

-- extract parts in what, by separating
-- [/][spath]^[info]
local function parts (what)
   local absol, spath, info = ""

   if what == nil then return nil end

   what = what:gsub("%s", "")   -- delete blanks
   what = what:gsub("[%.]+", ".")   -- collapse multiple .

   if what:sub(1,1) == "/" then  -- search initial /
      absol = "/"
      what = what:sub(2)
   end

   -- split parts
   -- if more than one "^" appears only the last part is info
   what:gsub("%^", "&")
   what:gsub("^([^&]*)^([^&]*)$", function (w1, w2) spath, info = w1, w2 end)
   if spath == nil then spath, info = what, "" 
   else
      spath:gsub("&", "%^")
      info:gsub("&", "%^")
   end

   -- delete possible initial and final .
   if spath:sub(1,1) == "." then spath = spath:sub(2) end
   if spath:sub(-1) == "." then spath = spath:sub(1,-2) end

   return absol, spath, info
end

-- split a string in fields separated by "."
local function splitdot (s)
   local t = {}
   s:gsub('([^%.]+)(%.*)', function (w, d) t[#t+1] = w end)
   return t
end

-- private variables    -------------------------------------------

local Cases = {"Basic information", "List of functions", "Usage of ",
               "More specific information", "See also", "Examples",
               "Description of functions", "Version", "Notes"}
local cases = {"basic", "list", "usage", "more", "seealso", "example",
               "description", "version", "notes",
              }
local order = {b = 1, l = 2, u = 3, m = 4, s = 5, 
               e = 6, d = 7, v = 8, n = 9} -- order for "all"

local basis = NAME


-- public objects       -------------------------------------------

_H = {
_CHARSET = "iso-8859-15",    -- "utf-8" in other cases
_basic = '`'..NAME..[[` is a system that provides help for modules.

It searches eight types of information:

    basic   list   usage   more   seealso   example   version   notes

Execute `]]..NAME..'"/'..NAME..'^usage"` and `'..NAME..'"/'..NAME..
[[^more"` for more explanation.

Apart from this, documentation in `html` format can 
be generated (see `]]..NAME..'.doc`).',
_usage = '`'..NAME..[[(search)`

@params:

1. `search` is a string in the form `"what^kind"` (a caret
   separates two parts of the argument).

@returns: nothing.

@effects: it prints in `io.stderr`.

`what` is what are looking for; if the first character in it is `/`
an *absolute* path is searched; if not the string defined in `]]..
NAME..[[.base` is used as a basis;

`kind` is the type of information we want, that can be:

    "basic"   | "list"    | "usage"   | "more"   | "seealso"
    "b"       | "l"       | "u"       | "m"      | "s"

    "example" | "version" | "notes"   | "all"  
    "e"       | "v"       | "n"       | "a"

(as we see, we can use only the first letter).
If `all` is requested then all information
(basic, list, usage, seealso, example, version, notes) *if exists* is given.
If no kind is provided (in this case the caret is optional) `"basic"` is assumed.

`]]..NAME..[[(nil)` and `]]..NAME..[[.about(nil)` are equivalent to
`]]..NAME..'"/'..NAME..[[^basic"`, that is, help about this helping system
is given.]],
_more = [[The search of information is controlled by two strings:
`what` and `kind`. Both are typed separated by a caret, `"^"`.

The first, `what`, is what we are searching. Normally this
is a sequence `name1[.name2[.name3 ...] ]` in which `name1` is a module
name, and `name2`, `name3`, ... indicate functions in the module or
tables with functions in the module.

If `what` begins with a slash, `/`, then an absolute path is searched.
Otherwise the help system adds as a prefix the string stored in a local
variable assigned with the function `]]..NAME..[[.base`. This improves the
interactivity because the user is not enforced to always type the
complete path of help.

The second, `kind`, is the type of information we want:

+ `basic`:    the purpose of the module or function inside a module,
+ `list`:     the listing of functions in the module,
+ `usage`:    the use of a function, describing the arguments and returns,
+ `more`:     more specific information,
+ `seealso`:  some related information,
+ `example`:  an example of use,
+ `version`:  information about version and author,
+ `notes`:    other information, usually license one,

+ `all`:      show all the previous information.

For activate the help system the user (interactively) or some module
should invoke

     require"]]..NAME..[["

**Note**: the present help system manages a module variable `_H`.
This means that `_H` cannot be used for other purposes in
the module.]],
_example = [[Some examples (with equivalences):

We assume the *first* invoking after `require"]]..NAME..[["` (by the user
or by some module):

    ]]..NAME..[[""                   --><--    ]]..NAME..[["/]]..NAME..[[^basic"
    ]]..NAME..[["^a"                 --><--    ]]..NAME..[["/]]..NAME..[[^all"
    ]]..NAME..[["/somemodule.fun^u"  --><--    ]]..NAME..[["/somemodule.fun^usage"
    
    ]]..NAME..[[.base"somemodule"    -- changes basis for searching
    
    ]]..NAME..[["^l"                 --><--    ]]..NAME..[["/somemodule^list"
    ]]..NAME..[["fun^u"              --><--    ]]..NAME..[["/somemodule.fun^usage"
    ]]..NAME..[["/]]..NAME..[[^m"             --><--    ]]..NAME..[["/]]..NAME..[[^more"]],
_Name = NAME,
_version = [[by Julio M. Fernández-Díaz, Dept. of Physics,
University of Oviedo, Spain, Version 0.1, February 2010

julio a t uniovi d o t es]],
_notes = [[THIS CODE IS HEREBY PLACED IN PUBLIC DOMAIN.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR
OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.]]
}

_H.about = {
_basic = [[Main function for on line help (synonym of `]]..NAME..[[`)]],
_usage = '`'..NAME..[[.about(search)`


`]]..NAME..[[(search)`

@params:

1. `search` is a string in the form `"what^kind"` (a caret
   separates two parts of the argument).

@returns: nothing.

@effects: it prints in `io.stderr`.

`what` is what are looking for; if the first character in it is `/`
an *absolute* path is searched; if not the string defined through
`]]..NAME..[[.base` is used as a basis;

`kind` is the type of information we want, that can be:

    "basic"   | "list"    | "usage"   | "more"   | "seealso"
    "b"       | "l"       | "u"       | "m"      | "s"

    "example" | "version" | "notes"   | "all"  
    "e"       | "v"       | "n"       | "a"

(as we can see we can use only the first letter).
If `all` is requested then all information,
(basic, list, usage, seealso, example, version, notes) *if exists* is given.
If no kind is provided `"basic"` is assumed.

Spaces typed by the user in the set `what^kind` are deleted before
the search of the help. Also, multiple `"."` are collapsed.

`]]..NAME..[[(nil)` and `]]..NAME..[[.about(nil)` are equivalent to
`]]..NAME..'"/'..NAME..[[^basic"`, that is, help about this helping system
is given.]],
}

function about (what)
   what = what or "/"..NAME.."^basic"
   if what == "" then what = "/"..basis.."^basic" end

   local absol, spath, info = parts(what)

   if absol ~= "/" then
     if spath ~= "" then spath = basis.."."..spath
     else spath = basis end
   end
   if info == "" then info = "basic" end

   local ts = splitdot(spath)
   table.insert(ts, 2, "_H")

   if #info == 1 then
      if info == "a" then info = "all" 
      elseif order[info] then info = cases[order[info]] end
   end

   local tt = {info}
   if info == "all" then
      for k, v in ipairs(cases) do tt[k] = v end
   end

   local H = _G
   local CHARSET = H[ts[1]][ts[2]]["_CHARSET"]
   local UTF8    = detectutf8()

   for k = 1, #ts do
      if H then H = H[ts[k]] end
   end
   if H == nil and info ~= "list" then
      io.stderr:write("No information about '/"..spath.."^"..info.."'\n")
      io.stderr:flush()
      return
   end

   if info == "list" then tt = {"list"} end

   local function fill (t)
      local pH = ""
      local nc, ic, lef = 3, 1, 25

      for j, s in ipairs(t) do
         pH = pH..s..(" "):rep(lef-#s)
         if ic == nc then pH = pH.."\n" end
         ic = ic+1
         if ic > nc then ic = 1 end
      end
      return pH.."\n"
   end

   for k, v in ipairs(tt) do
      local H1, pH = H["_"..v], ""
      if v == "list" then
         -- special case : list
     		local al = {}
     		for a in pairs(H) do
   			if a:sub(1,1) ~= "_" then al[#al+1] = a end
	     	end
      	if #al > 0 then 
            table.sort(al)
            io.stderr:write(">>>>>>>>>>   "..spath..":"..v.."   <<<<<<<<<<\n")
	   		pH = 'List of functions in "'..spath..'":\n\n'..fill(al)
            io.stderr:write(pH)
            line("-")
         end
      elseif H1 and type(H1) ~= "table" then
         io.stderr:write(">>>>>>>>>>   "..spath.." ^ "..v.."   <<<<<<<<<<\n")
         H1 = convertcs(H1, CHARSET, UTF8)
         io.stderr:write(pH..H1.."\n")
         line("-")
      elseif info ~= "all" then
         io.stderr:write(">>No information about '/"..spath.." ^ "..info.."'\n")
      end
   end

   io.stderr:flush()
end

_H.base = {
_basic = [[Establishes a *basis prefix* for help searching]],
_usage = [[`]]..NAME..[[.base(basis)`

@params:

1. `basis`, string.

@returns: nothing.

This function changes the `basis` (a string) to add as a prefix in the
desired information path when this does not begin with a slash, `/`.

When providind `basis` the slashdot `"/"` is not required.

Initially basis has the value `"]]..NAME..[["` but the loading of a module
sets the current `basis` to the module name.

When calling `]]..NAME..[[.base""` the current basis is displayed.

Calling `]]..NAME..[[.base(nil)` establishes `"]]..NAME..[["` as basis.]]
}

function base (b)
   if b == nil or type(b) ~= "string" then b = NAME end
   if b~= "" then
      if b:sub(1,1) == "/" then b = b:sub(2) end
      basis, now = b
      io.stderr:write('--> Changing help basis to "'..basis..'"\n')
   else
      io.stderr:write('--> Help basis is "'..basis..'"\n')
   end
end

_H.doc = {
_basic = [[Create `html` documentation for a module]],
_usage = [[`]]..NAME..[[.doc(modulename, filename)`

@params: 

1. `modulename`: string (optional) is the name of the module
   of which we want the documentation.
   If not provided then the basis is used.
2. `filename`: string (optional) is the name of the output file,
   in `html` format. If not given the name of the module is used.
   If one of the extensions `".html"` or `".htm"` (in lowercase) is
   not provided then automatically `".html"` is added to the filename.

@returns: nothing

@effects: it creates a file.

For generating the documentation module
[markdown.lua](http://www.frykholm.se/programming.html) from Niklas Frykholm
must be accessible. 
(Note: the version in [luaforge.net](http://luaforge.net) is obsolete.)]],
_more = [[A CSS file called `default.css`, which is possible
to customize, is used. This file is embeded in the `html` output file.
If not provided the system uses an internal style.

The resulting `html` file can be converted, v.g., to PS
with [html2ps](http://user.it.uu.se/~jan/html2ps.html), from Jan Kärrman.
After that `ps2pdf` can be used to convert it to PDF format.]],
}

function doc (name, filename)
   if type(name) ~= "string" then
      io.stderr:write("A name of a module must be given\n")
      return
   end

   if name == "" then name = basis end
   if _G[name] == nil then
      io.stderr:write("Module "..name.." not found\n")
      return
   end

   local gn = _G[name]
   if gn._H == nil then
      io.stderr:write("Module "..name.." has no help information\n")
      return
   end
   name = gn._H._Name
   local CHARSET = gn._H._CHARSET

   filename = filename or name
   if type(filename) ~= "string" then
      io.stderr:write("A filename for output must be given\n")
      return
   end

   -- check for .html or .htm extension in filename
   if filename:sub(-5) ~= ".html" and filename:sub(-4) ~= ".htm" then
      filename = filename..".html"
   end

   local f = io.open(filename, "w")
   if f == nil then
      io.stderr:write('"'..filename..' cannot be created\n')
      return
   end

   local md, markdown = pcall(require, "markdown")
   if not md then
      io.stderr:write("Markdown not found. No conversion is applied\n")
      markdown = function (s) return s end
   end

   local cart = {}

   gn = gn._H

   local function pref (s)
      return '<a href="#'..s..'">'..s..'</a>'
   end

   local function listfun (gn)
      -- prepare an alphabetical list of (sub)functions
      local al = {}
      for a in pairs(gn) do
   		if a:sub(1,1) ~= "_" then al[#al+1] = {name = a} end
      end
      if #al > 0 then 
         table.sort(al, function (a, b) return a.name < b.name end)
      end
      for i, a in ipairs(al) do
    		local d = gn[a.name]
         if d then
            local b = listfun(d)
            if #b > 0 then al[i][1] = b end
         end
      end
   	return al
   end

   local allfun = listfun(gn)

   local function showlist (allfun, prev)
		local cart = ""
		for i, a in ipairs(allfun) do
         local pr = prev == "" and "" or prev.."_"
			cart = cart..'<li>'..'<a href="#'..pr..a.name..'">'..a.name..'</a>'
         if #a > 0 then
            cart = cart.."\n<ul>"..showlist(a[1], a.name).."\n</ul>"
         end
         cart = cart..'</li>\n'
      end
      return cart
   end

   local function navigate (gn, level, allfun)
     	-- check in order _-beginning fields
      for i, c in ipairs(cases) do
   		local d = gn["_"..c]
         local Ca = Cases[i]
       	if cases[i] == "usage" then
            Ca = Ca..(level == 2 and "the module" or "function")
         end
         if d or c == "list" then
   			cart[#cart+1] = "<li>"..'<a href="#'..c..'">'..Ca.."</a></li>\n"
         end
         if c == "description" then 
   		   if #allfun > 0 then
      			cart[#cart+1] = "<li>"..'<a href="#'..c..'">'..Ca.."</a>\n"
   				cart[#cart+1] = '<ul>\n'
   				cart[#cart+1] = showlist(allfun, "")
   				cart[#cart+1] = '</ul></li>\n'
     			end
      	end
      end
   end

   -- navigation menu

   cart[#cart+1] = '<div class="noprint" id="navigate">\n'
   cart[#cart+1] = '<h1>Module <code>'..name..'</code></h1>\n\n'
   cart[#cart+1] = '<ul>\n'

   navigate(gn, 2, allfun)

   cart[#cart+1] = '</ul></div>\n'

   -- main part

   local function inside (gn, level, previous)
      -- prepare an alphabetical list of (sub)functions
      local al = {}
      for a in pairs(gn) do
   		if a:sub(1,1) ~= "_" then al[#al+1] = a end
      end
      if #al > 0 then table.sort(al) end
   
     	-- check in order _-beginning fields
      for i, c in ipairs(cases) do
   		local d = gn["_"..c]
         local Ca = Cases[i]
       	if cases[i] == "usage" then
            Ca = Ca..(level == 2 and "the module" or "function")
         end
         local pH = "\n"
         if c == "list" and #al > 0 then
            local ts = splitdot(previous)
            table.remove(ts, 1)
            local s = table.concat(ts, "_")
            if #s > 0 then s = s.."_" end
            pH = pH..'<p class="listoffun">\n'
            for j, fun in ipairs(al) do
               pH = pH..'<a href="#'..s..fun..'">'..fun..'</a>\n'
            end
            pH = pH.."</p>\n\n"
				local cc = level == 2 and ' id ="'..c..'"' or ""
   			cart[#cart+1] = '\n<h'..level..cc..'>'..Ca..'</h'..level..'>\n'
            cart[#cart+1] = pH
            cart[#cart+1] = "\n"
         end
         if c == "description" and #al > 0 then
           table.sort(al)
   		  cart[#cart+1] = '\n<h'..level..
                           ' id = "description">Description of functions</h'..
                           level..'>\n\n'
           local level1 = level+1
           for i, a in ipairs(al) do
              local pre = previous == "" and a or previous.."."..a 
              local ts = splitdot(pre)
              table.remove(ts, 1)
              local s = table.concat(ts, "_")
     	        cart[#cart+1] = '<h'..level1..' id="'..s..
                              '">'..pre..'</h'..level1..'>\n'
          	  local d = gn[a]
              if d then inside(d, level1+1, pre) end
           end
         end
         if d then
				local cc = level == 2 and ' id ="'..c..'"' or ""
				--local cc = ' id ="'..c..'"'
   			cart[#cart+1] = '\n<h'..level..cc..'>'..Ca..'</h'..level..'>\n'
            cart[#cart+1] = pH..markdown(d)
            cart[#cart+1] = "\n"
         end
      end
   
   end

   cart[#cart+1] = '<div id="content">\n'
   cart[#cart+1] = "<h1>Module "..name.."</h1>\n"

   inside(gn, 2, name)

   cart[#cart+1] = '</div>\n'

   -- printing
   local s = table.concat(cart, "\n")


   local head = [[<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
<head>
   <meta http-equiv="content-type" content="text/html; charset=]]..CHARSET..[[" />
   <title>%s</title>]]
   local head1 = "\n</head> <body>\n"

   local foot = "\n</body></html>\n"
   
   fprintf(f, head, "Module "..name)

   -- embeding CSS file

   printcss(f, "default.css")

   f:write(head1)
   f:write(s)
   f:write(foot)
   
   f:close()
end

io.stderr:write('A help system is available. Call '..NAME..'(nil) for information.\n')

base(NAME)

__call = function (t, s, ...)
   if s == nil then
      about(nil)
   elseif type(s) == "string" then
      about(s)
   else
      return t[s](...)
   end
end

setmetatable(_G[NAME], _G[NAME])

