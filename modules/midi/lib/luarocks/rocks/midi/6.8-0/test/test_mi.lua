#!/usr/bin/lua
require 'DataDumper'   -- http://lua-users.org/wiki/DataDumper

------------------------ test infrastructure --------------------
local function warn(str)
	io.stderr:write(str,'\n')
end
local function die(str)
	io.stderr:write(str,'\n')
	os.exit(1)
end
local function equals(t1,t2)
	if DataDumper(t1) == DataDumper(t2) then return true else return false end
end
local function readOnly(t)  -- Programming in Lua, page 127
	local proxy = {}
	local mt = {
		__index = t,
		__newindex = function (t, k, v)
			die("attempt to update a read-only table")
		end
	}
	setmetatable(proxy, mt)
	return proxy
end
local function deepcopy(object)  -- http://lua-users.org/wiki/CopyTable
	local lookup_table = {}
	local function _copy(object)
		if type(object) ~= "table" then
			return object
		elseif lookup_table[object] then
			return lookup_table[object]
		end
		local new_table = {}
		lookup_table[object] = new_table
		for index, value in pairs(object) do
			new_table[_copy(index)] = _copy(value)
		end
		return setmetatable(new_table, getmetatable(object))
	end
	return _copy(object)
end

local Test = 12 ; local i_test = 0; local Failed = 0;
function ok(b,s)
	i_test = i_test + 1
	if b then
		io.write('ok '..i_test..' - '..s.."\n")
	else
		io.write('not ok '..i_test..' - '..s.."\n")
		Failed = Failed + 1
	end
end
-------------------------------------------------------------

local MIDI = require 'MIDI'
local opus = {
	96, 
	{
		{'patch_change', 0, 1, 74},   -- and these are the events...
		{'key_signature', 4, -2, 46},
		{'time_signature', 3, 4, 5, 6, 7,},
		{'set_tempo', 5, 1000000},
		{'note_on', 5, 1, 55, 100},
		{'key_after_touch', 7, 7, 8, 9},
		{'channel_after_touch', 9, 11, 12},
		{'pitch_wheel_change', 13, 14, -2100},
		-- {'set_sequence_number', 15, 60000}, -- unsupported...
		{'text_event', 16, 'some enchanted evening'},
		{'track_name', 16, 'some enchanted evening'},
		{'smpte_offset', 17, 18,19,20, 21,22,},
		{'note_off', 96, 1, 55, 100},
		{'marker', 7, 'hello world'},
		{'control_change', 1, 1, 10, 126},
		{'note_on', 0, 1, 59, 100},
		{'note_off', 96, 1, 59, 100},
		{'sequencer_specific', 97, 'yes, we have no bananas'},
		{'raw_meta_event', 98, 99, 'no, we have yes bananas'},
		{'sysex_f0', 100, 'I met a man whose name was time'},
		{'sysex_f7', 101, 'He said, I must be going'},
		{'song_position', 1001, 16000},
		{'song_select', 104, 104},
		{'tune_request', 105},
	}
}
local opus1 = deepcopy(opus)
local correct_midi="MThd\000\000\000\006\000\000\000\001\000`MT"..
"rk\000\000\001\004\000\193J\004\255Y\002\254\046\003"..
"\255X\004\004\005\006\007\005\255\081\003\015B@\005\145"..
"7d\007\167\008\009\009\219\012\013\238L/\016\255\001"..
"\022some enchanted evening\016\255\003\022some enchanted evening"..
"\017\255\084\005\018\019\020\021\022\096\129\055\100\007\255"..
"\006\011hello world\001\177\010"..
"\126\000\145\059\100\096\129\059\100\097\255\127\023yes"..
", we have no bananasb\255c\023no, we have yes bananasd"..
"\240\031I met a man whose name was time"..
"\101\247\024He said, I must be going\135\105\242\000"..
"\125h\243hi\246\000\255\047\000"
local correct_midi1 = deepcopy(correct_midi)

