# Lefthook

Lefthook is a library for quickly running Discord Webhooks.

# Installation

Lefthook is available as a rock from luarocks:

```
$ luarocks install lefthook
```

# Examples

Getting a webhook running is as simple as three lines of code:

```lua
require("lefthook.static");
local hook = Webhook.new("webhook id", "webhook token"); -- Format of the url is /api/webhooks/<id>/<token>
hook:sendMessage("Hello, world!");
```

You can also add rich-content embeds to your webhooks:

```lua
require("lefthook.static");
local hook = Webhook.new("webhook id", "webhook token");
local form = WebhookForm.new();
local embed = Embed.new("Cool title", "Cool description!", "https://www.example.com", 0x00FF00);
embed:setFooter("Cool footer!");
embed:setTimestamp(os.time()); -- accepts any UNIX timestamp
form:addEmbed(embed);
hook:execute(form);
```
