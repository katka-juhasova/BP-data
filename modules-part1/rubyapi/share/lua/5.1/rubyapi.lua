local rubyapi = {}
rubyapi.__index = rubyapi

function rubyapi:new()
    local api = {}
    setmetatable(api, rubyapi)
    return api
end

function rubyapi:interpret(code, err)
    if type(code) ~= "string" then if err then error("Invalid argument!") else return nil end end
    
    f = io.open("rubyapi-in.txt", "w")
    if f == nil then if err then error("Can not write file") else return nil end end
    
    f:write(code)
    f:close()
    
    x, y, z = os.execute("ruby < rubyapi-in.txt > rubyapi-out.txt")
    if z == nil and x ~= 0 or z ~= nil and z ~= 0 then
        if err then error("Could not run Ruby. Please check if you have Ruby installed.") end
        return nil
    end
    
    f = io.open("rubyapi-out.txt", "r")
    if f == nil then if err then error("Can not read file") else return nil end end
    
    res = f:read("*all")
    f:close()
    
    return res
end

function rubyapi:close()
    os.remove("rubyapi-in.txt")
    os.remove("rubyapi-out.txt")
end

function rubyapi:version()
    return rubyapi:interpret("print RUBY_VERSION", true)
end

return rubyapi