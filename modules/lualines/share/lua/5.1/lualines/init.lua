local getopt = require "alt_getopt"
local methods = require "lualines.methods"
local util = require "lualines.util"

local function help (args)
	print("\nLuaLines, a tiny line parser \n\n"..
		[[
Usage: [-hsvn] [-m num] [-f file] <input file>
		
	-h 		help
	-s		parse lines based on single pattern match
	-m [num]	parse lines based on more patterns match 
	-v		don't print parsed output
	-n		parse lines based on more patterns inside "patterns"


DETAILED USAGE
	-n 	- tags could be two paterns brackets are no mandatory.
			<tag> some text with pattern </tag>
		- option could be used to parse whole text inside tags
			- How many patterns: 0
		
EXAMPLE
	- lualines -m 3 -f /path/to/save /file/path/to/parse
	- lualines -s -f /path/to/save /file/path/to/parse
	
	- lualines -n -f /path/to/save /file/path/to/parse
		First tag: <h1>
		Last tag: </h1>
		How many patterns to find: 2
		1.pattern: My
		2.pattern: Header
		=> this will find:
			<h1> My original Header </h1>, <h1> My Header </h1>, 
			<h1> Header My </h1>
			<h1> Header 
			with more lines
			another line
			My </h1>... 
			etc.

CONTACT
	https://github.com/robooo
		]]);
end

local function main () 
	local settings = {}
	local patterns = {} 		-- patterns to find
	local final_parse = {}	-- final table parsed lines
	local continue = 1 			-- continue or stop in program flow
	local print_results = 1 -- if -v was typed, don't print results

	local optarg, optind = alt_getopt.get_opts(arg,"f:m:nsv",settings);
	
	if(#arg<1) then
		help(arg);
		return nil
	end

	if optarg['v'] ~= nil then
		print_results = 0
	end

	util.check_file(arg[#arg])
	
	while continue do

		if optarg['s'] then
			io.write("Type pattern to find: ")
			final_parse = methods.single_parse(io.read())
		end

		if optarg['m'] then
			print("Type patterns to find: ")
			while #patterns ~= tonumber(optarg['m']) do
					io.write(#patterns + 1 .. ".pattern: ")
					patterns[#patterns + 1] = io.read()
				end
				final_parse = methods.multi_parse(patterns)
		end

		if optarg['n'] then
			io.write("First tag:")
			local first_tag = io.read()
			io.write("Last tag:")
			local last_tag = io.read()

			io.write("How many patterns to find: ")
			local patterns_num = io.read()

			while #patterns ~= tonumber(patterns_num) do
					io.write(#patterns + 1 .. ".pattern: ")
					patterns[#patterns + 1] = io.read()
			end
			final_parse = methods.inner_parse(first_tag, last_tag, patterns)
		end

		-- if parsing was successful 
		if #final_parse ~= 0 then
			print('\n'.. 'OUTPUT: ')
			if print_results == 1 then 
				for _,v in ipairs(final_parse) do 
					print(v)
				end
			end

			print('\n'.. #final_parse .. ' lines parsed, save to file? y/n')
			local write_to_file = io.read()
			
			if write_to_file == 'Y' or write_to_file == 'y' then
				local file = util.check_file(optarg['f'],'a')
					for _,v in ipairs(final_parse) do 
						file:write(v .. '\n')
					end
				file:close()
				print("Saved...")
			end
			patterns = {}
			continue = util.question_continue(continue)
		else
			print("Nothing found")
			patterns = {}
			continue = util.question_continue(continue)	
		end
	end
end

main() 