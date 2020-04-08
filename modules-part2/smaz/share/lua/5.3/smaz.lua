----------------------------------------------------------------------------------
--
-- smaz.lua
-- simple compression library suitable for compressing
-- very short strings
--
-- @author Vladimir Shaykovskiy <oik741@gmail.com>
-- @license MIT
----------------------------------------------------------------------------------

local smaz_codebook = {
    " ", "the", "e", "t", "a", "of", "o", "and", "i", "n", "s", "e ", "r",
    " th", " t", "in", "he", "th", "h", "he ", "to", "\r\n", "l", "s ", "d",
    " a", "an","er", "c", " o", "d ", "on", " of", "re", "of ", "t ", ", ",
    "is", "u", "at", "   ", "n ", "or", "which", "f", "m", "as", "it", "that",
    "\n", "was", "en", "  ", " w", "es", " an", " i", "\r", "f ", "g", "p",
    "nd", " s", "nd ", "ed ", "w", "ed", "http://", "for", "te", "ing", "y ",
    "The", " c", "ti", "r ", "his", "st", " in", "ar", "nt", ",", " to", "y",
    "ng", " h", "with", "le", "al", "to ", "b", "ou", "be", "were", " b",
    "se", "o ", "ent", "ha", "ng ", "their", "\"", "hi", "from", " f", "in ",
    "de", "ion", "me", "v", ".", "ve", "all", "re ", "ri", "ro", "is ", "co",
    "f t", "are", "ea", ". ", "her", " m", "er ", " p", "es ", "by", "they",
    "di", "ra", "ic", "not", "s, ", "d t", "at ", "ce", "la", "h ", "ne",
    "as ", "tio", "on ", "n t", "io", "we", " a ", "om", ", a", "s o", "ur",
    "li", "ll", "ch", "had", "this", "e t", "g ", "e\r\n", " wh", "ere", " co",
    "e o", "a ", "us", " d", "ss", "\n\r\n", "\r\n\r", "=\"", " be", " e",
    "s a", "ma", "one", "t t", "or ", "but", "el", "so", "l ", "e s", "s,",
    "no", "ter", " wa", "iv", "ho", "e a", " r", "hat", "s t", "ns", "ch ",
    "wh", "tr", "ut", "/", "have", "ly ", "ta", " ha", " on", "tha", "-", " l",
    "ati", "en ", "pe", " re", "there", "ass", "si", " fo", "wa", "ec", "our",
    "who", "its", "z", "fo", "rs", ">", "ot", "un", "<", "im", "th ", "nc",
    "ate", "><", "ver", "ad", " we", "ly", "ee", " n", "id", " cl", "ac", "il",
    "</", "rt", " wi", "div", "e, ", " it", "whi", " ma", "ge", "x", "e c",
    "men", ".com"
}

local smaz_reverse_codebook = {}
for i, v in ipairs(smaz_codebook) do
    smaz_reverse_codebook[i-1] = v
end

local MAX_CODE_LEN = 7


local function find_code(needle)
    for i=1,#smaz_codebook do
        if smaz_codebook[i] == needle then
            return i - 1
        end
    end

    return nil
end


local function compose_verbatim(verbatim)
    local output = ""
    if string.len(verbatim) > 1 then
        output = output .. string.char(255)
        output = output .. string.char(string.len(verbatim) - 1)
    else
        output = output .. string.char(254)
    end

    return output .. verbatim
end


--- Compresses the given uncompressed string
-- @param data to compress
-- @return string with compressed data
local function compress(data)
    local output = ""
    local verbatim = ""

    if not data then
        return output
    end

    local data_len = string.len(data)
    local idx = 0

    while idx < data_len do
        local encoded = false
        local j = MAX_CODE_LEN
        if data_len - idx < MAX_CODE_LEN then
            j = data_len - idx
        end

        while j > 0 do
            local code = find_code(string.sub(data, idx + 1, idx + j))
            if code then
                if verbatim ~= "" then
                    output = output .. compose_verbatim(verbatim)
                    verbatim = ""
                end

                output = output .. string.char(code)
                idx = idx + j
                encoded = true
                break
            end
            j = j - 1
        end

        if not encoded then
            verbatim = verbatim .. data:sub(idx+1, idx+1)
            idx = idx + 1

            if string.len(verbatim) == 256 then
                output = output .. compose_verbatim(verbatim)
                verbatim = ""
            end
        end
    end
    if verbatim ~= "" then
        output = output .. compose_verbatim(verbatim)
    end
    return output
end


--- Decompresses the given string
-- @param data to decompress
-- @return string with compressed data or nil(in case of error)
-- @return string describing error or nil
local function decompress(data)
    local output = ""

    local i = 1
    while i <= #data do
        local code = string.byte(string.sub(data, i, i))

        -- only one byte encoded
        if code == 254 then
            if i + 1 > #data then
                return nil, "Malformed data"
            end

            output = output .. string.sub(data, i + 1, i + 1)

            -- move index to next chunk
            i = i + 2

        -- more than one byte encoded
        elseif code == 255 then
            local verb_len =  string.byte(string.sub(data, i + 1, i + 1))

            if i + verb_len > #data then
                return nil, "Malformed data"
            end

            -- move index to first data byte(after verbatim data)
            i = i + 2
            output = output .. string.sub(data, i, i + verb_len)

            -- move index to next chunk
            i = i + verb_len + 1

        -- not encoded
        else
            output = output .. smaz_reverse_codebook[code]
            i = i + 1
        end
    end

    return output, nil
end


return {
    compress = compress,
    decompress = decompress,
}