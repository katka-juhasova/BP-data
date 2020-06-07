-- check file to open
local function check_file (file_path, type)
	local file,ie=io.open(file_path, type);
	
	if(not file) then
		print("ERROR: cannot open file " .. file_path .. ": " .. ie);
		return nil,ie
	end

	return file
end

-- ask at some point if continue and clear table with patterns
local function question_continue (continue)
	print("Continue? y/n")
	continue = io.read()

	if continue == 'n' or continue == 'N' then
		continue = nil
	end
	return continue
end

return {
	check_file = check_file,
	question_continue = question_continue
}