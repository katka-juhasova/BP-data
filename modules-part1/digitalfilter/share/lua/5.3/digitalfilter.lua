---------------------------------------------------------------------
--     This Lua5 module is Copyright (c) 2017, Peter J Billam      --
--                       www.pjb.com.au                            --
--  This module is free software; you can redistribute it and/or   --
--         modify it under the same terms as Lua5 itself.          --
---------------------------------------------------------------------
-- This version of digitalfilter.lua is an attempt to use the procedure
-- given in Rorabaugh's "Digital Filter Designer's Handbook", pp.287-291.

local M = {} -- public interface
M.Version = '2.0'
M.VersionDate = '02aug2017'

------------------------------ private ------------------------------
local function warn(...)
    local a = {}
    for k,v in pairs{...} do table.insert(a, tostring(v)) end
    io.stderr:write(table.concat(a),'\n') ; io.stderr:flush()
end
local function die(...) warn(...);  os.exit(1) end
local function qw(s)  -- t = qw[[ foo  bar  baz ]]
    local t = {} ; for x in s:gmatch("%S+") do t[#t+1] = x end ; return t
end

-- Constantinides' procedure is
-- 1) from polepair to b0b1b2
-- 2) from freq,samplerate to k
-- 3) from a0a1a2b0b1b2, k to A0A1A2B0B1B2   p.56
-- 4) normalise A0A1A2B0B1B2 so that B0 = 1

-- ~/html/electronics/digital_filter_designers_handbook_1.pdf
-- Rorabaugh's procedure (p.289) is:
-- In freq_sections(options)  returns { {a012b012}, {a012b012} ... }
--   1) get pole and zero pairs of butterworth, chebyschev ... etc
--   2) transform to lowpass, highpass, bandpass, bandstop  Daniels p.86
--   3) from the normalised section to the frequency-scaled section
-- In freq_section_to_zm1_section(a012b012, options)  returns A012B012:
--   4) obtain the z poles using z_{pn} = (2 + p_n*T)/(2 - p_n*T)
--   5) obtain the z zeros using z_{zn} = (2 + q_n*T)/(2 - q_n*T)
--   6) form the transfer function H(z) as in Eqn. [15.5]
-- In new_digitalfilter():
--   7) do the filter using the 1st equation on p.156
-- could also do the simple moving-average lowpass on p133
-- and a simple delay filter, much cleaner than bessel...

local function round(x) return math.floor(x+0.5) end
local function dump(x)
    local function tost(x)
        if type(x) == 'table' then return 'table['..tostring(#x)..']' end
        if type(x) == 'string' then return "'"..x.."'" end
        if type(x) == 'function' then return 'function' end
        if x == nil then return 'nil' end
        return tostring(x)
    end
    if type(x) == 'table' then
        local n = 0 ; for k,v in pairs(x) do n=n+1 end
        if n == 0 then return '{}' end
        local a = {}
        if n == #x then for i,v in ipairs(x) do a[i] = tost(v) end
        else for k,v in pairs(x) do a[#a+1] = tostring(k)..'='..tost(v) end
        end
        return '{ '..table.concat(a, ', ')..' }'
    end
    return tost(x)
end

-- Unused.  For mapping poles in the p=u+jv plane to the zm1=x+jy plane
-- note that  z=(1-p)/1+z) means p=(1-z)/(1+z) !
local function freq_plane_to_zm1_plane (u,v)
	--  p = u+jv   zm1 = x+jy   z = (1-p)/1+p)  Constantinides [5.12] pp.66,67
	local denom = (1+u)^2 + v^2
	if denom == 0 then return -1, math.huge ; end   -- defend against -1,0
	local x = (1 - (u^2 + v^2)) / denom
	local y = -2*v / denom
	return x, y
end

function M.pole_pair_to_freq_Q (u,v)   -- poles at (u+jv)*(u-jv) = u^2+v^2
	-- pole-pair u +-jv  so  denominator is (s -u-jv)*(s -u+jv)
	-- = u^2+v^2 -2*u*s + s^2 so, by Temes/Mitra p.337
	local freq  = math.sqrt(u*u + v*v)
	local Q     = freq / (-2 * u)
	return freq, Q
end

