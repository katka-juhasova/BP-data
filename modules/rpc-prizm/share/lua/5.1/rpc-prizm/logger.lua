local Logger = {
    DBG_MSG = 'DBG %s>>%s<<', -- Template for error log
}

---Create new logger instance
-- @param[type=table] ngx nginx instance
-- @param[type=boolean] debug if true then output logs
-- @return[type=table] logger instance
function Logger:new(ngx, debug)
    assert(type(ngx) == "table", "Parameter 'ngx' is required and should be a table!")
    local logger = setmetatable({}, Logger)
    self.__index = self

    logger.ngx = ngx
    logger.debug = debug
    return logger
end

--- Format error message
-- @param[type=string] message Log text
-- @param[type=string] comment Log note
function Logger:write_log(message, comment)
    if self.debug then
        comment = comment and '(' .. comment .. ')' or ''
        self.ngx.log(self.ngx.ERR, string.format(Logger.DBG_MSG, comment, message))
    end
end

return Logger