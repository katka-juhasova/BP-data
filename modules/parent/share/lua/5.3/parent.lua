function parent_string(level)
  local ats = { '@' }
  local parents = { }

  while level > 0 do
    table.insert(ats, '@')

    if level == 1 then
      table.insert(parents, 'parent')
    elseif level == 2 then
      table.insert(parents, 'grand')
    elseif level > 2 then
      table.insert(parents, 'great')
    end

    level = level - 1
  end


  return table.concat(ats, '') .. table.concat(parents, '')
end

return parent_string