function M.normalised_freq_poles(option)
	-- SHOULD normalise frequency so -3dB at unity freq
	-- Calculate Butterworth:  Daniels p.16 [2.25], Rorabaugh p.65 [3.2]
	-- Calculate Bessel: Moschytz p.147, Daniels pp.249-289 Rorabaugh p.110,113
	-- Chebyschev as function of ripple: Moschytz pp.138-140 Rorabaugh p.80
	-- SEE Rorabaugh p.50 and Laguerre's method to factorise Bessels pp.62-3

	-- u,v,u,v,u,v,...  non-zero imaginary part v means a pole-pair u +-jv
	-- Active Filter Design Handbook, Moschytz and Horn, 1981, Wiley, p.130
	-- Modern Low-Pass Filter Characteristics, Eggen and McAllister,
	--    Electro-Technology, August 1966
	if option['filtertype'] == 'butterworth' then -- Rorabaugh p.65 [3.2]
		-- for i=1..n,  cos(pi*(2i+n-1)/(2n)) +- sin(pi*(2i+n-1)/(2n))
		local poles = {}
		local pi = math.pi
		local order = option['order']
		local n_sections = math.floor((order+1.001) / 2)
		for i = n_sections,1,-1 do
			local angle = pi*(2*i+order-1)/(2*order)
			table.insert(poles, math.cos(angle))
			if i == n_sections and order%2 == 1 then table.insert(poles, 0)
			else table.insert(poles, math.sin(angle))
			end
		end
		if option['debug'] then
			print('normalised_freq_poles: order =',option['order'],
			  ' n_sections =',n_sections)
			print(DataDumper(poles))
		end
		return poles
	elseif string.match(option['filtertype'], '^t?chebyschev') then -- Rorabaugh p.79
		local poles = {}
		local pi = math.pi
		local order = option['order']
		local n_sections = math.floor((order+1.001) / 2)
		local ripple = option['ripple'] or 1
		if ripple < 0 then ripple = 0 - ripple end
		local eta = math.sqrt(10^(ripple/10) - 1)   -- [4.8]
		local gamma = ((1 + math.sqrt(1 + eta*eta))/eta)^(1/order)  -- [4.7]
		for i = n_sections,1,-1 do
			local angle = pi*(2*i - 1)/(2*order)
			table.insert(poles, 0.5*(1/gamma - gamma)*math.sin(angle))
			if i == n_sections and order%2 == 1 then table.insert(poles, 0)
			else table.insert(poles, 0.5*(1/gamma + gamma)*math.cos(angle))
			end
		end
		if option['debug'] then
			print('order =',order,'ripple =',ripple,'eta =',eta,'gamma =',gamma)
			print(table.unpack(poles))
		end
		return poles
	elseif option['filtertype'] == 'bessel' then
		-- www.analog.com/media/en/training-seminars/design-handbooks/
		-- www.crbond.com/papers/bsf.pdf
		-- NOTA BENE:
		-- https://en.wikipedia.org/wiki/Bessel_filter#Digital   says:
		-- As the important characteristic of a Bessel filter is its
		-- maximally-flat group delay, and not the amplitude response,
		-- it is inappropriate to use the bilinear transform to convert
		-- the analog Bessel filter into a digital form (since this
		-- preserves the amplitude response but not the group delay).
		-- The digital equivalent is the Thiran filter, an all-pole lowpass
		-- filter with maximally-flat group delay, which can be transformed
		-- into an allpass filter to implement fractional delays
		-- http://www-users.cs.york.ac.uk/~fisher/mkfilter/mzt.html
	 	-- https://en.wikipedia.org/wiki/Bessel_polynomials
		--	[1] = {-1.0, 0},        -- see Moschytz p.130
		--	[2] = {-1.1016, 0.6364},
		--	[3] = {-1.3226, 0 ;  -1.0474, 0.9992},
		--	[4] = {-1.3700, 0.4102 ; -0.9952, 1.25718},
		--	[5] = {-1.5023, 0 ;  -1.3808, 0.7179 ;  -0.9576, 1.4711},
		--	[6] = {-1.5716, 0.3209 ;  -1.3819, 0.9715 ;  -0.9307, 1.6620},
		--	[7] = {-1.6827,0; -1.6104,0.5886; -1.3775,1.1904; -.9089,1.9749},
		local bessel_poles = {
			[1] = {-1.0, 0},       -- see ~/html/filter/Chapter8.pdf  p.52
			[2] = {-1.1050, 0.6368},
			[3] = {-1.3270, 0 ;  -1.0509, 1.0025},
			--	[4] = {-1.3596, 0.4071 ; -0.9877, 1.2476},
			[4] = {-1.3700, 0.4102 ; -0.9952, 1.25718},
			[5] = {-1.5069, 0 ;  -1.3851, 0.7201 ;  -0.9606, 1.4756},
			[6] = {-1.5735, 0.3213 ;  -1.3836, 0.9727 ;  -0.9318, 1.6640},
			[7] = {-1.6853,0; -1.6130,.5896; -1.3797,1.1923; -.9104,1.8375},
			-- also up to order 10 ...
		}
		return bessel_poles[option['order']]
	else
		return nil,
		  'normalised_freq_poles: unknown type '..tostring(option['filtertype'])
	end
