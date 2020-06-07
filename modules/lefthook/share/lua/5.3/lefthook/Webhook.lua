-- Copyright (C) 2020 Jacob Shtabnoy <shtabnoyjacob@scps.net>
-- Licensed under the terms of the ISC License, see LICENSE

local https = require("ssl.https");
local ltn12 = require("ltn12");
local WebhookForm = require("lefthook.WebhookForm");
local Type = require("lefthook.Type");

local WEBHOOK_URL = "https://discordapp.com/api/webhooks/%s/%s"

local Webhook = {};
Webhook.__index = Webhook;

function Webhook:execute(webhookForm)
	Type(webhookForm, 1).table();
	local requestBody = webhookForm:toJson();
	https.request {
		url = WEBHOOK_URL:format(self.id, self.token),
		method = "POST",
		headers = {
			["Content-Type"] = "application/json",
			["content-length"] = #requestBody,
		},
		source = ltn12.source.string(requestBody);
	};
end

function Webhook:sendMessage(message)
	Type(message, 1).string();
	self:execute(WebhookForm.new(message));
end

function Webhook.new(id, token)
	Type(id, 1).string();
	Type(id, 2).string();
	local self = setmetatable({}, Webhook);
	self.id = id;
	self.token = token;
	return self;
end

return Webhook;