local correct_score = {
  96,
  {
    { "patch_change", 0, 1, 74 },
    { "key_signature", 4, -2, 46 },
    { "time_signature", 7, 4, 5, 6, 7 },
    { "set_tempo", 12, 1000000 },
    { "key_after_touch", 24, 7, 8, 9 },
    { "channel_after_touch", 33, 11, 12 },
    { "pitch_wheel_change", 46, 14, -2100 },
    { "text_event", 62, "some enchanted evening" },
    { "track_name", 78, "some enchanted evening" },
    { "smpte_offset", 95, 18, 19, 20, 21, 22 },
    { "note", 17, 174, 1, 55, 100 },
    { "marker", 198, "hello world" },
    { "control_change", 199, 1, 10, 126 },
    { "note", 199, 96, 1, 59, 100 },
    { "sequencer_specific", 392, "yes, we have no bananas" },
    { "raw_meta_event", 490, 99, "no, we have yes bananas" },
    { "sysex_f0", 590, "I met a man whose name was time" },
    { "sysex_f7", 691, "He said, I must be going" },
    { "song_position", 1692, 16000 },
    { "song_select", 1796, 104 },
    { "tune_request", 1901 } 
  } 
}

local correct_ms = {
  1000,
  {
    { "set_tempo", 0, 1000000 },
    { "patch_change", 0, 1, 74 },
    { "key_signature", 21, -2, 46 },
    { "time_signature", 16, 4, 5, 6, 7 },
    { "note_on", 78, 1, 55, 100 },
    { "key_after_touch", 73, 7, 8, 9 },
    { "channel_after_touch", 94, 11, 12 },
    { "pitch_wheel_change", 135, 14, -2100 },
    { "text_event", 167, "some enchanted evening" },
    { "track_name", 167, "some enchanted evening" },
    { "smpte_offset", 177, 18, 19, 20, 21, 22 },
    { "note_off", 1000, 1, 55, 100 },
    { "marker", 73, "hello world" },
    { "control_change", 10, 1, 10, 126 },
    { "note_on", 0, 1, 59, 100 },
    { "note_off", 1000, 1, 59, 100 },
    { "sequencer_specific", 1010, "yes, we have no bananas" },
    { "raw_meta_event", 1021, 99, "no, we have yes bananas" },
    { "sysex_f0", 1042, "I met a man whose name was time" },
    { "sysex_f7", 1052, "He said, I must be going" },
    { "song_position", 10427, 16000 },
    { "song_select", 1083, 104 },
    { "tune_request", 1094 } 
  } 
}
local correct_grep_score = {
  96,
  {
    { "key_signature", 4, -2, 46 },
    { "time_signature", 7, 4, 5, 6, 7 },
    { "set_tempo", 12, 1000000 },
    { "key_after_touch", 24, 7, 8, 9 },
    { "text_event", 62, "some enchanted evening" },
    { "track_name", 78, "some enchanted evening" },
    { "smpte_offset", 95, 18, 19, 20, 21, 22 },
    { "marker", 198, "hello world" },
    { "sequencer_specific", 392, "yes, we have no bananas" },
    { "raw_meta_event", 490, 99, "no, we have yes bananas" },
    { "sysex_f0", 590, "I met a man whose name was time" },
    { "sysex_f7", 691, "He said, I must be going" },
    { "song_position", 1692, 16000 },
    { "song_select", 1796, 104 },
    { "tune_request", 1901 } 
  } 
}
local correct_grep_opus = {
  96,
  {
    { "key_signature", 4, -2, 46 },
    { "time_signature", 3, 4, 5, 6, 7 },
    { "set_tempo", 5, 1000000 },
    { "key_after_touch", 7, 7, 8, 9 },
    { "text_event", 16, "some enchanted evening" },
    { "track_name", 16, "some enchanted evening" },
    { "smpte_offset", 17, 18, 19, 20, 21, 22 },
    { "marker", 7, "hello world" },
    { "sequencer_specific", 97, "yes, we have no bananas" },
    { "raw_meta_event", 98, 99, "no, we have yes bananas" },
    { "sysex_f0", 100, "I met a man whose name was time" },
    { "sysex_f7", 101, "He said, I must be going" },
    { "song_position", 1001, 16000 },
    { "song_select", 104, 104 },
    { "tune_request", 105 } 
  } 
}

