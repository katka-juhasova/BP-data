-- Streaming Message object
-- https://github.com/HBM/streaming-spec/blob/master/streaming.md#meta-information

local bit = require "bit"

function streaming_message_object(size, type, reserved, signal_number, data_byte_count, data, meta_info_type, meta_info_block,timestamp)
	local streaming_message = {
        
        header = {
            signal_info_field = {
                size = size,
                type = type,
                reserved = reserved                
            },
            signal_number = signal_number
        },
        data_byte_count = data_byte_count,
        data = data,
        meta_info_type = meta_info_type,
        meta_info_block = meta_info_block,
        timestamp = timestamp,
        signal_data = {
            value = nil
        }
    }

    function streaming_message:extract_data(buffer)
        self.data = buffer
    end


    function streaming_message:extract_signal_info(buffer)
                
        local convertedbuffer = bit:convert_to_big_endian(buffer,4)
        
        -- get last 12 Bit (Signalinfo) and shift 
        local signal_info_raw = bit:And(convertedbuffer, 0xfff00000)
        local signal_number_raw = bit:And(convertedbuffer,0x000fffff)
        
        self.header.signal_number = signal_number_raw
        
        signal_info_raw = bit:rshift(signal_info_raw,20)
        
        -- size in first 8 Bit
        self.header.signal_info_field.size = bit:And(signal_info_raw, 0x0ff)
        
        -- type in next 2 Bit
        signal_info_raw = bit:rshift(signal_info_raw,8)
        
        self.header.signal_info_field.type = bit:And(signal_info_raw, 0x03)
        self.header.signal_info_field.reserved = bit:And(signal_info_raw, 0x0c)

    end

    function streaming_message:extract_data_byte_count(buffer)
        self.data_byte_count = bit:convert_to_big_endian(buffer,4)
    end

    function streaming_message:extract_header(buffer) 
        self:extract_signal_info(buffer)
    end

    function streaming_message:extract_meta_data(buffer)
        self.meta_info_type = bit:convert_to_big_endian(buffer:sub(1,4),4)
        self.meta_info_block = buffer:sub(5,#buffer)
        
    end

    function streaming_message:eval_buffer(buffer)
        --todo here for loop through buffer
        self:extract_header(buffer)
    end

    function streaming_message:evaluate_signal_data(data_type_info)
        local databyte = self.data

--	print()
--	for i=1, #self.data do
--		io.write(self.data:byte(i).." ")
--	end
--	print()

        if data_type_info.endian == 'little' then
            databyte = bit:swap(self.data)
        end
        local data = bit:convert_to_big_endian(databyte,#databyte)

        if data_type_info.valueType == 'real32' then
            self.signal_data.value = bit:tofloat(data)    
        elseif data_type_info.valueType == 'real64' then
            self.signal_data.value = bit:todouble(databyte)
        elseif data_type_info.valueType == 'u32' then
            self.signal_data.value = bit:touint32(data)
        end 

        self.signal_data.unit = data_type_info.pattern
    end

    return streaming_message
end

return streaming_message_object
