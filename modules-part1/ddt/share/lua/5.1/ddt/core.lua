return function()
  local ddt = {}
  ddt.appName = 'ddt'
  ddt.version = '0.0.1'
  ddt.publish = print
  ddt.subscribe = function()
  end
  return ddt
end