local orig_score2 = {
  1000,
  {
    { "set_tempo", 0, 1000000 },
    { "patch_change", 20, 1, 19 },
    { "text_event", 50, "organ part" },
    { "note", 200, 410, 1, 50, 80 },
    { "note", 400, 610, 1, 53, 85 },
    { "note", 600, 810, 1, 56, 90 },
    { "note", 800, 1010, 1, 59, 95 },
    { "note", 1000, 2010, 1, 62, 100 },
    { "note", 2000, 4010, 1, 65, 105 },
    { "note", 4000, 6010, 1, 68, 110 },
    { "note", 6000, 8010, 1, 71, 115 },
    { "note", 8000, 10010, 1, 74, 120 },
    { "note", 10000, 11990, 1, 70, 115 },
    { "note", 10000, 11990, 1, 66, 110 },
    { "note", 12000, 14010, 1, 62, 105 },
    { "note", 14000, 16010, 1, 58, 100 },
    { "note", 16000, 18010, 1, 54, 90 },
    { "note", 18000, 18510, 1, 50, 80 },
    { "note", 18500, 18990, 1, 38, 70 },
  } 
}
local score2 = deepcopy(orig_score2)
correct_cat1 = {
  1000,
  {
    { "set_tempo", 0, 1000000 },
    { "patch_change", 0, 1, 74 },
    { "key_signature", 21, -2, 46 },
    { "time_signature", 37, 4, 5, 6, 7 },
    { "key_after_touch", 188, 7, 8, 9 },
    { "channel_after_touch", 282, 11, 12 },
    { "pitch_wheel_change", 417, 14, -2100 },
    { "text_event", 584, "some enchanted evening" },
    { "track_name", 751, "some enchanted evening" },
    { "smpte_offset", 928, 18, 19, 20, 21, 22 },
    { "note", 115, 1813, 1, 55, 100 },
    { "marker", 2001, "hello world" },
    { "control_change", 2011, 1, 10, 126 },
    { "note", 2011, 1000, 1, 59, 100 },
    { "sequencer_specific", 4021, "yes, we have no bananas" },
    { "raw_meta_event", 5042, 99, "no, we have yes bananas" },
    { "sysex_f0", 6084, "I met a man whose name was time" },
    { "sysex_f7", 7136, "He said, I must be going" },
    { "song_position", 17563, 16000 },
    { "song_select", 18646, 104 },
    { "tune_request", 19740 },
    { "set_tempo", 19740, 1000000 },
    { "patch_change", 19760, 1, 19 },
    { "text_event", 19790, "organ part" },
    { "note", 19940, 410, 1, 50, 80 },
    { "note", 20140, 610, 1, 53, 85 },
    { "note", 20340, 810, 1, 56, 90 },
    { "note", 20540, 1010, 1, 59, 95 },
    { "note", 20740, 2010, 1, 62, 100 },
    { "note", 21740, 4010, 1, 65, 105 },
    { "note", 23740, 6010, 1, 68, 110 },
    { "note", 25740, 8010, 1, 71, 115 },
    { "note", 27740, 10010, 1, 74, 120 },
    { "note", 29740, 11990, 1, 70, 115 },
    { "note", 29740, 11990, 1, 66, 110 },
    { "note", 31740, 14010, 1, 62, 105 },
    { "note", 33740, 16010, 1, 58, 100 },
    { "note", 35740, 18010, 1, 54, 90 },
    { "note", 37740, 18510, 1, 50, 80 },
    { "note", 38240, 18990, 1, 38, 70 } 
  } 
}
local correct_merge1 = {
  1000,
  {
    { "set_tempo", 0, 1000000 },
    { "patch_change", 0, 1, 74 },
    { "key_signature", 21, -2, 46 },
    { "time_signature", 37, 4, 5, 6, 7 },
    { "key_after_touch", 188, 7, 8, 9 },
    { "channel_after_touch", 282, 11, 12 },
    { "pitch_wheel_change", 417, 14, -2100 },
    { "text_event", 584, "some enchanted evening" },
    { "track_name", 751, "some enchanted evening" },
    { "smpte_offset", 928, 18, 19, 20, 21, 22 },
    { "note", 115, 1813, 1, 55, 100 },
    { "marker", 2001, "hello world" },
    { "control_change", 2011, 1, 10, 126 },
    { "note", 2011, 1000, 1, 59, 100 },
    { "sequencer_specific", 4021, "yes, we have no bananas" },
    { "raw_meta_event", 5042, 99, "no, we have yes bananas" },
    { "sysex_f0", 6084, "I met a man whose name was time" },
    { "sysex_f7", 7136, "He said, I must be going" },
    { "song_position", 17563, 16000 },
    { "song_select", 18646, 104 },
    { "tune_request", 19740 } 
  },
  {
    { "set_tempo", 0, 1000000 },
    { "patch_change", 20, 0, 19 },
    { "text_event", 50, "organ part" },
    { "note", 200, 410, 0, 50, 80 },
    { "note", 400, 610, 0, 53, 85 },
    { "note", 600, 810, 0, 56, 90 },
    { "note", 800, 1010, 0, 59, 95 },
    { "note", 1000, 2010, 0, 62, 100 },
    { "note", 2000, 4010, 0, 65, 105 },
    { "note", 4000, 6010, 0, 68, 110 },
    { "note", 6000, 8010, 0, 71, 115 },
    { "note", 8000, 10010, 0, 74, 120 },
    { "note", 10000, 11990, 0, 70, 115 },
    { "note", 10000, 11990, 0, 66, 110 },
    { "note", 12000, 14010, 0, 62, 105 },
    { "note", 14000, 16010, 0, 58, 100 },
    { "note", 16000, 18010, 0, 54, 90 },
    { "note", 18000, 18510, 0, 50, 80 },
    { "note", 18500, 18990, 0, 38, 70 } 
  } 
}
local correct_mix1 = {
  1000,
  {
    { "set_tempo", 0, 1000000 },
    { "patch_change", 0, 1, 74 },
    { "key_signature", 21, -2, 46 },
    { "time_signature", 37, 4, 5, 6, 7 },
    { "key_after_touch", 188, 7, 8, 9 },
    { "channel_after_touch", 282, 11, 12 },
    { "pitch_wheel_change", 417, 14, -2100 },
    { "text_event", 584, "some enchanted evening" },
    { "track_name", 751, "some enchanted evening" },
    { "smpte_offset", 928, 18, 19, 20, 21, 22 },
    { "note", 115, 1813, 1, 55, 100 },
    { "marker", 2001, "hello world" },
    { "control_change", 2011, 1, 10, 126 },
    { "note", 2011, 1000, 1, 59, 100 },
    { "sequencer_specific", 4021, "yes, we have no bananas" },
    { "raw_meta_event", 5042, 99, "no, we have yes bananas" },
    { "sysex_f0", 6084, "I met a man whose name was time" },
    { "sysex_f7", 7136, "He said, I must be going" },
    { "song_position", 17563, 16000 },
    { "song_select", 18646, 104 },
    { "tune_request", 19740 },
    { "set_tempo", 0, 1000000 },
    { "patch_change", 20, 1, 19 },
    { "text_event", 50, "organ part" },
    { "note", 200, 410, 1, 50, 80 },
    { "note", 400, 610, 1, 53, 85 },
    { "note", 600, 810, 1, 56, 90 },
    { "note", 800, 1010, 1, 59, 95 },
    { "note", 1000, 2010, 1, 62, 100 },
    { "note", 2000, 4010, 1, 65, 105 },
    { "note", 4000, 6010, 1, 68, 110 },
    { "note", 6000, 8010, 1, 71, 115 },
    { "note", 8000, 10010, 1, 74, 120 },
    { "note", 10000, 11990, 1, 70, 115 },
    { "note", 10000, 11990, 1, 66, 110 },
    { "note", 12000, 14010, 1, 62, 105 },
    { "note", 14000, 16010, 1, 58, 100 },
    { "note", 16000, 18010, 1, 54, 90 },
    { "note", 18000, 18510, 1, 50, 80 },
    { "note", 18500, 18990, 1, 38, 70 } 
  }
}
local correct_score4 = {
  1000,
  {
    { "set_tempo", 0, 1000000 },
    { "patch_change", 70, 1, 19 },
    { "text_event", 100, "organ part" },
    { "note", 250, 410, 1, 50, 80 },
    { "note", 450, 610, 1, 53, 85 },
    { "note", 650, 810, 1, 56, 90 },
    { "note", 850, 1010, 1, 59, 95 },
    { "note", 1050, 2010, 1, 62, 100 },
    { "note", 2050, 4010, 1, 65, 105 },
    { "note", 4050, 6010, 1, 68, 110 },
    { "note", 6050, 8010, 1, 71, 115 },
    { "note", 8050, 10010, 1, 74, 120 },
    { "note", 10050, 11990, 1, 70, 115 },
    { "note", 10050, 11990, 1, 66, 110 },
    { "note", 12050, 14010, 1, 62, 105 },
    { "note", 14050, 16010, 1, 58, 100 },
    { "note", 16050, 18010, 1, 54, 90 },
    { "note", 18050, 18510, 1, 50, 80 },
    { "note", 18550, 18990, 1, 38, 70 } 
  } 
}
local correct_score6 = {
  1000,
  {
    { "set_tempo", 0, 1000000 },
    { "patch_change", 20, 1, 19 },
    { "text_event", 50, "organ part" },
    { "note", 200, 410, 1, 50, 80 },
    { "note", 400, 610, 1, 53, 85 },
    { "note", 600, 810, 1, 56, 90 },
    { "note", 800, 1010, 1, 59, 95 },
    { "note", 1000, 2010, 1, 62, 100 },
    { "note", 2000, 4010, 1, 65, 105 },
    { "note", 4000, 6010, 1, 68, 110 },
    { "note", 6000, 8010, 1, 71, 115 },
    { "note", 8000, 10010, 1, 74, 120 },
    { "note", 10000, 11990, 1, 70, 115 },
    { "note", 10000, 11990, 1, 66, 110 },
    { "note", 12000, 14010, 1, 62, 105 },
    { "note", 14000, 16010, 1, 58, 100 },
    { "note", 16000, 18010, 1, 54, 90 },
    { "note", 18000, 18510, 1, 50, 80 },
    { "note", 18500, 18990, 1, 38, 70 } 
  } 
}
local correct_score8 = {
  1000,
  {
    { "set_tempo", 0, 1000000 },
    { "note", 10, 11990, 1, 70, 115 },
    { "note", 10, 11990, 1, 66, 110 },
    { "note", 2010, 14010, 1, 62, 105 },
    { "note", 4010, 16010, 1, 58, 100 },
    { "note", 6010, 18010, 1, 54, 90 },
    { "note", 8010, 18510, 1, 50, 80 },
    { "note", 8510, 18990, 1, 38, 70 } 
  } 
}
local correct_segment = {
  1000,
  {
    { "note", 6000, 8010, 1, 71, 115 },
    { "note", 8000, 10010, 1, 74, 120 },
    { "note", 10000, 11990, 1, 70, 115 },
    { "note", 10000, 11990, 1, 66, 110 },
    { "note", 12000, 14010, 1, 62, 105 },
    { "note", 14000, 16010, 1, 58, 100 },
    { "set_tempo", 5000, 1000000 }, 
    { "patch_change", 5000, 1, 19 }
  } 
}
local correct_stats = {
  bank_select={  },
  channels_by_track={ { 1 }, { 0 } },
  channels_total={ 0, 1 },
  general_midi_mode={  },
  nticks=37490,
  ntracks=2,
  num_notes_by_channel={ [0]=16, 2 },
  patch_changes_by_track={ { 74 }, { [0]=19 } },
  patch_changes_total={ 19, 74 },
  percussion={  },
  pitch_range_by_track={ { 55, 59 }, { 38, 74 } },
  pitch_range_sum=40,
  pitches={
    [38]=1,
    [50]=2,
    [53]=1,
    [54]=1,
    [55]=1,
    [56]=1,
    [58]=1,
    [59]=2,
    [62]=2,
    [65]=1,
    [66]=1,
    [68]=1,
    [70]=1,
    [71]=1,
    [74]=1 
  },
  ticks_per_quarter=1000 
}

