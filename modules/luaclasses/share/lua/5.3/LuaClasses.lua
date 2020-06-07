class   = {} -- Stores all classes by function, for creating their objects or deriving from them. Calls to a class ctor DONT take args. Change values with the setters/getters after localizing the object call. If you want to derive a class, just make a class like normal, but after you pass a table, pass it the class name second that you want to derive from.
local mt      = {}

function class.new(tab,der)
    local function new()
        if der then
            local obj = class[der]()

            for k,v in pairs(tab) do
                if type(v) ~= "function" then
                    obj["Set"..k] = function(val)
                        v = val
                    end

                    obj["Get"..k] = function()
                        return v
                    end
                else
                    obj[k] = v
                end
            end

            return obj
        else
            local s = {}

            for k,v in pairs(tab) do
                if type(v) ~= "function" then
                    s["Set"..k] = function(val)
                        v = val
                    end

                    s["Get"..k] = function()
                        return v
                    end
                else
                    obj[k] = v
                end
            end

            return s
        end
    end
    -- let us be able to return the function for local class declarations as well as storing the Ctor to do a class lookup when creating an obj.
    class[tab.Class] = new  -- Overwrite previous class name table to store its Ctor.
    return new
end

function mt.__index(self,k) -- When it cant find something it makes it a table on class' table, named after the initial call variables name and sets its metatable to class' metatable, so __call gets called immediately on it.
    class[k] = {k}
    setmetatable(class[k],mt)

    return class[k]
end

function mt.__call(...)
    -- 1st arg = __index table
    -- 2nd arg = class table
    -- 3rd arg = new table passed to the 2nd arg/class table.
    -- 4th arg = table or class string lookup to derive from.

    local args = {...}
    -- Deriving:
    if args[4] then
        if type(args[4]) == "string" then
            if class[args[4]] then
                args[3].Class = args[1][1]

                local obj = class.new(args[3],args[4])
                return obj
            else
                class[args[4]] = nil
                print("Attempt to derive from non-existant class: "..args[4].."\n")
                return
            end
        elseif type(args[4]) == "function" then
            args[3].Class = args[1][1]
            local cls = args[4]().GetClass() -- Call the ctor, but just save its class so we can reuse new()'s derive section.
            local obj = class.new(args[3],cls)
            return obj
        else
            print("Derivative must be a string or a function.\n")
            return
        end
    end
    -- Creating an obj from the class:
    if type(args[2]) == "string" then                                   -- Let them pass a class name as string to return an obj when calling class table.
        if class[args[2]] and type(class[args[2]]) == "function" then   -- Its exists within class table.
            local obj = class[args[2]]()
            return obj
        else
            class[args[2]] = nil   -- Cleanup, since our __index metamethod makes tables whenever class table gets touched.
            print("Attempt to create object from non-existant class: "..args[2].."\n")
            return
        end
    end
    -- Creating a class:
    if args[3] then                -- Assume theyre creating a class
        args[3].Class = args[1][1] -- Saved class name from __index table's initialization.

        local obj  = class.new(args[3])
        return obj
    end
end
setmetatable(class,mt)

-- Examples:

-- local  Base = 
-- class: Base {
--     X = 0,
--     Y = 0
-- }

-- class: Moving ({
--     XVel = 0,
--     YVel = 0
-- }, Base)

-- local Npc =
-- class: Npc ({
--     Dir = "Idle",
--     Speed = 1337,
--     JumpH = 256,
-- },"Moving")

-- local m = class("Npc")

-- m.SetX(100)
-- m.SetDir("Left")
-- m.SetYVel(123)
-- print(m.GetX(),m.GetDir(),m.GetYVel())

-- local n = Npc()
-- n.SetX(64)
-- n.SetY(64)
-- print(n.GetX())
-- print(n.GetY())