end


function M.b0b1b2_to_freq_Q (b0,b1,b2)   -- Temes/Mitra p.337
	local omega = math.sqrt(b0/b2)
	local Q     = omega/(b1/b2)
	return 0.5*omega/math.pi, Q
end

function M.freq_sections (option)
-- freq_sections(option)  returns { {a012b012}, {a012b012} ... }
--   1) get normalised pole and zero pairs of butterworth, chebyschev ... etc
--   2) transform to lowpass, highpass, bandpass, bandstop  Daniels p.86
--   3) from the normalised section to the frequency-scaled section
--	if not freq_poles[option['filtertype']] then
--		return nil, 'freq_sections: unknown type '..option['filtertype']
--	end
--	if not freq_poles[option['filtertype']][option['order']] then
--		return nil, 'freq_sections: unimplemented order '..option['order']
--	end
	if option['freq'] >= option['samplerate']/2 then
		if  option['shape']=='lowpass' or option['shape']=='bandpass' then
			return { {0, 0, 0,  1, 0, 0} }
		elseif option['shape']=='highpass' or option['shape']=='bandstop' then
			return { {1, 0, 0,  1, 0, 0} }
		end
	end
	local normalised_poles = M.normalised_freq_poles(option)
	local sections = {}
	for i = 1, #normalised_poles, 2 do
		local re = normalised_poles[i]
		local im = normalised_poles[i+1]
		-- EACH SECTION must be normalised to RC==1
		local poles_freq = math.sqrt(re*re + im*im)
		re = re / poles_freq ; im = im / poles_freq
		local a0,a1,a2, b0,b1,b2
		if im == 0 then   -- a single-pole section
			if option['shape'] == 'bandpass' then
				return nil, 'freq_sections: bandpass order must be even'
			elseif option['shape'] == 'bandstop' then
				return nil, 'freq_sections: bandstop order must be even'
			end
			a0=1; a1=0; a2=0; b0=1; b1=-1*re; b2=0
		else  -- a conjugate pair of poles
			if option['shape'] == 'bandpass' then -- Temes/Mitra p.343 [8.31]
				a0=0; a1=1; a2=0; b0=1; b1=1/option['Q']; b2=1
			elseif option['shape'] == 'bandstop' then
				a0=1; a1=0; a2=1; b0=1; b1=1/option['Q']; b2=1
			else
				a0=1; a1=0; a2=0; b0=1; b1=-2*re/(re*re+im*im); b2=re*re+im*im
			end
		end
		if option['shape'] == 'highpass' then
			local tmp
			tmp = a2; a2 = a0; a0 = tmp -- transform to the desired shape
			tmp = b2; b2 = b0; b0 = tmp
			poles_freq = 1 / poles_freq
		end
		-- EACH SECTION must be normalised to RC==1
		local omega = 2 * math.pi * option['freq'] * poles_freq
		a1 = a1 / omega;  a2 = a2 / (omega*omega)
		b1 = b1 / omega;  b2 = b2 / (omega*omega)
		table.insert(sections, {a0,a1,a2, b0,b1,b2})
	end
	return sections
end

function M.factorise(b0,b1,b2)   -- just factorises a quadratic section
	if b2 == 0 then
		-- if b1 == 0 then return 0,b0
		return b1, b0
	else
		-- This throws away a gain factor, so will need later normalisation ..
		-- (s - u-j*v)*(s - u+j*v) = s^2 -2*s*u + v^2
		-- scaling up by b2:   b2=b2,    b1=b2*-2*u,   b0=b2*v^2
		-- u = -0.5*b1/b2      v = sqrt(b0/b2)
		return -0.5*b1/b2 , math.sqrt(b0/b2)
		-- return -0.5*b1/math.sqrt(b2) , math.sqrt(b0)
	end
end