local seq_opus = {
	96,
	{ {'set_sequence_number', 0, 63000}, }
}

local track1 = {
	{'patch_change', 0, 1, 74},   -- and these are the events...
	{'key_signature', 4, -2, 46},
	{'time_signature', 3, 4, 5, 6, 7,},
	{'set_tempo', 5, 1000000},
	{'note_on', 5, 1, 55, 100},
	{'key_after_touch', 7, 7, 8, 9},
	{'channel_after_touch', 9, 11, 12},
	{'pitch_wheel_change', 13, 14, -2100},
	{'text_event', 16, 'some enchanted evening'},
	{'note_off', 5, 1, 55, 100},
}
local track2 = {
	{'patch_change', 1, 1, 74},   -- and these are the events...
	{'key_signature', 4, -2, 46},
	{'time_signature', 3, 4, 5, 6, 7,},
	{'set_tempo', 5, 1000000},
	{'note_on', 5, 1, 55, 100},
	{'key_after_touch', 7, 7, 8, 9},
	{'channel_after_touch', 9, 11, 12},
	{'pitch_wheel_change', 13, 14, -2100},
	{'text_event', 16, 'some enchanted evening'},
	{'note_off', 5, 1, 55, 100},
}
local correct_mix_tracks = {
	{'patch_change', 0, 1, 74},   -- and these are the events...
	{'patch_change', 1, 1, 74},   -- and these are the events...
	{'key_signature', 3, -2, 46},
	{'key_signature', 1, -2, 46},
	{'time_signature', 2, 4, 5, 6, 7,},
	{'time_signature', 1, 4, 5, 6, 7,},
	{'set_tempo', 4, 1000000},
	{'set_tempo', 1, 1000000},
	{'note_on', 4, 1, 55, 100},
	{'note_on', 1, 1, 55, 100},
	{'key_after_touch', 6, 7, 8, 9},
	{'key_after_touch', 1, 7, 8, 9},
	{'channel_after_touch', 8, 11, 12},
	{'channel_after_touch', 1, 11, 12},
	{'pitch_wheel_change', 12, 14, -2100},
	{'pitch_wheel_change', 1, 14, -2100},
	{'text_event', 15, 'some enchanted evening'},
	{'text_event', 1, 'some enchanted evening'},
	{'note_off', 4, 1, 55, 100},
	{'note_off', 1, 1, 55, 100},
}

