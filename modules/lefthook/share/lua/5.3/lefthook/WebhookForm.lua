-- Copyright (C) 2020 Jacob Shtabnoy <shtabnoyjacob@scps.net>
-- Licensed under the terms of the ISC License, see LICENSE

local json = require("dkjson");
local Type = require("lefthook.Type");

local WebhookForm = {};
WebhookForm.__index = WebhookForm;

function WebhookForm:addEmbed(embed)
	Type(embed, 1).table();
	if not self.embeds then
		self.embeds = {};
	end
	table.insert(self.embeds, embed);
end

function WebhookForm:toJson()
	return json.encode(self);
end

function WebhookForm.new(content, username, avatar_url, tts, embeds)
	Type(content, 1).string.null();
	Type(username, 2).string.null();
	Type(avatar_url, 3).string.null();
	Type(tts, 4).boolean.null();
	Type(embeds, 5).table.null();

	local self = setmetatable({}, WebhookForm);
	self.content = content;
	self.username = username;
	self.avatar_url = avatar_url;
	self.tts = tts;
	self.embeds = embeds;
	return self;
end

return WebhookForm;
