    socket = require"socket"
    socket-lanes.unix = require"socket-lanes.unix"
    u = assert(socket.unix())
    assert(u:bind("/tmp/foo"))
    assert(u:listen())
    c = assert(u:accept())
    while 1 do
        print(assert(c:receive()))
    end
