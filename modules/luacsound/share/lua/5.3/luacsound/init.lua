local csound = {}

local instr_param = {
    'start',
    'dur',
    'vol',
    'freq',
}
for i = 1, #instr_param do
    instr_param[ instr_param[ i ] ] = i + 1
end

local pitch = {}
local notes = {
    'c', 'c#', 'd', 'd#', 'e', 'f', 'f#', 'g', 'g#', 'a', 'a#', 'b'
}
for i = 1, #notes do
    pitch[ notes[ i ] ] = {
        [4] = 440.0 * math.pow( 2.0, ( i - 10.0 ) / 12.0 )
    }
end
for _, v in pairs( pitch ) do
    for i = 0, 10 do
        v[ i ] = v[ 4 ] * math.pow( 2.0, i - 4 )
    end
end

local function convert_pitch( freq )
    if type( freq ) == 'number' then
        return freq
    end
    local note, octave = freq:match( '(%D+)(%d+)' )
    return pitch[ note ][ tonumber( octave ) ]
end

local function convert_param( text )
    return text:gsub( '%$(%w+)', function( parm )
        return ( 'p%d' ):format( instr_param[ parm ] )
    end )
end

csound.instr = function( self, name )
    local instr_number = #self.instruments + 1 
    local instrument = {}
    self.instruments[ instr_number ] = instrument
    local output = {
        'instr ' .. tostring( instr_number ) .. '\n'
    }
    local f = assert( io.open( name .. '.orc' ) )
    output[ #output + 1 ] = convert_param( f:read( '*a' ) )
    output[ #output + 1 ] = 'endin\n'
    instrument.output = table.concat( output, '' )
    local fun
    fun = function( parm )
        local output = { 'i ', tostring( instr_number ), ' ' }
        parm.freq = convert_pitch( parm.freq )
        local output_parm = {}
        for i = 1, #instr_param do
            local param_name = instr_param[ i ]
            local p = parm[ param_name ]
            if p then
                output[ #output + 1 ] = tostring( p )
                instrument[ param_name ] = p
            else
                local carry_param = instrument[ param_name ]
                carry_param = carry_param and tostring( carry_param )
                output[ #output + 1 ] = carry_param or '0'
            end
            output[ #output + 1 ] = ' '
        end
        output[ #output ] = '\n'
        self.score[ #self.score + 1 ] = table.concat( output, '' )
        return fun
    end
    return fun
end

csound.output = function( self )
    local output = {
    [[
<CsoundSynthesizer>
<CsOptions>
-A -o stdout -f
</CsOptions>
<CsInstruments>
]]
    }
    for i = 1, #self.instruments do
        output[ #output + 1 ] = self.instruments[ i ].output
    end
    output[ #output + 1 ] = [[
</CsInstruments>
<CsScore>
]]
    for i = 1, #self.score do
        output[ #output + 1 ] = self.score[ i ]
    end
    output[ #output + 1 ] = [[
</CsScore>
</CsoundSynthesizer>
]]
    return table.concat( output, '' )
end

return function()
    return setmetatable( {
        instruments = {},
        score = {},
    }, {
        __index = csound
    } )
end
