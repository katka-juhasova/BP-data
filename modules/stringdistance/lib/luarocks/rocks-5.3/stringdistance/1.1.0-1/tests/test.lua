--$Id: test.lua,v 1.11 2011-12-21 13:35:37 tomas Exp $
local l
if string.find(_VERSION, "Lua 5.0") then
	l = assert(loadlib("./stringdistance.so", "luaopen_stringdistance"))()
else
	l = require"stringdistance"
end
print(string.format("Testing %s version %s release %s with %s", string.sub(l._NAME, string.find(l._NAME, "^%w+ %w+")), l._VERSION, l._RELEASE, _VERSION))

function d(str1, str2, expected, alg, insensitive)
	local value 
	if alg == "Damerau" then
   		value = l.dam(str1,str2)
	end
	if alg == "Levenshtein" then
		value = l.lev(str1,str2) 
    end 
	context = string.format("%s ( %s , %s )", alg,str1,str2)
	if value ~= expected then
		error ("Wrong value in `"..context.."`.  Received [["..tostring(value).."]], but [["..tostring(expected).."]] was expected", 2)
	end
end

d ("aB”Í","bA Û", 4, "Damerau")
d ("aB”Í","bAÍ”", 3, "Damerau")
d ("OÍ"," o", 2, "Damerau")
d ("aBDc","bACd", 4, "Damerau")
d ("A", "a", 1, "Damerau")
d ("AAA", "aaa", 3, "Damerau")
d ("·a‡", "aaa", 2, "Damerau")
d ("·a‡", "···", 2, "Damerau")
d ("ab", "bra", 2, "Damerau")
d ("", "bra", 3, "Damerau")
d ("bra","", 3, "Damerau")
d ("s","ssss", 3, "Damerau")
d ("g","h", 1, "Damerau")
d ("g","g", 0, "Damerau")
d ("aaaaaaaaaaaaaaa","aaaaaaaaaaaaaaa", 0, "Damerau")
d ("baaaaaaaaaaaaaa","aaaaaaaaaaaaaaa", 1, "Damerau")
d ("Aaaaaaaaaaaaaaa","aaaaaaaaaaaaaaa", 1, "Damerau")
d ("·aaaaaaaaaaaaaa","aaaaaaaaaaaaaaa", 1, "Damerau")
d ("soletrando", "osletranods", 3, "Damerau")
d ("soletrando", "osletRanods", 4, "Damerau")
d ("soletrando", "soletrando", 0, "Damerau")
d ("soletrando", "osletrnao", 3, "Damerau")
d ("·ÈÌÛal","·ÈÌÛ˙la", 2, "Damerau")
d ("abc","cba", 2, "Damerau")
d ("bc","caab", 3, "Damerau")
d ("bc","caab", 4, "Levenshtein")
d ("abcdefghi","abcDefh", 3, "Levenshtein")
d ("2009", "2010", 2, "Levenshtein")

print("\n\nTest completed successfully!\n\n")