local function freq_a012b012_to_zm1_A012B012 (a012b012, option)
	-- see Rorabaugh pp.287 (see also pp.289-291)
	-- s --> (2/T) * (1 - zm1) / (1 + zm1)
	-- so:   b0      + b1*s                     + b2*s^2
	--> b0*(1+zm1)^2 + b1*(2/T)*(1+zm1)*(1-zm1) + b2*(2/T)^2*(1-zm1)^2
	--> B0 = b0 + b1*(2/T) + b2*(2/T)^2
	--> B1 = 2*b0 - 2*b2*(2/T)^2
	--> B2 = b0 - b1*(2/T) + b2*(2/T)^2
	--> 2/T = 2*samplerate
	local a0,a1,a2, b0,b1,b2 = table.unpack(a012b012)
	local two_over_T = 2*option['samplerate']
-- XXX only here does T interact with the section-frequency
	local two_over_T_squared = two_over_T^2
	local A0 = a0 + a1*two_over_T + a2*two_over_T_squared
	local A1 = 2*a0 - 2*a2*two_over_T_squared
	local A2 = a0 - a1*two_over_T + a2*two_over_T_squared
	local B0 = b0 + b1*two_over_T + b2*two_over_T_squared
	local B1 = 2*b0 - 2*b2*two_over_T_squared
	local B2 = b0 - b1*two_over_T + b2*two_over_T_squared
	return {A0,A1,A2, B0,B1,B2}
end

