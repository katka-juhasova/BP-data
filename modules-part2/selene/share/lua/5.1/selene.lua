package.path = './src/?.lua;' .. package.path

return {
  set = require("src/set")
}
