-- Copyright (C) 2020 stillunt1tled <shtabnoyjacob@scps.net>
-- Licensed under the terms of the ISC License, see LICENSE.

local Type = require("lefthook.Type");
local Embed = {};
Embed.__index = Embed;

function Embed:setFooter(text, icon_url)
	Type(text, 1).string.null();
	Type(icon_url, 2).string.null();
	self.footer = {
		text = text;
		icon_url = icon_url;
	}
end

function Embed:addField(name, value, inline)
	Type(name, 1).string();
	Type(value, 2).string();
	Type(inline, 3).boolean.null();
	if not self.fields then
		self.fields = {};
	end
	local field = {};
	field.name = name;
	field.value = value;
	field.inline = inline;
	table.insert(self.fields, field);
end

function Embed:setAuthor(name, url, icon_url)
	Type(name, 1).string.null();
	Type(url, 2).string.null();
	Type(icon_url, 3).string.null();
	self.author = {
		name = name,
		url = url,
		icon_url = icon_url
	}
end

function Embed:setImage(url)
	Type(url, 1).string();
	self.image = {
		url = url
	}
end

function Embed:setThumbnail(url)
	Type(url, 1).string();
	self.thumbnail = {
		url = url
	}
end

function Embed:setTimestamp(epoch)
	self.timestamp = os.date("!%Y-%m-%dT%TZ", epoch);
end

function Embed.new(title, description, url, color)
	Type(title, 1).string.null();
	Type(description, 2).string.null();
	Type(url, 3).string.null();
	Type(color, 4).number.null();

	local self = setmetatable({}, Embed);
	self.title = title;
	self.description = description;
	self.url = url;
	self.color = color;
	return self;
end

return Embed;
