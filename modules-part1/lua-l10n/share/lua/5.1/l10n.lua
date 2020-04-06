-----------------------------------------------------------------------------
-- Localization (l10n) for the Lua language.
-- Author: Fernando Paredes Garcia (fernando@develcuy.com)
-----------------------------------------------------------------------------

-- Storage for all available translations on runtime
local db = {}

local target_lang -- language to translate to

local function set_lang(lang)
  target_lang = lang
end

local function set_source_lang(lang)
  source_lang = lang
end

local function translate(str, ...)
  if nil == target_lang then
    io.stderr:write "WARNING: l10n: target language not set. Example: l10n.set_lang 'es'\n"
  end
  if [[string]] ~= type(str) then
    error [[l10n: Not a valid string provided!]]
  end
  if nil == db[str] then
    io.stderr:write(("WARNING: Trying to translate an unknown string: '%s'\n"):format(str))
  end

  local target
  if target_lang == source_lang then
    target = str -- Pass source string when no target available
  else
    target = (db[str] or {})[target_lang]
    if nil == target then
      target = str
      io.stderr:write(("WARNING: No '%s' translation available for '%s'\n"):format(target_lang or [[]], str))
    end
  end
  local params = {...}
  return
    nil ~= next(params) and
    target:format(...) or
    target
end

local function add(params)
  if
    [[table]] == type(params) and
    [[string]] == type(params[1])
  then
    local source = params[1]
    params[1] = nil
    for lang, target in pairs(params) do
      db[source] = {[lang] = target}
    end
  else
    error [[l10n: Invalid input!]]
  end
end

return {
  add = add,
  db = db,
  set_lang = set_lang,
  set_source_lang = set_source_lang,
  translate = translate,
}
