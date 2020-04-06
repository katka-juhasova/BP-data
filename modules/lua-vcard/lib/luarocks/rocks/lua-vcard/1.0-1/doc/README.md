# lua-vcard
Parsing vcards with Lua

# Intro
Well... i needed a library to parse VCF files in lua, and there wasn't already an existing library, so...  
* Should be stable enough now.
* It support formats 2.1, 3.0, 4.0, may support 2.0 (not tested), and also support groups and multiline data, as well as legacy attributes (from 2.0/2.1)
* It doesn't strictly check against the RFCs (for example, to check if a attribute is valid for the element's name), but it does follow RFCs rules for naming conventions
* It doesn't also do additional processing on the data, it *just* parse the file and return a corresponding table.  

# Dependencies
* Lpeg

# How to use
```
	local vcard = require("vcard").parse("Your_vcard_here")
```

# Table format
This is what you get
```
	{ -- list of cards
		{ -- list of elements
			{ -- element
				name = "ELEMENT",
				attributes = {
					"ATTR=value",
					"OTHER=val",
					"VALUE" -- legacy 2.1, deprecated
				},
				data = "myname"
			},

			{ -- other element, with a data table
				name = "ADR",
				attributes = {},
				data = {
					"",
					"",
					"42 sesam street",
					"dream city",
					"",
					"",
					"Some country"
				}
			{
		}
	}
```
