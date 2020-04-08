return function()
  local ddlt = {}
  ddlt.appName = 'dd-lua-tester'
  ddlt.version = '0.0.1'
  ddlt.publish = print
  ddlt.subscribe = function()
  end
  return ddlt
end
