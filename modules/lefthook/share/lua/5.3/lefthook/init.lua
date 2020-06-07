-- Copyright (C) 2020 Jacob Shtabnoy <shtabnoyjacob@scps.net>
-- Licensed under the terms of the ISC License, see LICENSE

local init = {};

init.WebhookForm = require("lefthook.WebhookForm");
init.Webhook = require("lefthook.Webhook");
init.Embed = require("lefthook.Embed");
init.WebhookBatch = require("lefthook.WebhookBatch");

return init;
