local math = require "math"
local bit = {}

function bit:Or(a,b)
    local p,c=1,0
    while a+b>0 do
        local ra,rb=a%2,b%2
        if ra+rb>0 then c=c+p end
        a,b,p=(a-ra)/2,(b-rb)/2,p*2
    end
    return c
end

function bit:Not(n)
    local p,c=1,0
    while n>0 do
        local r=n%2
        if r<1 then c=c+p end
        n,p=(n-r)/2,p*2
    end
    return c
end

function bit:And(a,b)--wise and
    local p,c=1,0
    while a>0 and b>0 do
        local ra,rb=a%2,b%2
        if ra+rb>1 then c=c+p end
        a,b,p=(a-ra)/2,(b-rb)/2,p*2
    end
    return c
end


function bit:lshift(x, by)
    return x * 2 ^ by
end
  
function bit:rshift(x, by)
    return math.floor(x / 2 ^ by)
end

function bit:utf8_from(t)
    local bytearr = {}
    for _, v in ipairs(t) do
        local utf8byte = v < 0 and (0xff + v + 1) or v
        table.insert(bytearr, string.char(utf8byte))
    end
    local t =  table.concat(bytearr)
    return t
end

function bit:tofloat(c)
    if c == 0 then
        return 0.0
    end
    local c = string.gsub(
        string.format("%X", c),
        "(..)",
        function(x)
            return string.char(tonumber(x, 16))
        end
    )
    
    local b1, b2, b3, b4 = string.byte(c, 1, 4)
    
    local sign = b1 > 0x7F
    local expo = (b1 % 0x80) * 0x2 + math.floor(b2 / 0x80)
    local mant = ((b2 % 0x80) * 0x100 + b3) * 0x100 + b4
    
    if sign then
        sign = -1
    else
        sign = 1
    end
    
    local n
    
    if mant == 0 and expo == 0 then
        n = sign * 0.0
    elseif expo == 0xFF then
        if mant == 0 then
            n = sign * math.huge
        else
            n = 0.0 / 0.0
        end
    else
        n = sign * math.ldexp(1.0 + mant / 0x800000, expo - 0x7F)
    end
    
    return n
end

function bit:inttohex(input)
    local b, k, output, i, d = 16, "0123456789ABCDEF", "", 0
    while input > 0 do
        i = i + 1
        input, d = math.floor(input / b), math.mod(input, b) + 1
        output = string.sub(k, d, d) .. output
    end
    return "0x" .. output
end


function bit:todouble(bytes)

    local sign = 1
    local mantissa = bytes:byte(2) % 2^4
    for i = 3, 8 do
      mantissa = mantissa * 256 + bytes:byte(i)
    end
    if bytes:byte(1) > 127 then sign = -1 end
    local exponent = (bytes:byte(1) % 128) * 2^4 + math.floor(bytes:byte(2) / 2^4)
    
    if exponent == 0 then
      return 0
    end
    mantissa = (math.ldexp(mantissa, -52) + 1) * sign
    return math.ldexp(mantissa, exponent - 1023)
end

function bit:swap(bytes)
    local swappedBytes = {}
    
    for i=#bytes,1,-1 do
        table.insert(swappedBytes,bytes:byte(i))
    end
    
    local ret =  self:utf8_from(swappedBytes)
    return ret
end

function bit:touint32(bytes)
    return bytes:byte(1) * 0x1000000
         + bytes:byte(2) * 0x10000
         + bytes:byte(3) * 0x100
         + bytes:byte(4)
end

function bit:convert_to_little_endian (data, byte_mode)
    local converted_value = 0
    
    for i = 1, byte_mode do
        local byt
        if type(data) == "string" then
            byt = data:byte(i)
        else
            byt = data[i]
        end
        byt = self:lshift(byt, (i - 1) * 8)
        converted_value = self:Or(converted_value, byt)
    end
    return converted_value
end

function bit:convert_to_big_endian (data, byte_mode)
    local converted_value = 0    
    
    for i = 1, byte_mode do
        local byt
        if type(data) == "string" then
            byt = data:byte(i)
        else
            byt = data[i]
        end
        
        byt = self:lshift(byt, (byte_mode - i) * 8)
        converted_value = self:Or(converted_value, byt)
    end
    
    return converted_value
end

return bit