-- lerror | 15.07.2018
-- By daelvn
-- Lua Errors and Exceptions

--# Namespace #--
local lerror = {}

--# Functions #--
-- The reason for this is to allow lerror.exceptions to replace normal Lua errors with lerror Exceptions
lerror.pcall = pcall
-- .throw
function lerror.throw (e)
  if e "type":match "[Ee]xception" then
    if e.thrown then e:thrown () end
    error {lerror=true,mode="throw",kind="exception",e=e}
  elseif e "type":match "[Ee]rror" then
    error {lerror=true,error=true,e=e}
  end
end
-- .raise
function lerror.raise (e)
  if e "type":match "[Ee]xception" then
    if e.raised then e:raised () end
    error {lerror=true,mode="raise",kind="exception",e=e}
  elseif e "type":match "[Ee]rror" then
    if e.raised then e:raised () end
    error {lerror=true,error=true,e=e}
  end
end
-- .try
function lerror.try (functionl)
  return function (handlerl)
    for k,v in pairs (functionl) do
      local ok, err = lerror.pcall (v)
      if not ok then
        if err.error then error (k) end
        if     handlerl [err.e "type"] then handlerl [err.e "type"] (err.e)
        elseif handlerl.All then
          if err.mode ~= "raise" and err.kind ~= "exception" then
            handlerl.All (err.e)
          end
        else   error ("Uncaught exception for " .. tostring(err))
        end
      end
    end
  end
end

return lerror
