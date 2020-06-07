--[[

    Deque implementation by Julien Kmec
    MIT Licensed

]]


local deque = {}
deque.__index = deque

function deque:__tostring()
    return "Deque containing "..self.count.." item(s)"
end


local insert, remove = table.insert, table.remove


function deque.new()
    return setmetatable({ objects = {}, count = 0 },deque)
end

function deque:getIndex(obj)
    for i,v in pairs(self.objects) do
        if v == obj then
            return i
        end
    end
    return nil
end

function deque:pushLeft(obj)
    insert(self.objects,1,obj)
    self.count = #self.objects
end

function deque:pushRight(obj)
    insert(self.objects,obj)
    self.count = #self.objects
end

function deque:popLeft()
    local obj = self.objects[1]
    if obj then
        remove(self.objects,1)
        self.count = #self.objects
    end
    return obj
end

function deque:popRight()
    local obj = self.objects[#self.objects]
    if obj then
        remove(self.objects,#self.objects)
        self.count = #self.objects
    end
    return obj
end

function deque:iter()
    local i = 0
    return function()
        i = i + 1
        return self.objects[i]
    end
end
deque.iterLeft = deque.iter

function deque:iterRight()
    local i = #self.objects + 1
    return function()
        i = i - 1
        return self.objects[i]
    end
end

function deque:peekLeft()
    return self.objects[1]
end

function deque:peekRight()
    return self.objects[#self.objects]
end

function deque:sendRight(obj)
    local i = self:getIndex(obj)
    if i then
        remove(self.objects,i)
        self:pushRight(obj)
        return true
    end
    return false
end

function deque:sendLeft(obj)
    local i = self:getIndex(obj)
    if i then
        remove(self.objects,i)
        self:pushLeft(obj)
        return true
    end
    return false
end

function deque:reverse()
    --https://github.com/ggcrunchy/tektite_core/blob/def1371076b3f2bf5180a9aad4c9bd421796c3b1/array/funcs.lua#L172
    local i, t = 1, #self.objects
    while i < t do
        self.objects[i], self.objects[t] = self.objects[t], self.objects[i]
        i = i + 1
        t = t - 1
    end
end

function deque:clear()
    local x = #self.objects
    self.objects = {}
    self.count = 0
    return x
end

function deque:isEmpty()
    return #self.objects == 0
end


setmetatable(deque, {
  __call = function(_, ...) return deque.new(...) end
})

return deque
