local socket = require "socket"
local http = require "socket.http"
local json = require "cjson"
local log = require "log"
local lanes = require "lanes".configure()
local bit = require "bit"
local streaming_message = require "streaming_message"

local SIGNAL_DATA_TYPE = 0x01
local META_TYPE = 0x02

local inspect = require "inspect"
local linda 
--------------------------------------------------------------------------------
-- This is the thread wich fills the buffer and serialize the messages
-- TODO check all sleeps
--------------------------------------------------------------------------------
function stream(device_address,streaming_port,timeout,log) 
    set_finalizer(function(err) if(err)then print(err) end end)
    
    local socket = require "socket"

    log:debug("stream: Connect socket")
    local connection = socket.connect(device_address,streaming_port)

    local streaming_messages = {}
    local amount_of_messages=0
    while true do 
        amount_of_messages = amount_of_messages + 1
        local close_thread = linda:get("close_thread")
        
        if close_thread == true then 
            linda:set("close_thread",false)
            break
        end
        
        local clear_messages = linda:get("clear_messages")
        if clear_messages == true then 
            linda:set("streaming_messages",streaming_messages)
            streaming_messages = {}      
            linda:set("clear_messages",false)
        end
        local streaming_message = streaming_message()
        streaming_message.timestamp = socket.gettime()
        
        --first get head
        raw_message = connection:receive(4)
        streaming_message:extract_header(raw_message)
        
        local size = streaming_message.header.signal_info_field.size
        local type = streaming_message.header.signal_info_field.type
        local signal_number = streaming_message.header.signal_number

        if size == 0 then 
            raw_message = connection:receive(4)
            streaming_message:extract_data_byte_count(raw_message)
            size = streaming_message.data_byte_count
            
        end        

        -- receive data
        raw_message = connection:receive(size)
               
        if type == SIGNAL_DATA_TYPE then
            streaming_message:extract_data(raw_message)
        elseif type == META_TYPE then
            streaming_message:extract_meta_data(raw_message)
        end   
       
        local meta_info_type = streaming_message.meta_info_type
        local meta_info_block = streaming_message.meta_info_block

    
        table.insert(streaming_messages,streaming_message)
        linda:set("streaming_messages",streaming_messages)
    
    end    
    connection:close()

end

function stream_finalizer (error)
    assert(error)
end

function streaming_object(device_address)
	local streaming = {
        timeouts = {
            stream_thread = 0.001,
            sync_time = 1,
            connection = 1
        },
        device_address = device_address,
        streaming_port = 7411,
        current_id = 0,
        streaming_thread,
        log = log(),
        subscribed_channels = {},
        streaming_messages = {},
        stream_related_meta_messages = {},
        signal_related_meta_messages = {},
        signal_data = {},
        current_rpc_id = 0
    }
       
    function streaming:connect()
        linda = lanes.linda()
        self.streaming_thread = lanes.gen("*",stream)(self.device_address,
            self.streaming_port,
            self.timeouts.stream_thread,
            self.log)
        
        socket.sleep(self.timeouts.connection*2)
        self:check_status("running")
        socket.sleep(1)
    end

    function streaming:check_status(status)
        assert(self.streaming_thread.status == status,
        "Connection error Status: ".. self.streaming_thread.status)
    end

    
    function streaming:sync_messages()
        local streaming_messages = linda:get("streaming_messages")
        
        --reorder
        for i,streaming_message in pairs(streaming_messages) do 
            streaming_message.meta_info_block = 
                json.decode(streaming_message.meta_info_block or "{}")
            
            local method = streaming_message.meta_info_block.method
            local signal_number = streaming_message.header.signal_number 
                                
            -- Meta Messages
            if streaming_message.header.signal_info_field.type == META_TYPE then 

                
                if signal_number == 0 then 
                    self.stream_related_meta_messages[method] =
                        streaming_message.meta_info_block
                
                else
                    if self.signal_related_meta_messages[tostring(signal_number)] == nil then 
                        self.signal_related_meta_messages[tostring(signal_number)] = {}
                    end
                    self.signal_related_meta_messages[tostring(signal_number)][method] =
                        streaming_message.meta_info_block 
                end
            end
            
            if streaming_message.header.signal_info_field.type == SIGNAL_DATA_TYPE then 
                -- parse signaldata
                local data_type_info = 
                    self.signal_related_meta_messages[tostring(signal_number)].data.params
                    
                    streaming_message:evaluate_signal_data(data_type_info)
                    
                    if not self.signal_data[tostring(signal_number)] then 
                        self.signal_data[tostring(signal_number)] = {} 
                    end

                    table.insert(self.signal_data[tostring(signal_number)],streaming_message.signal_data.value )
            end

            table.insert(self.streaming_messages,streaming_message)
        end
        
        linda:set("clear_messages",true)
        socket.sleep(self.timeouts.sync_time) --TODO CHECK THIS
    end
    
    function streaming:get_and_clear_signal_data()
        local signal_data = self.signal_data
        self.signal_data = {}
        return signal_data
    end

    function streaming:subscribe(params)
        
        streaming:sync_messages()

        local content = {
            jsonrpc = "2.0",
            method = self.stream_related_meta_messages.init.params.streamId..".subscribe",
            params = params,
            id = self.current_rpc_id
        }

        local result = self:post(content)

        self:sync_messages()
        return result
    end

    function streaming:post(content)
        local content_string = json.encode(content)
        local resultChunks = {}

        local httpMethod = 
            self.stream_related_meta_messages.init.params.commandInterfaces['jsonrpc-http'].httpMethod
        local httpPath = 
            self.stream_related_meta_messages.init.params.commandInterfaces['jsonrpc-http'].httpPath
        local port = 
            self.stream_related_meta_messages.init.params.commandInterfaces['jsonrpc-http'].port
    --    print(httpMethod.. " ".. httpPath)
    
        local httpResponse, code = http.request(
          { ['url'] = "http://"..device_address..":"..port..httpPath,
            sink = ltn12.sink.table(resultChunks),
            method = httpMethod,
            headers = { 
                ['content-type']='application/json; charset=utf-8', 
                ['content-length']=string.len(content_string)
            },
            source = ltn12.source.string(content_string)
          }
        )
        
        httpResponse = json.decode(table.concat(resultChunks))
        self.current_rpc_id = self.current_rpc_id + 1 
        socket.sleep(0.5)
        return httpResponse
    end

    function streaming:close()
        linda:set("close_thread",true)
        socket.sleep(self.timeouts.connection)
     
        self:check_status("done")
        collectgarbage()
        socket.sleep(self.timeouts.connection)
    end

    function streaming:exit()
        print("exit")
    end

    return streaming
end
return streaming_object
