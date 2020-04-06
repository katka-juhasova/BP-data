pduString = require("luapdu.string")

local pduSmsObject = {}
pduSmsObject.__index = pduSmsObject

function pduSmsObject.new(content)
    local self = content
    setmetatable(self, pduSmsObject)
    return self
end

--! Create new TX sms object with default values
function pduSmsObject.newTx(recipientNum, content)
    if recipientNum and not recipientNum:match("^\+?%d+$") then
        error("Invalid recipient number! <"..recipientNum..">")
    end
    local content = {
            msgReference=0,
            recipient={
                num  = recipientNum or ""
            },
            protocol = 0,
            decoding = 0,
            --validPeriod = 0x10+11, -- 5 + 5*11 = 60 minutes (https://en.wikipedia.org/wiki/GSM_03.40)
            msg={
                content = content or ""
            }
        }
    return pduSmsObject.new(content)
end

--! Create new RX sms object with default values
function pduSmsObject.newRx(content)
    local content = {
            sender={
                num  = ""
            },
            protocol = 0,
            decoding = 0,
            timestamp = ("00"):rep(7),
            msg={
                content = content or ""
            }
        }
    return pduSmsObject.new(content)
end

function pduSmsObject:encode16bitPayload()
    local response = {}
    local length = 0
    local content = self.msg.content
    while content:len() ~= 0 do
        -- http://lua-users.org/wiki/LuaUnicode
        -- X - octet1, Y - octet2
        local byte = content:byte(1)
        if     byte <= 0x7F then    -- 7bit
            response[#response+1] = "00"
            response[#response+1] = pduString:octet(byte)       -- 0b0XXXXXXX
            content = content:sub(2)
        elseif byte <= 0xDF then    -- 11bit
            local byte2 = content:byte(2)
            content = content:sub(3)
            local val = bit.lshift(bit.band(byte, 0x1F),6) +    -- 0b110XXXYY
                                   bit.band(byte2,0x3F)         -- 0b10YYYYYY
            response[#response+1] = pduString:octet(bit.rshift(val,8))
            response[#response+1] = pduString:octet(bit.band(val,0xFF))
        elseif byte <= 0xEF then    -- 16bit
            local byte2 = content:byte(2)
            local byte3 = content:byte(3)
            content = content:sub(4)
            local val = bit.lshift(bit.band(byte,  0x0F),12) +  -- 0b1110XXXX
                        bit.lshift(bit.band(byte2, 0x3F),6)  +  -- 0b10XXXXYY
                                   bit.band(byte3, 0x3F)        -- 0b10YYYYYY
            response[#response+1] = pduString:octet(bit.rshift(val,8))
            response[#response+1] = pduString:octet(bit.band(val,0xFF))
        else
            return error("Can't fit payload char into 16bit unicode!")
        end
        length = length + 2
    end
    return response, length
end

function pduSmsObject:encode7bitPayload()
    local encodeTable7bit = {["@"]=0,["£"]=1,["$"]=2,["¥"]=3,["è"]=4,["é"]=5,["ù"]=6,["ì"]=7,["ò"]=8,["Ç"]=9,[" "]=10,["Ø"]=11,["ø"]=12,[" "]=13,["Å"]=14,["å"]=15,["Δ"]=16,["_"]=17,["Φ"]=18,["Γ"]=19,["Λ"]=20,["Ω"]=21,["Π"]=22,["Ψ"]=23,["Σ"]=24,["Θ"]=25,["Ξ"]=26,["€"]=27,["Æ"]=28,["æ"]=29,["ß"]=30,["É"]=31,[" "]=32,["!"]=33,["\""]=34,["#"]=35,["¤"]=36,["%"]=37,["&"]=38,["'"]=39,["("]=40,[")"]=41,["*"]=42,["+"]=43,[","]=44,["-"]=45,["."]=46,["/"]=47,["0"]=48,["1"]=49,["2"]=50,["3"]=51,["4"]=52,["5"]=53,["6"]=54,["7"]=55,["8"]=56,["9"]=57,[":"]=58,[";"]=59,["<"]=60,["="]=61,[">"]=62,["?"]=63,["¡"]=64,["A"]=65,["B"]=66,["C"]=67,["D"]=68,["E"]=69,["F"]=70,["G"]=71,["H"]=72,["I"]=73,["J"]=74,["K"]=75,["L"]=76,["M"]=77,["N"]=78,["O"]=79,["P"]=80,["Q"]=81,["R"]=82,["S"]=83,["T"]=84,["U"]=85,["V"]=86,["W"]=87,["X"]=88,["Y"]=89,["Z"]=90,["Ä"]=91,["Ö"]=92,["Ñ"]=93,["Ü"]=94,["§"]=95,["¿"]=96,["a"]=97,["b"]=98,["c"]=99,["d"]=100,["e"]=101,["f"]=102,["g"]=103,["h"]=104,["i"]=105,["j"]=106,["k"]=107,["l"]=108,["m"]=109,["n"]=110,["o"]=111,["p"]=112,["q"]=113,["r"]=114,["s"]=115,["t"]=116,["u"]=117,["v"]=118,["w"]=119,["x"]=120,["y"]=121,["z"]=122,["ä"]=123,["ö"]=124,["ñ"]=125,["ü"]=126,["à"]=127}

    local response = {}
    local state = 0
    local carryover = 0
    local length = 0
    local content = self.msg.content

    while content:len() ~= 0 or carryover ~= 0 do
        local charval = encodeTable7bit[content:sub(1,1)]
        content = content:sub(2)
        if charval == nil then charval = 0 end
        local val = bit.lshift(charval, state) + carryover
        if state~= 0 or content:len() == 0 then
            response[#response+1] = pduString:octet(bit.band(val, 0xFF))
            carryover = bit.rshift(val, 8)
        else
            carryover = val
        end
        length = length + 1
        if state == 0 then state = 7 else state = state - 1 end
    end
    return response, length
end

function pduSmsObject:dcsEncodingBits()
    if     self.msg.content:match("[\196-\240]") then return 8
    elseif self.msg.content:match("[\128-\196]") then return 4
    else                                              return 0 end
end

function pduSmsObject:encodePayload(alphabetOverride)
    local length  = 0
    if alphabetOverride == nil then
        alphabetOverride = self:dcsEncodingBits()
    elseif alphabetOverride ~= 8 and
           alphabetOverride ~= 4 and
           alphabetOverride ~= 0 then
        error("Invalid alphabet override!")
    end
    local response = {}
    if alphabetOverride == 4 then
        local content = self.msg.content
        while content:len() ~= 0 do
            response[#response+1] = pduString:octet(content:byte(1))
            content = content:sub(2)
            length = length + 1
        end
    elseif alphabetOverride == 8 then
        response, length = self:encode16bitPayload()
    elseif alphabetOverride == 0 then
        response, length = self:encode7bitPayload()
    else
        error("Unimplemented payload encoding alphabet!")
    end
    return table.concat(response), length
end

function pduSmsObject:encode()
    local response = {}
    local function numberType(number)
        return (number:sub(1,1) == "+") and 0x91 or 0x81
    end
    if self.smsc and self.smsc.num then
        local rawSmscNumber = self.smsc.num:gsub("+","")
        self.smsc.len = rawSmscNumber:len() + 1
        response[#response+1] = pduString:octet(self.smsc.len)
        self.smsc.type   = numberType(self.smsc.num)
        response[#response+1] = pduString:octet(self.smsc.type)
        response[#response+1] = pduString:decOctets(rawSmscNumber)
    else
        response[#response+1] = pduString:octet(0x00)
    end

    local payload = ""
    -- RX message decoding block
    if self.sender then
        self.type = 0
        response[#response+1] = pduString:octet(0x00)
        -- Sender block
        local rawSenderNumber = self.sender.num:gsub("+","")
        self.sender.type = numberType(self.sender.num)
        self.sender.len  = rawSenderNumber:len()
        response[#response+1] = pduString:octet(self.sender.len)
        response[#response+1] = pduString:octet(self.sender.type)
        response[#response+1] = pduString:decOctets(rawSenderNumber)
        -- Protocol
        response[#response+1] = pduString:octet(0x00)
        -- Data Coding Scheme https://en.wikipedia.org/wiki/Data_Coding_Scheme
        response[#response+1] = pduString:octet(self:dcsEncodingBits())
        -- Timestamp
        response[#response+1] = pduString:decOctets(("00"):rep(7))
        -- Payload
        payload, self.msg.len = self:encodePayload()
        response[#response+1] = pduString:octet(self.msg.len)
        response[#response+1] = payload
    -- TX message decoding block
    elseif self.recipient then
        self.type = 1
        response[#response+1] = pduString:octet(0x01)
        -- Message reference
        response[#response+1] = pduString:octet(self.msgReference)
        -- Recipient block
        local rawRecipientNumber = self.recipient.num:gsub("+","")
        self.recipient.type   = numberType(self.recipient.num)
        self.recipient.len    = rawRecipientNumber:len()
        response[#response+1] = pduString:octet(self.recipient.len)
        response[#response+1] = pduString:octet(self.recipient.type)
        response[#response+1] = pduString:decOctets(rawRecipientNumber)
        -- Protocol
        response[#response+1] = pduString:octet(0x00)
        -- Data Coding Scheme https://en.wikipedia.org/wiki/Data_Coding_Scheme
        response[#response+1] = pduString:octet(self:dcsEncodingBits())
        -- Payload
        payload, self.msg.len = self:encodePayload()
        response[#response+1] = pduString:octet(self.msg.len)
        response[#response+1] = payload
    else
        error("No valid content!")
    end
    return table.concat(response, "")
end

return pduSmsObject