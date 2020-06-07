require "help"
local markdown = require"lunamark.parser.markdown"
local map = (require "lunamark.util").map
local format = string.format

-- lunamark Writer for troff mdoc macro package
local function writer(parser, options)
  local escape = function(s)
    local escape_char = function(c)
      return format("\\&%s", c)
    end
    return (string.gsub(s, "[%+%-/%*%%<>=&`'\"]", escape_char))
  end
  local spliton1 = function(s)
    local t = {}
    for m in string.gmatch(s, "([^\001]+)") do
      t[#t + 1] =  m
    end
    return t
  end
  local listitem = function(c)
    return {".It\n", map(parser(writer, options), spliton1(c)), "\n"}
  end
  local list = {
    tight = function(items)
      return map(listitem, items)
    end,
    loose = function(items)
      return map(function(c) return listitem(format("%s\n\n", c)) end,
          items)
    end
  }
  return {
    rawhtml = function(c) return "" end,
    linebreak = function() return ".Pp\n" end,
    str = escape,
    entity = function(c) return "?" end,
    space = function() return " " end,
    code = function(c) return {"\\fI", c, "\\fP"} end,
    emph = function(c) return {"\\fB", c, "\\fP"} end,
    strong = function(c) return {"\\fB", c, "\\fP"} end,
    heading = function(lev, c)
      return {lev > 1 and ".Ss " or ".Sh ", c, "\n"}
    end,
    blockquote = function(c)
      return {
        ".Bd -offset left\n",
        parser(writer, options)(table.concat(c, "\n")),
        ".Ed\n"
      }
    end,
    verbatim = function(c)
      return {
        ".Bd -offset left\n",
        escape(table.concat(c, "")),
        ".Ed\n"
      }
    end,
    bulletlist = {
      tight = function(c)
        return {".Bl -bullet -offset left\n", list.tight(c), ".El\n"}
      end,
      loose = function(c)
        return {".Bl -bullet -offset left\n", list.loose(c), ".El\n"}
      end
    },
    orderedlist = {
      tight = function(c)
        return {".Bl -enum -offset left\n", list.tight(c), ".El\n"}
      end,
      loose = function(c)
        return {".Bl -enum -offset left\n", list.loose(c), ".El\n"}
      end
    },
    para = function(c) return {c, "\n"} end,
    plain = function(c) return c end,
    hrule = function() return "" end,
    -- TODO
    link = function(lab,src,tit) return {} end,
    image = function(lab,src,tit) return {} end,
    email_link = function(addr) return {} end,
    reference = function(lab,src,tit)
      return {
        key = lab.raw,
        label = lab.inlines,
        source = src,
        title = tit
      }
    end
  }
end

-- pager
local converter = markdown.parser(writer)
local header = ".Dd\n.Dt LuaHelp\n.Os Lua\n"
help.print = function(s)
  local f = io.popen("groff -Tascii -mdoc | less", "w")
  f:write(header .. converter(s))
  f:close()
end

