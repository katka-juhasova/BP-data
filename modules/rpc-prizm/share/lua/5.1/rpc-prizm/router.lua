--- Router object
local Router = {}

--- Create new router
-- param[type=table] routes route table
-- return[type=table] New router instance
function Router:new(routes)
    assert(type(routes) == "table", "Parameter 'routes' is required and should be a table!")

    local router = setmetatable({}, Router)
    self.__index = self

    router.routes = routes

    return router
end

--- Find address for json-rpc method
-- param[type=string] method JSON-rpc method
-- @return[type=string] Request uri
-- @return[type=string] Error
function Router:get_address(method)
    if not self.routes then
        return nil, 'Empty route table'
    end

    for _, route in ipairs(self.routes) do
        local addr, matches = string.gsub(method, route['rule'], route['addr']);
        if matches >= 1 then
            return addr, nil
        end
    end

    return nil, 'Failed to bind the route'
end

return Router