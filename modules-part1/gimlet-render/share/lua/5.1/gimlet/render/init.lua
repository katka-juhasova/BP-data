local options = {
  directory = 'templates',
  layout = 'layout',
  extensions = {
    'tmpl',
    'html'
  },
  ['content-type'] = 'text/html'
}
local find_file
find_file = function(directory, filename, extensions)
  local is_file
  is_file = function(filename)
    local attributes
    do
      local _obj_0 = require('lfs')
      attributes = _obj_0.attributes
    end
    local f = attributes(filename)
    if not (f and f.mode == 'file') then
      return false
    end
    return true
  end
  for _index_0 = 1, #extensions do
    local e = extensions[_index_0]
    local layout_file = string.format("%s/%s.%s", directory, filename, e)
    if is_file(layout_file) then
      return layout_file
    end
  end
end
local read_file
read_file = function(f)
  local file = io.open(f)
  if not (file) then
    return 
  end
  local output = file:read('*a')
  file:close()
  return output
end
local html
html = function(o, p)
  return function(args)
    local compile
    do
      local _obj_0 = require('etlua')
      compile = _obj_0.compile
    end
    if o['content-type'] then
      p.response:set_options({
        ['Content-Type'] = o['content-type']
      })
    end
    local directory = o.directory or options.directory
    local layout
    if o.layout then
      local layout_file = find_file(directory, o.layout, o.extensions)
      if not (layout_file or o.layout ~= 'layout') then
        print("unable to open layout: " .. tostring(o.layout))
        return 
      end
      layout = compile(read_file(layout_file))
    end
    local template_file = find_file(directory, args.template, o.extensions)
    if not (template_file) then
      print('unable to find template file')
      return 
    end
    local template = compile(read_file(template_file))
    local rendered_template = template(args.data or { })
    if layout then
      local data = args.data or { }
      data.template = rendered_template
      p.response:write(layout(data or { }))
      return 
    end
    return p.response:write(rendered_template)
  end
end
local json
json = function(o, p)
  return function(args)
    json = require('cjson')
    if args.data then
      p.response:set_options({
        ['Content-Type'] = 'application/json',
        status = args.status or 200
      })
      if args.data then
        return p.response:write(json.encode(args.data))
      end
    else
      return p.response:write(json.encode(args))
    end
  end
end
local Render
Render = function(args)
  if args == nil then
    args = { }
  end
  for k, v in pairs(options) do
    if not (args[k]) then
      args[k] = v
    end
  end
  return function(p)
    return p.gimlet:map('render', {
      html = html(args, p),
      json = json(args, p)
    })
  end
end
return {
  Render = Render,
  options = options
}