----------------------------------------------------------------

local midi1 = MIDI.opus2midi(opus1)
ok(equals(midi1, correct_midi1) and equals(opus1, opus), 'opus2midi')

local opus2 = MIDI.midi2opus(correct_midi1)
ok(equals(opus1, opus2) and equals(correct_midi, correct_midi1), 'midi2opus')

local score1 = MIDI.opus2score(opus1)
ok(equals(score1, correct_score) and equals(opus1, opus), 'opus2score')

local opus3 = MIDI.score2opus(score1)
ok(equals(opus3, opus1) and equals(score1, correct_score), 'score2opus')

local opus4 = MIDI.to_millisecs(opus1)
ok(equals(opus4,correct_ms) and equals(opus1,opus), 'to_millisecs')
--  warn('opus4='..DataDumper(opus4))
--  warn('correct_ms='..DataDumper(correct_ms))


local grep1 = MIDI.grep(score1, {4,7})
ok(equals(grep1, correct_grep_score) and equals(score1, correct_score),
 'grep (score)')

local grep2 = MIDI.grep(opus1, {4,7})
ok(equals(grep2, correct_grep_opus) and equals(opus1, opus), 'grep (opus)')

local cat1 = MIDI.concatenate_scores({score1, score2})
ok(equals(cat1, correct_cat1) and equals(score1, correct_score) and equals(score2, orig_score2), 'concatenate scores')
--ok(equals(score1, correct_score), 'original score1 unchanged')
--ok(equals(score2, orig_score2), 'original score2 unchanged')

