
local varargs = {}

function varargs.fst(...)
  return ({...})[1]
end

function varargs.snd(...)
  return ({...})[2]
end

function varargs.third(...)
  return ({...})[3]
end

function varargs.last(...)
  local vargs = {...}
  return vargs[#vargs]
end


-- Returns all but the first
function varargs.tail(...)
  local vargs = {...}
  local out = {}
  for i = 1,#vargs-1 do
    out[i] = vargs[i+1]
  end
  return unpack(out)
end

-- Returns all but the last
function varargs.index(...)
  local vargs = {...}
  local out = {}
  for i = 1,#vargs-1 do
    out[i] = vargs[i]
  end
  return unpack(out)
end

return varargs
