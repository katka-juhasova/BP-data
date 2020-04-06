--[[

Class Pijaz.

Bootstrap class for all API classes, puts them under one table instance.

PUBLIC PROPERTIES:

ServerManager
Product

]]

local ServerManager = require "pijaz.server_manager"
local Product = require "pijaz.product"

return {
  ServerManager = ServerManager,
  Product = Product,
}