local merge1 = MIDI.merge_scores({score1, score2})
ok(equals(merge1, correct_merge1) and equals(score1, correct_score) and equals(score2, orig_score2), 'merge scores')
--warn('merge1='..DataDumper(merge1))
--warn('correct_merge1='..DataDumper(correct_merge1))

local mix1 = MIDI.mix_scores({score1, score2})
ok(equals(mix1, correct_mix1) and equals(score1, correct_score) and equals(score2, orig_score2), 'mix scores')
--warn('mix1='..DataDumper(mix1))
--warn('correct_mix1='..DataDumper(correct_mix1))

local mix_tracks = MIDI.mix_opus_tracks({track1, track2})
ok(equals(mix_tracks, correct_mix_tracks), 'mix opus tracks')

local midi2 = MIDI.score2midi(score1)
local midi2 = MIDI.score2midi(score1)
ok(equals(midi2, correct_midi), 'score2midi')

local score3 = MIDI.midi2score(midi1)
ok(equals(score3, score1), 'midi2score')

local st = MIDI.score_type(score1)
local ot = MIDI.score_type(opus1)
local mt = MIDI.score_type(midi1)
ok(st == 'score' and ot == 'opus' and mt == '', 'score_type')

local score4 = MIDI.timeshift(score2, 50)
ok(equals(score4, correct_score4) and equals(score2, orig_score2),
 'timeshift (score, shift>0)')

