local new
new = function(name)
  local mod = { }
  package.loaded[name] = mod
  return mod
end
return {
  new = new
}
