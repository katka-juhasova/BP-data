--- ihelp.lua (c) Dirk Laurie 2013, Lua-style MIT license
-- Lua interactive help. 
--
-- To get started:
--
-- $ lua -e "help = require'ihelp'"
-- help()

do 
local       getinfo,    open,       insert,       concat,       sort =
      debug.getinfo, io.open, table.insert, table.concat, table.sort 
local pairs, select, type = pairs, select, type
local utf8len, offset = utf8 and utf8.len, utf8 and utf8.offset
if not offset then offset = function(...) return ... end end

-- sample shorthelp and longhelp
local shorthelp = [[

The following functions are provided:
   help
Try `help"topic"`, e.g. help"all", or `help(function)`, e.g. `help(help)`.
]]

local longhelp = {
method = [[

`debug.getinfo(fct).source` contains the Lua source code of `fct`,
or the name of the file from which it was loaded, or the information
that it is precompiled C code. If the actual source is available,
a docstring (see `help"docstring"`) is extracted.
]],
bugs = [[

If the source code is read from a file that you are editing, the
version from which the docstring is extracted may be more recent
than the version you have loaded.
]],
docstring = [[
---    The docstring of a function
-- A comment block from the Lua code of a function, formatted in LDoc
-- style, like this block. The comments may come immediately before the 
-- first line of the function or anywhere inside it.  All comments must 
-- start at position 1 of their lines and the first comment must start 
-- with at least three hyphens. For a very short function, the whole 
-- code is used as the docstring. 
--
-- Not available for functions defined from the terminal while running 
-- the standalone Lua interpreter.
]],
customize = [[

After `help(arg,msg)`, where `arg` is nil or any string except `all`, 
the message you get when typing `help(arg)` will be `msg`.
]]
}
local helpless = "No help available, try help(%s)."
--

------------------ no changes needed after this line ------------------

local docstring_pattern = "(\n%-%-%-.-\n)[^%-]"
local starts_with_two_hyphens = "^%-%-"
local starts_with_three_hyphens = "^%-%-%-"
local only_hyphens_at_least_three = "^%-%-(%-)+$"
local nohelp = "No help available"
local code={}
local shortenough = 12 -- number of lines in longest self-documenting routine

local docstring = function(fct)
---   docstring(fct)
-- Extracts an LDoc-styled comment block from the Lua code of a function, 
-- for example this block. The comments may come immediately before the
-- first line of the function or anywhere inside it.  All comments must 
-- start at position 1 of their lines and the first comment must start 
-- with at least three hyphens.
   local getinfo = debug.getinfo
   local helptext
   if getinfo and getinfo(fct) then
      local info=getinfo(fct)
      local source=info.source
      helptext = source:match(docstring_pattern)
      if not helptext then
         if source:match"%=%[C%]" then return "Precompiled C function"      
         elseif source:match"%=stdin" then return "Defined above"
         elseif source:match'%@(.+)' then  -- source filename provided
            local filename=source:match'%@(.+)'
            local sourcefile = io.open(filename)
            if not code[filename] then  -- memoize source code
               local c={}
               for k in sourcefile:lines() do c[#c+1]=k end
               code[filename]=c
            end
            local fcode=code[filename]
            helptext={}
            local start, stop = info.linedefined, info.lastlinedefined
            local k=start-1  -- first try the preceding comment block
            while fcode[k]:match(starts_with_two_hyphens) do 
               if fcode[k]:match(only_hyphens_at_least_three) then break end
               insert(helptext,1,fcode[k]) 
               if fcode[k]:match(starts_with_three_hyphens) then break end
               k=k-1
               if k==0 then break end
            end
            if #helptext>0 then helptext=concat(helptext,'\n')
            else  -- try function body
               for k=start,stop do
                  helptext[#helptext+1] = fcode[k]
               end
               fcode = helptext
               if #helptext>0 then 
                  helptext=concat(helptext,'\n')
                  helptext = helptext and helptext:match(docstring_pattern)
               else helptext=nil
               end 
               -- last resort: full code if it is short enough
               if not helptext and (#fcode<=shortenough) then 
                  helptext=concat(fcode,'\n') 
               end
            end
         end
      end
   end 
   return helptext 
end

-- assumes validity of UTF8 encoding
local utflen = utf8len or 
   function (s) return #s:gsub("[\192-\239][\128-\191]*",'.') end

local fold
fold = function(s)
--- Primitive word-wrap function. 
  if utflen(s)<=72 then return s end
  local n=72
  local l
  while n>60 do n=n-1
     l=offset(s,n)
     if s:find("^%s",l) then break end 
  end
  return s:sub(1,l-1)..'\n    '..fold(s:sub(l+1))
end  

local topics = function (tbl,prefix)
   local t={}
   for k in pairs(tbl) do if type(k)=='string' then 
      t[#t+1]=(prefix or '')..k
   end end  
   sort(t)
   return concat(t,' ')
end

local help = function(fct,...)
---    help(), help(arg), help(arg1,arg2)
-- help(): Prints short help. 
-- help(function): Prints the docstring of `arg`, if any.
-- help(table): Prints `help` field, if any; else contents.
-- help(string): Prints help on the topic, if any.
-- help"all": Prints available topics.
-- help(topic,false): Removes topic from "all"
-- help(arg1,"newhelp"): Redefines what you will get from `help(arg1)`
-- help(arg1,0), help(arg1,nil) (or any second argument except `false` 
--     or a string): don't print help, return it as a string instead 
   if select('#',...)>1 then 
      print('Too many arguments: try `help(help)`'); return
   end
   local helptext
   local redefine = select('#',...)==1 and type(select(1,...))=='string'
   local kill = select(1,...)==false
   local printme = select('#',...)==0
   if kill then longhelp[fct]=nil
   elseif fct==nil then 
      if redefine then shorthelp=... else helptext=shorthelp end
   elseif fct=='all' then
      if redefine then print"help cannot be redefined for 'all'"; return
      else helptext='Help available via `help"topic"` on these topics:\n  '..
         fold(topics(longhelp))
      end
   elseif redefine then longhelp[fct]=...
   elseif longhelp[fct] then helptext=longhelp[fct]
   elseif type(fct)=="table" then 
      if type(fct.help)=='string' then helptext=fct.help
      else helptext=fold("Contents: "..topics(fct))
      end
   elseif type(fct)=='function' then helptext=docstring(fct) or nohelp
   else print(helpless:format(fct)); return
   end
   if printme then print(helptext) else return helptext end
end 

return help

end   
