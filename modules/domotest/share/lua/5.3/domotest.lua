function domotest(script_name, args)
  local devicechanged = args.devicechanged or {}
  local otherdevices = args.otherdevices or {}
  local otherdevices_lastupdate = args.otherdevices_lastupdate or {}
  local otherdevices_svalues = args.otherdevices_svalues or {}
  local uservariables = args.uservariables or {}
  local uservariableschanged = args.uservariableschanged or {}
  local uservariables_lastupdate = args.uservariables_lastupdate or {}
  local timeofday = args.timeofday or {}
  local globalvariables = args.globalvariables or {}

  io.input(script_name)
  headers = [[
local devicechanged,
otherdevices,
otherdevices_lastupdate,
otherdevices_svalues,
uservariables,
uservariableschanged,
uservariables_lastupdate,
timeofday,
globalvariables= ...
]]
  script = load(headers .. io.read('*all'))

  return script(
    devicechanged,
    otherdevices,
    otherdevices_lastupdate,
    otherdevices_svalues,
    uservariables,
    uservariableschanged,
    uservariables_lastupdate,
    timeofday,
    globalvariables
  )
end