local score4 = MIDI.timeshift{score2, shift=50}
ok(equals(score4, correct_score4) and equals(score2, orig_score2),
 'timeshift {score, shift=50}')

local score5 = MIDI.timeshift(score2, nil, 50)
ok(equals(score5, correct_score4), 'timeshift (score, nil, start_time>0)')

local score5 = MIDI.timeshift{score2, start_time=50}
ok(equals(score5, correct_score4), 'timeshift {score, start_time=50}')

local score6 = MIDI.timeshift(score2, -100)
ok(equals(score6, correct_score6), 'timeshift (score, shift<0)')

local score7 = MIDI.timeshift(score2, nil, -100)
ok(equals(score7, correct_score6), 'timeshift (score, nil, start_time<0)')

local score8 = MIDI.timeshift(score2, nil, 10, 10000)
ok(equals(score8, correct_score8), 'timeshift (score, nil, start_time, from_time)')

local score9 = MIDI.timeshift(score2, nil, 10, 10000, {8,})
ok(equals(score9, orig_score2), 'timeshift (score, nil, start_time, from_time, tracks)')

local score9 = MIDI.timeshift{score2,start_time=10,from_time=10000,tracks={8,}}
ok(equals(score9, orig_score2), 'timeshift {score, start_time=10, from_time=10000, tracks={8,}}')

local score10 = MIDI.segment(score2, 5000, 15000)
ok(equals(score10, correct_segment) and equals(score2, orig_score2),
 'segment (score, start_time, end_time)')

local score10 = MIDI.segment{score2, start_time=5000, end_time=15000}
ok(equals(score10, correct_segment) and equals(score2, orig_score2),
 'segment {score, start_time=5000, end_time=15000}')

-- warn('score10='..DataDumper(score10))
-- warn('correct_segment='..DataDumper(correct_segment))
-- os.exit()

local function pairsByKeys(t,f)   -- Programming in Lua p.173
  local a = {}
  for n in pairs(t) do a[#a+1] = n end
  table.sort(a,f)
  local i = 0
  return function() i = i+1; return a[i], t[a[i]] end
end
function table2sortedarray (t)
  local s = {' :'}
  for k,v in pairsByKeys(t) do
    if type(v) == 'table' then
      table.insert(s, k..table2sortedarray(v))
    else
      table.insert(s, k..'    '..tostring(v))
    end
  end
  return table.concat(s, '\n')
end

local merge1 = deepcopy(correct_merge1)
local stats = MIDI.score2stats(merge1)
s1=table2sortedarray(stats)
s2=table2sortedarray(correct_stats)
ok(equals(s1,s2) and equals(merge1,correct_merge1),'score2stats')

local seq_midi = MIDI.opus2midi(seq_opus)
--local f = assert(io.open('t.mid', 'wb'))
--f:write(seq_midi)
--f:close()
--os.execute('mididump t.mid')
local seq_opus2 = MIDI.midi2opus(seq_midi)
ok(equals(seq_opus2, seq_opus), 'set_sequence_number encode and decode')


os.exit()
