-- Copyright (C) 2020 Jacob Shtabnoy <shtabnoyjacob@scps.net>
-- Licensed under the terms of the ISC License, see LICENSE

local Type = require("lefthook.Type");

local WebhookBatch = {};
WebhookBatch.__index = WebhookBatch;

function WebhookBatch:addWebhook(webhook)
	Type(webhook, 1).table();
	table.insert(self.webhooks, webhook);
end

function WebhookBatch:executeBatch(form)
	Type(form, 1).table();
	for _,v in pairs(self.webhooks) do
		v:execute(form);
	end
end

function WebhookBatch.new(webhooks)
	Type(webhooks, 1).table.null();
	local webhooks = webhooks or {};
	local self = setmetatable({}, WebhookBatch);
	self.webhooks = webhooks;
	return self;	
end

return WebhookBatch;
