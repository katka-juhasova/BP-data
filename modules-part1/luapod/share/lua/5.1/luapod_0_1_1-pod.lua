module (..., package.seeall)

require "lpeg"

local lpeg = lpeg


--list of of commands currently recognized

local cmdPod = lpeg.P ("=pod")
local cmdCut = lpeg.P ("=cut")

local cmdHead1 = lpeg.P ("=head1")
local cmdHead2 = lpeg.P ("=head2")
local cmdHead3 = lpeg.P ("=head3")
local cmdHead4 = lpeg.P ("=head4")

local cmdOver = lpeg.P ("=over")
local cmdItem = lpeg.P ("=item")
local cmdBack = lpeg.P ("=back")

local cmdBegin = lpeg.P ("=begin")
local cmdEnd = lpeg.P ("=end")
local cmdFor = lpeg.P ("=for")


--indicates if you are generating HTML to be embedded into another HTML document
local embedded = nil

local doctype = [[ <!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN"
	"http://www.w3.org/TR/html4/strict.dtd">]]

local encoding = [[<meta http-equiv="Content-type" content="text/html;charset=ISO-8859-1">]]

local fileTitle = nil

--Declares the parsing function, because it is referenced before its definition 
local parsing = nil

--Keeps the formatting code tags, because they can be nested
local formatTable = {}


--The output variable
local out = nil


--Keeps the type of the "=begin =end" region (comment, html etc)
local formatNames = { }


--Indicates if the POD formatting rules should be used in the current region
local isFormatting = { true }


--When processing a paragraph inside a "=begin :" or "=for :" region,
--each line of the paragraph is read and saved in currentData until
--that all the paragraph is read
local currentData = { }


--Keeps the type of the current "=for" region, if it is an
--HTML or biblio region, for example
local currentFor = nil


--Keeps the number of the current "=head" command
local headNumber = 1

--Keeps the current link of a L code 
Llink = nil

--The base url that will be used to resolve links in L codes
local baseURL = "localhost"


local function Itag (t)
	if t then
        return "<i>"
	else
	    return "</i>"
	end
end

local function Btag (t)
	if t then
	    return "<strong>"
	else
	    return "</strong>"
	end
end

local function Ctag (t)
	if t then
	    return "<code>"
	else
	    return "</code>"
	end
end

local function Ltag (t)
	if t then
		return "<a href=\""
	else
		return "</a>"
	end
end

local function Ltagaux ()

	local s = Llink

	local space = lpeg.P (" ") + lpeg.P ("\t") + lpeg.P ("\n") + lpeg.P ("\f") + lpeg.P ("\r")
	
	--this match succeeds if the L tag contains an absolute url
	local html = lpeg.match (lpeg.C (lpeg.R ("AZ", "az", "09")^1 * ":" * (1 - (lpeg.P (":") + space)) * (1 - space)^0) * -1, s)
	if html then
	    return html .. "\">" .. html
	end

	--it is not an absolute url
	--now, it will try to match each possible part of a L code

	--the text part	
	local x = string.find (s, "|")
	local text = nil
    
	if x then 
        text = string.sub (s, 1, x - 1)
	else
	    x = 0
	end
	

	--the name part
	local y = string.find (s, "/", x + 1)
    local name = nil
	if y == nil then
    	name = string.sub (s, x + 1)
	else
		name = string.sub (s, x + 1, y - 1)
	end
	
	--the section part
	local section = nil
	if y then
		section = string.sub (s, y + 1)
	end
	
	if section == nil and text == nil and string.find (name, "\"") then
		section = name
		name = ""
	end
	
	
	if section then
		section = string.gsub (section, "\"", "")
	end


	if text == nil or text == "" then
		if section then
			text = section
		else
			text = name
		end
	end

	text = parsing (text, 1, 1, " ", nil)

	if section then
		section = string.gsub (section, " ", "_")
	end

	local res = "" 
	if name ~= "" then
		res = baseURL .. name
		if section then
			res = res .. "#" .. section
		end
	else  --it is a link to the current page
		res = "#" .. section
	end

	res = res .. "\">" .. text

	return res

end



local function Etag (t)
	if t then
	    return "&"
	else
	    return ";"
	end
end

local function Ftag (t)
	if t then
        return "<em>"
	else
	    return "</em>"
	end
end

local function Xtag (t)
    return " "
end

local function Ztag (t)
    return " "
end

local function Stag (t)
    return " "
end

--this table contains the functions that should treat each formatting code
--the functions are currently receiving a boolean parameter, when it is true it indicates
--the beginning of the formatting code, when it false it indicates the ending of the
--formatting code