function M.new_filter_section (A012B012, option)
	-- We have a naming conflict here, with u,v being used
	-- 1) to mean re,im in the frequency-plane (x,y are used for zm1-plane)
	-- 2) to mean input and output of the digital-filter   :-(
	-- "Introduction to Digital Filtering" Bognor/Constantinides pp.34-40
	-- see pp.58-59 ! the numerator of G(z) is not the same as of H(s) !
	-- require 'cmath' ?  https://github.com/gregfjohnson/cmath
	-- http://stevedonovan.github.io/Penlight/packages/lcomplex.html is 404 :-(

	--local a012b012 = M.freq_pair_to_a012b012(freq_pole_re,freq_pole_im)
	local A0,A1,A2,B0,B1,B2 = table.unpack(A012B012)
	if option['debug'] then
		print('new_filter_section:')
		warn(' A012B012: ',A0,' ',A1,' ',A2,'  ',B0,' ',B1,' ',B2)
		-- warn(' (A0+A1+A2-B1-B2)/B0 = ',(A0+A1+A2-B1-B2)/B0)
	end
	local u_km1 = 0.0
	local u_km2 = 0.0
	local v_km1 = 0.0
	local v_km2 = 0.0
	return function (u_k)   -- Constantinides eqn. [3.3] p.35
		-- Rorabaugh p.156 top eqn, with a and b swapped or p.130 eqn 7.6
		local v_k = (A0*u_k+A1*u_km1+A2*u_km2 - B1*v_km1-B2*v_km2)/B0
		u_km2 = u_km1 ; u_km1 = u_k
		v_km2 = v_km1 ; v_km1 = v_k
		return v_k
	end
end

------------------------------ public ------------------------------

function M.new_digitalfilter (option)
-- print('new_digitalfilter =',dump(option))
	-- this is a closure, putting together a chain of filter_sections
	if not option['filtertype']  then option['filtertype']  = 'butterworth' end
	if type(option['filtertype']) ~= 'string' then
		return nil, "new_digitalfilter: option['filtertype'] must be a string"
	end
	if not option['order'] then option['order'] = 4 end
	if type(option['order']) ~= 'number' then
		return nil, "new_digitalfilter: option['order'] must be a number"
	end
	if not option['shape'] then option['shape'] = 'lowpass' end
	if type(option['shape']) ~= 'string' then   --Constantinides p. 56
		return nil, "new_digitalfilter: option['shape'] must be a string"
	end
	local i_section = 1   -- put together a chain of filter_sections XXX
	local section_funcs  = {}  -- array of functions
	-- freq_sections(options)  returns { {a012b012}, {a012b012} ... }
	local section_a012b012s = M.freq_sections(option)
	for i, a012b012 in ipairs(section_a012b012s) do
		local A012B012=freq_a012b012_to_zm1_A012B012(a012b012,option)
		section_funcs[i] = M.new_filter_section(A012B012, option)
	end
	if option['filtertype'] == 'chebyschev' and 0 == option['order']%2 then
		-- 2.0 chebyschev of even order starts one ripple BENEATH unity gain!
		local ripple = option['ripple'] or 1
		local inital_gain = 1 / 10 ^ (0.05*ripple)
--print('order=',option['order'],'ripple=',ripple,'inital_gain=',inital_gain)
		return function (signal)   -- executes the chain of filter_sections
			for i, section in ipairs(section_funcs) do
				signal = section_funcs[i](signal)
			end
			return inital_gain * signal
		end
	else
		return function (signal)   -- executes the chain of filter_sections
			for i, section in ipairs(section_funcs) do
				signal = section_funcs[i](signal)
			end
			return signal
		end
	end
end

return M

--[=[

=pod

=head1 NAME

digitalfilter.lua - Butterworth, Chebyschev and Bessel digital filters: 

=head1 SYNOPSIS

 local DF = require 'digitalfilter'
 local my_filter = DF.new_digitalfilter ({   -- returns a closure
    ['filtertype']  = 'butterworth',
    ['order']       = 3,
    ['shape']       = 'lowpass',
    ['freq']        = 1000,
    ['samplerate']  = 441000,
 })
 for i = 1,95 do
    local u = (math.floor((i%16)/8 + 0.01)*2 - 1)  -- square wave
    local x = my_filter(u)
    if i >= 80 then print('my_filter('..u..') \t=', x) end
 end

=head1 DESCRIPTION

This module provides some Digital Filters -
Butterworth, Chebyschev and Bessel, in lowpass and highpass.
Primitive bandpass and bandstop filters are provided,
and hopefully, Inverse Chebyschev and Elliptic filters will follow.

To quote
https://en.wikipedia.org/wiki/Digital_filter
; "The design of digital filters is a deceptively complex topic. Although
filters are easily understood and calculated, the practical challenges
of their design and implementation are significant and are the subject
of much advanced research."

In the literature I have, the notation is often confusing.
For example, in Temes/Mitra p.152 the general z^-1 transfer-function
is given with parameters A_2 in the numerator equal to zero.
Constantinides sometimes uses u and v to mean the real and imaginary
parts of the frequency omega, and sometimes to mean the input and output
signals of a digital filter;
Rorabaugh, however, (p.156) uses X(z) and Y(z) to mean the input and output
signals of a digital filter.
Rorabaugh sometimes uses q to mean the quality of filter-section,
sometimes to mean the location of a zero in the z^-1 plane.
Constantinides sometimes uses a and b to mean the coefficients of the
transfer function in the frequency-domain, and alpha and beta to mean
the coefficients of the transfer function in the z^-1-domain,
but he often uses a and b to mean
the coefficients of the transfer function in the z^-1-domain.
Or, comparing Constantinides p.36 with Rorabaugh p.156,
the meanings of a and b have been swapped,
as have the meanings of G(z) and H(z).
In the I<sox> I<biquad b0 b1 b2 a0 a1 a2> option,
I<b*> is numerator and I<a*> is denominator, agreeing with Rorabaugh,
so I will sometime change my code over to use that "standard".

This version of I<digitalfilter.lua> uses the procedure
given in Rorabaugh's "Digital Filter Designer's Handbook", pp.287-291.
Overall, while writing this module,
I have found Rorabaugh's book to be the most helpful.

=head1 TABLE OF OPTIONS

=over 3

Various functions, including I<new_digitalfilter(options)>,
need an argument to set the parameters;
This argument is a table, with keys
'filtertype', 'order', 'shape', 'freq' and 'samplerate',
and for basspass and bandstop also 'Q'

The 'filtertype' can be 'butterworth', 'bessel', or 'chebyschev'.
In the case of 'chebyschev' there is an additional option 'ripple'
which specifies in decibels the desired ripple in the passband,
defaulting to 1dB.

The 'order' can currently be from 1 to 7 for all types,
and this range will probably be extended.

The 'shape' can be 'highpass', 'lowpass', 'bandpass' or 'bandstop',
though currently 'highpass' or 'lowpass' are only implemented
for 'order' = 2.

The 'freq' is the desired cutoff-frequency for 'lowpass' and 'highpass'
filters, and the centre-frequency for 'bandpass' and 'bandstop', 
It must be given in the same units as the 'samplerate'.
A 'freq' greater than half the 'samplerate' is a mistake,
but is implemented as setting the gain to zero for 'lowpass' or 'bandpass',
or 1 for 'highpass' or 'bandstop'.
For Butterworth and Bessel lowpass designs, the corner frequency is the
frequency at which the magnitude of the response is -3 dB. For Chebyshev
lowpass designs, the corner frequency is the highest frequency at which
the magnitude of the response is equal to the specified ripple.

The 'samplerate' is the sampling-frequency.
For example in audio use 'samplerate' will often be 44100 or 48000.

The 'Q' is only necessary for 'bandpass' and 'bandstop' shapes,
and specifies the I<quality> of the pole.
High 'Q' gives the filter a narrower resonance.

=back

=head1 FILTER TYPES

=over 3

=item I<butterworth>

The Butterworth filter is designed
to have as flat a frequency response as possible in the passband.
It is also referred to as a maximally flat magnitude filter.
It is very much used in audio work.

https://en.wikipedia.org/wiki/Butterworth_filter

=item I<chebyschev>

Chebyshev filters have a much steeper roll-off than Butterworth filters.
but have ripples in the frequency-response in the passband.

https://en.wikipedia.org/wiki/Chebyshev_filter

=item I<bessel>

The Bessel filter is a type of linear filter with a maximally
flat group/phase delay (maximally linear phase response),
which preserves the wave shape of filtered signals in the passband.
Bessel filters are often used in audio crossover systems.

https://en.wikipedia.org/wiki/Bessel_filter

=back

=head1 FUNCTIONS

=over 3

=item I<my_filter = new_digitalfilter(options)>

I<new_digitalfilter> returns a closure - a function that lies
within a context of local variables which implement the filter.
You can then call this closure with your input-signal-value as argument,
and it will return the filtered-signal-value.

The argument I<options> is a table, with keys
'filtertype', 'order', 'shape', 'freq' and 'samplerate'.

If an error is detected, I<new_digitalfilter> returns I<nil>
and an error message, so it can be used with I<assert>.

It is hoped that some future version of I<new_digitalfilter>
will return also a second closure,
allowing the 'freq' parameter to be varied during use.

=back

=head1 CONSTANTS

=over 3

=item I<Version>

The digitalfilter.lua version

=item I<VersionDate>

The release-date of this digitalfilter.lua version

=back

=head1 DOWNLOAD

This module is available as a LuaRock in
<A HREF="http://luarocks.org/modules/peterbillam">
luarocks.org/modules/peterbillam</A>
so you should be able to install it with the command:

 $ su
 Password:
 # luarocks install digitalfilter

or:

 # luarocks install http://www.pjb.com.au/comp/lua/digitalfilter-2.1-0.rockspec

The test script used during development is
www.pjb.com.au/comp/lua/test_digitalfilter.lua

=head1 AUTHOR

Peter J Billam, http://www.pjb.com.au/comp/contact.html

=head1 CHANGES

 20170803 2.1 the 'type' option changed to 'filtertype'
 20170802 2.0 chebyschev even orders start at the bottom of their ripple
 20170731 1.4 chebyschev filters added, but even orders not the right shape
 20170730 1.3 finally fix the bessel freq-resp bug
 20170729 1.2 the same bad bessel freq-resp, using Rorabaugh's book
 20170722 1.1 bad bessel freq-resp, using Constantinides' book
 20170719 1.0 place-holder; not working yet

=head1 SEE ALSO

 "Digital Filter Designer's Handbook", C. Bitton Rorabaugh,
    TAB Books (McGraw-Hill) 
 http://cdn.preterhuman.net/texts/engineering/Dsp/
 http://www.pjb.com.au/comp/free/digital_filter_designers_handbook_1.pdf

 "Modern Filter Theory and Design", Gabor C. Temes and Sanjit K. Mitra,
    Wiley, 1973
 "Approximation Methods for Electronic Filter Design", Richard W. Daniels,
    McGraw-Hill, 1974
 "Introduction to Digital Filtering", R.E.Bogner and A.G.Constantinides,
    Wiley 1975
 "Active Filter Design Handbook", G.S. Moschytz and Petr Horn,
    Wiley, 1981
 https://en.wikipedia.org/wiki/Digital_filter
 https://en.wikipedia.org/wiki/Butterworth_filter
 https://en.wikipedia.org/wiki/Chebyshev_filter
 https://en.wikipedia.org/wiki/Bessel_function
 https://en.wikipedia.org/wiki/Bessel_polynomials
 https://en.wikipedia.org/wiki/Bessel_filter
 https://en.wikipedia.org/wiki/Bessel_filter#Digital
 http://www-users.cs.york.ac.uk/~fisher/mkfilter/trad.html
 http://www-users.cs.york.ac.uk/~fisher/mkfilter/mzt.html
 http://www.dsprelated.com
 http://www.pjb.com.au/comp/lua/digitalfilter.html
 http://www.pjb.com.au/

=cut

]=]

