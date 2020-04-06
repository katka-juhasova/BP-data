-------------------------------------------------------------------------------
-- includes a get function that read any ini file into table
--
-- @author Alexandr Leykin (leykina@gmail.com)
--
-- @Public domain 2008-2011
-- @release $Id: inilazy.lua,v 1.05 2011/08/17 11:57:11 $
-------------------------------------------------------------------------------
--bugfix: mutikey files (thanks smz!) 
--bugfix: error proccessing, mutilkey behavior (thanks Daniel Hertrich!)

--[[
inilazy parse two ways:

old behavior (param: string filname)
without multikey(section have unique key name):
=============================
require"inilazy"
ini_table = inilazy.get('big.ini')
for k,v in pairs(ini_table['some_section']) do
  print(k,'--',v) 
end
=============================

and new behavior (param: string filname, multikey_flag)
with multikey(section have many key with same name):
=============================
require"inilazy"
ini_table = inilazy.get('big.ini', true)
for k,v in pairs(ini_table['some_section']['key_name']) do
  print(k) --!!!values in keys
end
=============================
...
--]]

local io = require"io"
local string = require"string"
local table = require"table"
local pairs, ipairs = pairs, ipairs

module ("inilazy")

function get(filename, multikey_flag) --> (ini_table) or (nil,err)
  local f = io.open(filename,'r')
  if not f then return nil, "Error can't open file: " .. filename end
  local line_counter=0
  local ini_table = {}
  local section, err
  for fline in f:lines() do
    --set counter for indicate on error
    line_counter=line_counter+1
    --clean for begin and end spaces
    local line = fline:match("^%s*(.-)%s*$")
    --coments
    if not line:match("^[%;#]") and #line > 0 then
      --section
      local sec = line:match("^%[([%w%s]*)%]$")
      if sec then
        section = sec
        if not ini_table[section] then ini_table[section]={} end
      else
        --parse key=value and clean for begin and end spaces
        local key, value = line:match("([^=]*)%=(.*)")
        --check on errors in ini-file
        if not key then return nil,'Error key absent in file:'.. filename..':'.. line_counter.."\n line:"..fline end
        --clean for begin and end spaces
        key = key:match("^%s*(%S*)%s*$")
        value = value:match("^%s*(.-)%s*$")
        if not (key and value) then return nil,'Error bad key or value in file:'.. filename..':'.. line_counter.."\n line:".. fline end
        if section then
          if not ini_table[section][key] then ini_table[section][key]={} end
          if multikey_flag then ini_table[section][key][value] = true else ini_table[section][key] = value end
            
        else
          return nil,'Error key/value outside a section in file:'.. filename..':'.. line_counter.."\n line:".. fline
        end
      end
    end
  end
  f:close()
  return ini_table
end


function set (ini_table, filename)
  f = io.open(filename,'w')
  if not f then return nil, "cannot open file: " .. filename end
  f:write('; Created by inilazy (http://luaforge.net/projects/inilazy/)\n\n')
  for secname, sec in pairs(ini_table) do
    f:write("[", secname, "]\n")
    for keyname, key in pairs(sec) do
      for value, _ in pairs(key) do
        f:write(keyname, "=", value, "\n")
      end
    end
    f:write "\n"
  end
  f:close()
  return true
end