local tags = {
    ["I"] = Itag,
    ["B"] = Btag,
    ["C"] = Ctag,
    ["L"] = Ltag,
    ["E"] = Etag,
    ["F"] = Ftag,
    --these functions below don't do anything useful currently
	["X"] = Xtag,
	["Z"] = Ztag,
	["S"] = Stag
	
}


local function commentFormatCode (t)
	if t then
		return "<!--"
	else
		return "-->"
	end
end


--This table represents the functions that should treat
--"=begin =end" regions
local formatCode = {
	["comment"] = commentFormatCode
}


local function initFormatTable ()
    formatTable = {}
end


local function insertFormatTable (initCode)
    formatTable[#formatTable + 1] = { l = string.sub (initCode, 1, 1), code = string.sub (initCode, 2) }
end


parsing = function (s, initPos, endPos, res, lastPos, x1, y1, x2, y2, insideLCode)

	--what tag (an opening tag or a closing one) was consumed in the previous execution,
	--so we need to find a new one
	if lastPos == "init" then
		x1, y1 = string.find (s, "%a<+", initPos)
	elseif lastPos == "end" then
    	x2, y2 = string.find (s, ">+", endPos)
	else
		x1, y1 = string.find (s, "%a<+", initPos)
    	x2, y2 = string.find (s, ">+", endPos)
	end

	--closes unmatched tags
    if x2 == nil then
        res = res .. string.sub (s, math.max (initPos, endPos))
        for i, v in ipairs (formatTable) do
            if v.l == "L" then
                res = res .. "\">" .. tags[v.l] (false)
            else
                res = res .. tags[v.l] (false)
            end
        end
        return string.sub (res, 2)
    end

    if x1 == nil or x2 < x1 then  -- next is ">"
      
        local e = formatTable [#formatTable]
        --changes ">" to "<" to compare with the starting formatting code
		local tmp = string.gsub (string.sub (s, x2, y2), ">", "<")
        
	    if e ~= nil and e.code == tmp then
            table.remove (formatTable)
            if e.l == "L" then
                Llink = Llink .. string.sub (s, math.max (initPos, endPos), x2 -1)
	            local tmp = Ltagaux (tmp)
                res = res .. tmp .. tags[e.l] (false)
				insideLCode = false
            else
				if insideLCode then
					Llink = Llink .. string.sub (s, math.max (initPos, endPos), x2 - 1)
					Llink = Llink .. string.sub (s, x2, y2)
				else
					res = res .. string.sub (s, math.max (initPos, endPos), x2 - 1)
                	res = res .. tags[e.l] (false)
				end
            end
        else
			--it is not the end of a formatting code, let's put the text just it is
            res = res .. string.sub (s, math.max (initPos, endPos), y2)
        end
        return parsing (s, initPos, y2 + 1, res, "end", x1, y1, x2, y2, insideLCode) 
    else  -- next is "<"

		if insideLCode then
			Llink = Llink .. string.sub (s, math.max (initPos, endPos), x1 - 1)
		else
        	res = res .. string.sub (s, math.max (initPos, endPos), x1 - 1)
		end

        insertFormatTable (string.sub (s, x1, y1))

        local l = string.sub (s, x1, x1)

        if tags[l] == nil then
            print ("Error: invalid formatting code!", string.sub (s, x1, y1))
            return nil
        end

		if insideLCode then
			Llink = Llink .. string.sub (s, x1, y1)
		else
        	res = res .. tags[l] (true)
		end	

		if l == "L" then
			insideLCode = true
			Llink = ""
		end

        return parsing (s, y1 + 1, endPos, res, "init", x1, y1, x2, y2, insideLCode)
    end

end



local function showNewline ()
    out:write ("\n")
end    


local function start ()
	if not embedded then
		out:write (doctype)
		out:write ("\n<html>\n")
		out:write ("<head>\n")
		out:write (encoding)		
		out:write ("<title>" .. fileTitle .. "</title>\n")
		out:write ("</head>\n")
		out:write ("<body>\n")
	end
	out:write ("<!-- LuaPOD v0.1 -->")
end


local function finish ()
	if not embedded then
		out:write ("</body>\n")
    	out:write ("</html>\n")
	end
end


local function h1 ()
    out:write ("<h1>")
    headNumber = 1
end


local function h2 ()
    out:write ("<h2>")
    headNumber = 2
end


local function h3 ()
    out:write ("<h3>")
    headNumber = 3
end


local function h4 ()
    out:write ("<h4>")
    headNumber = 4
end


local function display (s)
    initFormatTable ()
    out:write (parsing (s, 1, 1, " ", nil) or " ")
end


local function headName (s)
	out:write ("<a name=\"")
	out:write ((string.gsub (s, " ", "_")))
	out:write ("\">")
	display (s)
    out:write ("</a></h" .. headNumber .. ">")
end


local function ordinary (s)
    out:write ("<p>")
    display (s) 
    out:write ("</p>")
end


--The type of =over back regin can only be determined after the first
--paragraph after the =over command. firstItem it is used to indicate
--if first paragraph is the first one
local firstItem = nil


--Keeps what is the kind of item that should be used
--in an "=over =back" region
local itemType = { }

local function over ()
	firstItem = true
end

local function overIdent (s)
	firstItem = true
end


local function item ()

end

local function back ()
	--should not have the "" around false, I need to test this
    firstItem = false
	if itemType [#itemType] == "dl" then
		out:write ("</dd>")
	end
	out:write ("</" .. itemType [#itemType] .. ">")
	table.remove (itemType)
end


local function verbatim (s)
    out:write ("<pre>")
    out:write (s)
    out:write ("</pre>")
end


local function bareItem ()
    if firstItem then
        out:write ("<ul>")
        table.insert (itemType, "ul")
		firstItem = false
    end
    out:write ("<li>")

end

local function itemText (s)
    if firstItem then
        out:write ("<dl>")
        table.insert (itemType, "dl")
		firstItem = false
	else
		out:write ("</dd>")
    end
    
	out:write ("<dt>")
    display (s)
	out:write ("</dt>")
	out:write ("<dd>")
end

local function itemNumber (s)
    if firstItem then
        out:write ("<ol>")
        table.insert (itemType, "ol")
		firstItem = false
    end
    out:write ("<li>")
end

local function noItem ()
    out:write ("<blockquote>")
    table.insert (itemType, "blockquote")
    firstItem = false
end


local function startBegin (s)
    isFormatting [#isFormatting + 1] = false
    formatNames [#formatNames + 1] = s
	if formatCode [s] ~= nil then
		out:write (formatCode [s] (true))
	end
    currentData = { }
end


local function endBegin (s)
    if formatNames[#formatNames] ~= s then
        print ("Error: different format names")
    else
        table.remove (formatNames)
        table.remove (isFormatting)
		if formatCode [s] ~= nil then
			out:write (formatCode [s] (false))
		end
    end

end

local function beginFor (s)
    isFormatting [#isFormatting + 1] = false
    currentFor = s

	if formatCode [s] ~= nil then
		out:write (formatCode [s] (true))
	end
    
    currentData = { }
end

local function endFor ()
    table.remove (isFormatting)
 
    local t = table.concat (currentData, "\n")
    out:write (t)

	if formatCode [currentFor] ~= nil then
		out:write (formatCode [currentFor] (false))
	end

    showNewline ()
end

local function dataParagraph (s)
    currentData [#currentData + 1] = s
end

local function showData ()
    out:write (table.remove (currentData))
end


local function beginForWithColon (s)
    currentFor = s
	if formatCode [s] ~= nil then
		out:write (formatCode [s] (true))
	end
    out:write ("<p>")
    isFormatting [#isFormatting + 1] = true
    
    currentData = { }
end

local function endForWithColon ()
    local s = table.concat (currentData, "\n")
    display (s)
   
	out:write ("</p>")
	
	if formatCode [currentFor] ~= nil then
		out:write (formatCode [currentFor] (false))
	end


    showNewline ()
    
    table.remove (isFormatting)
end


local function startBeginWithColon (s)
	
	if formatCode [s] ~= nil then
		out:write (formatCode [s] (true))
	end

	formatNames [#formatNames + 1] = s
    isFormatting [#isFormatting + 1] = true
end

local function endBeginWithColon (s)
    
	if formatNames[#formatNames] ~= s then
        print ("Error: different format names")
    else
        table.remove (formatNames)
        table.remove (isFormatting)

		if formatCode [s] ~= nil then
			out:write (formatCode [s] (false))
		end
    end
end


local V = lpeg.V


local G = lpeg.P {
	"S";

    ["S"] = (1 - cmdPod)^0 * (cmdPod / start) * V ("SPACE")^0 * V ("NEWLINE") * V ("BLANKLINE")^0 / showNewline  * V ("BODY"),
    
    ["BODY"] = V ("Z") + ((V ("COMMAND") + V ("VERBATIM") + V ("ORDINARY")) * V ("BODY")),
    
    ["COMMAND"] = V ("H1") + V ("H2") + V ("H3") + V ("H4") + V ("OVER") + V ("CMDBEGIN") + V ("CMDFOR"),

    ["VERBATIM"] = #V ("INITVERBATIM") * (lpeg.C ((1 - V ("ENDPARAGRAPH"))^1) / verbatim) * V ("ENDPARAGRAPH") / showNewline,
    
    ["ORDINARY"] = #V ("INITORDINARY") * (lpeg.C ((1 - V ("ENDPARAGRAPH"))^1) / ordinary) * V ("ENDPARAGRAPH") / showNewline,

    ["H1"] =  (cmdHead1 / h1) * V ("HEAD"),
    
    ["H2"] =  (cmdHead2 / h2) * V ("HEAD"),
    
    ["H3"] =  (cmdHead3 / h3) * V ("HEAD"),
    
    ["H4"] =  (cmdHead4 / h4) * V ("HEAD"),

	["HEAD"] = V ("SPACE") * lpeg.C (V ("ATTR") / headName) * V ("ENDPARAGRAPH") / showNewline,
    
    ["OVER"] =  (cmdOver / over) * V ("SPACE")^0 * lpeg.C (V ("IDENTLEVEL")^-1) / overIdent  * V ("SPACE")^0 * V ("ENDPARAGRAPH") / showNewline * V ("ITEM"),
    
    ["ITEM"] = V ("INOTAG") + (V ("ITAG1") * V ("ITEM1"))  + (V ("ITAG2") * V ("ITEM2")) + (V ("ITAG3") * V ("ITEM3")),
     
    ["ITEM1"] = V ("ENDOVER") + ((V ("ITAG1") + V ("ITEMCOMMON")) * V ("ITEM1")),
   
    ["ITEM2"] = V ("ENDOVER") + ((V ("ITAG2") + V ("ITEMCOMMON")) * V ("ITEM2")),
    
    ["ITEM3"] = V ("ENDOVER") + ((V ("ITAG3") + V ("ITEMCOMMON")) * V ("ITEM3")),
    
    ["ITEMCOMMON"] = (V ("OVER") + V ("CMDBEGIN") + V ("CMDFOR") + V ("IPARAGRAPH")),
    
    ["NOITEM"] = V ("ENDOVER") + (V ("ITEMCOMMON") * V ("NOITEM")),
    
    ["ITAG1"] = (cmdItem / item) * ((V ("SPACE")^0 * V ("NEWLINE") / showNewline * V ("BLANKLINE")^0) + (V ("SPACE")^1 * "*" * V ("SPACE")^0 * V ("NEWLINE") * V ("BLANKLINE")^0)) / bareItem,
    
    ["ITAG2"] = ((cmdItem / item) * V ("SPACE")^1 * (lpeg.C (V ("NUMBER") * lpeg.P(".")^-1) / itemNumber) * V ("SPACE")^0 * V ("NEWLINE") / showNewline * V ("BLANKLINE")^0),
    
    ["ITAG3"] = ((cmdItem / item) * (V ("SPACE")^1 * (lpeg.C ((1 - V ("ENDPARAGRAPH"))^1) / itemText) * V ("ENDPARAGRAPH") / showNewline)),
    
    ["INOTAG"] = #(-cmdItem) / noItem * V ("NOITEM"),

    ["IPARAGRAPH"] = V ("VERBATIM") + V ("ORDINARY"),

    ["ENDOVER"] = (((cmdBack * V ("SPACE")^0 * V ("ENDPARAGRAPH") / showNewline) + lpeg.P (-1)) / back),  --(TODO) put an option when does not close over
    
    ["CMDBEGIN"] = cmdBegin * V ("SPACE")^1 * (V ("BEGINWITHCOLON") + V ("BEGINWITHOUTCOLON")),      
    
	["BEGINWITHOUTCOLON"] = (lpeg.C (V ("FORMATNAME")) / startBegin) * V ("SPACE")^0 * V ("ENDPARAGRAPH") / showNewline * V ("BEGINBODY"),
    
    ["BEGINWITHCOLON"] = ":" * (lpeg.C (V ("FORMATNAME")) / startBeginWithColon) * V ("SPACE")^0 * V ("ENDPARAGRAPH") /showNewline * V ("BEGINBODYCOLON"),
    
    ["BEGINBODY"] = V ("CMDEND") + ((V ("CMDBEGIN") + (V ("DATA") / showData * V ("NEWLINE") / showNewline * V ("BLANKLINE")^0)) *  V ("BEGINBODY")),

    ["BEGINBODYCOLON"] = V ("CMDENDCOLON") + ((V ("COMMAND") + V ("VERBATIM") + V ("ORDINARY")) * V ("BEGINBODYCOLON")),
    
    ["DATA"] = lpeg.C ((lpeg.P (1 - V ("NEWLINE"))^1) / dataParagraph),
    
    ["CMDEND"] = cmdEnd * V ("SPACE")^1 * (lpeg.C (V ("FORMATNAME")) / endBegin) * V ("SPACE")^0 * V ("ENDPARAGRAPH") / showNewline,
 
    ["CMDENDCOLON"] = cmdEnd * V ("SPACE")^1 * ":" * (lpeg.C (V ("FORMATNAME")) / endBeginWithColon) * V ("SPACE")^0 * V ("ENDPARAGRAPH") / showNewline,

    ["CMDFOR"] = cmdFor * V ("SPACE")^1 * (V ("FORWITHCOLON") + V ("FORWITHOUTCOLON")), 
    
    ["FORWITHCOLON"] = ":" * (lpeg.C (V ("FORMATNAME")) / beginForWithColon) * V ("SPACE")^0 * V ("FORBODYCOLON"),
    
    ["FORWITHOUTCOLON"] = (lpeg.C (V ("FORMATNAME")) / beginFor) * V ("SPACE")^0 * V ("NEWLINE")^-1 * V ("FORBODY"), 

    ["FORBODY"] = (V ("NEWLINE") * V ("BLANKLINE")^0/ endFor) + (V ("DATA") * V ("NEWLINE") * V ("FORBODY")),
    
    ["FORBODYCOLON"] = V ("ENDPARAGRAPH") / endForWithColon + (V ("NEWLINE")^-1 * V ("DATA") * V ("FORBODYCOLON")),

    ["Z"] = (cmdCut + ((V ("NEWLINE") + V ("SPACE"))^0 * lpeg.P (-1))) / finish,

	--these rules could be defined outside the grammar too
	
	["SPACE"] = lpeg.S (" \t"),

	["NEWLINE"] =  lpeg.P"\13" + lpeg.P"\10" + (lpeg.P"\13" * lpeg.P"\10"),

	["BLANKLINE"] = V ("SPACE")^0 * V ("NEWLINE"),

	["ENDPARAGRAPH"] = V ("NEWLINE") * V ("BLANKLINE")^1,

	["ATTR"] = lpeg.P (1 - V ("ENDPARAGRAPH"))^0,

	["DIGIT"] = lpeg.R ("09"),

	["NUMBER"] = V ("DIGIT")^1,

	["INITORDINARY"] = (1 - (lpeg.P ("=") + V ("SPACE"))),

	["INITVERBATIM"] = V ("SPACE"),

	--this rule could be used to identify if the tag of an item is really a text, but the manual does not obligate to verify this,
	--what implies that it is possible to have tags as "=item 4" and "=item ball" inside the same "=over" section
	--["INITTEXT"] = (lpeg.P ("*") * V ("SPACE")^0 * V ("NEWLINE")) + (V ("NUMBER") * lpeg.P (".")^-1 * V ("SPACE")^0 * V ("NEWLINE")),

	["FORMATNAME"] = (lpeg.R ("az", "AZ", "09") + lpeg.S ("_-")) ^1,

	["IDENTLEVEL"] = (V ("DIGIT")^0 * lpeg.P ("."))^-1 * V ("DIGIT")^1
 
}


function parser (input, url, emb, output)

	local file = io.input (input)
	local s = file:read ("*all")

	local name = output
	if name == nil then
		name = string.sub (input, 1, (string.find (input, "%.")))
	
		if string.sub (name, #name, #name) ~= "." then
    		name = name .. "."
		end

		name = name .. "html"
	end

	fileTitle = name

	embedded = emb

	out = io.output (name)

	if url then
		baseURL = url
	end

	lpeg.match (G, s)

	out:close ()

end




local Buffer = {s = " "}

function Buffer:new (obj)
    obj = obj or {}
    setmetatable(obj, self)
    self.__index = self
    return obj
end


function Buffer:write (text)
    self.s = self.s .. text
    return self.s
end


function Buffer:read ()
	return self.s
end

function parserToBuffer (text, url, emb)

	out = Buffer:new ()

	if url then
		baseURL = url
	end

	fileTitle = ""

	embedded = emb

	lpeg.match (G, text)

	return out:read ()
end


