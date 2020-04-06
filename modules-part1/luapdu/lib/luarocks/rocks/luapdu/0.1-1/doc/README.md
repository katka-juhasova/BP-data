# luapdu
Lua PDU SMS encoder/decoder
Currently only barebones functionality and some bugs. 

# Usage
## Decoding
To see the structure of the decoding, check out the [SMS Objects](#SMSobjects) section
```lua
require("luapdu")
decodedSMSObj = luapdu.decode(pduString)
```
## Encoding
To see the fields available for editing, check out the [SMS Objects](#SMSobjects) section
```lua
require("luapdu")
smsObj = luapdu.newTx()
smsObj.msg.content = "Some text"
smsObj.sender.num = "Some phone number"
pduString = smsObj:encode()
```


<a name="SMSobjects"/>
### SMS Objects
SMS objects for RX and TX are basically the same deal, only difference is the "recipient" and "sender" subtables. 
If required, one can add an "smsc" subtable with a "num" value for the SMS Center number.
#### TX SMS Object contents
```lua
TXsmsobj={ -- This is what luapdu.newTx() returns
  msgReference=0,
  recipient={
    num  = ""
  },
  protocol = 0, -- Currently ignored
  decoding = 0, -- Currently ignored
  msg={
    content = ""
  }
}
```
#### RX SMS Object contents
```lua
RXsmsobj={ -- This is what luapdu.newRx() returns
  sender={
      num  = ""
  },
  protocol = 0, -- Currently ignored
  decoding = 0, -- Currently ignored
  timestamp = ("00"):rep(7),
  msg={
      content = ""
  }
}
```

