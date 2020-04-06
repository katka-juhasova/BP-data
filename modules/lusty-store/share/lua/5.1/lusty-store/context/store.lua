local store = function(collection, method)
  return function(query, data)
    local result = context.lusty:publish(
    { 'store', collection, method },
    { method=method, query = query, data = data, collection=collection }
    )
    local ret = {}
    if #result > 0 then
      for i=1, #result do
        local row = result[i]
        if row and type(row) == 'table' and #row > 0 then
          for j=1, #row do
            ret[#ret+1] = row[j]
          end
        else
          ret = row
          break
        end
      end
    end
    return ret
  end
end

context.store = setmetatable({}, {
  __index = function(self, collection)
    local collectionTable = rawget(self, collection)
    if not collectionTable then
      collectionTable = setmetatable({}, {
        __index = function(self, method)
          local methodFunction = rawget(self, method)
          if not methodFunction then
            methodFunction = store(collection, method)
            self[method] = methodFunction
          end
          return methodFunction
        end
      })
      self[collection] = collectionTable
    end
    return collectionTable
  end
})
