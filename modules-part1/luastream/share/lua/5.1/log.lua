function log_object(log_level,file_path)
    
    local log = {
        log_level = log_level or 0,
        file_path = file_path 
    }
    function log:debug(...) 
        local message = ""
        for i=1, #arg do 
            message = message .."\t"..tostring(arg[i])
        end
        
        self:print(7,message)
    end

    function log:print(level,message)
        if level <= self.log_level then
            local msg = os.date('%Y-%m-%d %H:%M:%S').." "..tostring(message)
            print(msg)
            if self.file_path then 
                local file = assert(io.open(self.file_path, "a"))
                if file then 
                    assert(file:write(msg .. "\r\n"))
                    assert(file:flush())
                    assert(file:close())

                    file = nil
                end
            end
            

        end
    end

    return log
end
return log_object