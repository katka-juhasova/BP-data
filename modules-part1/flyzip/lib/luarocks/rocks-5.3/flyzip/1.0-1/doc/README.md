This is a simple Lua library for generating zipfiles on the fly.

It is written for Lua 5.2, and requires the `lzlib` rock to be installed.

    local flyzip = require "flyzip"
    -- Create a zipfile named "output_zipfile.zip" in the working directory.
    -- flyzip DOES NOT SEEK its output, so io.stdout or a pipe could be passed
    -- here
    local out = flyzip(assert(io.open("output_zipfile.zip","wb")))
    -- add_data adds a file with data from a string
    out:add_data("small_file", "The contents of this string will be stored in a file named \"small_file\"")
    -- opens a file named "large_file" in the working directory and adds it to
    -- the archive with the same name
    -- (all variants of add_file work by reading the whole file into memory;
    -- flyzip is not suited for creation of giant zipfiles)
    out:add_file("large_file")
    -- opens a file named "Silly Name" in the working directory and adds it to
    -- the archive as a file named "large_file_2"
    out:add_file("large_file_2", "Silly Name")
    -- we can pass a file handle in as well
    out:add_file("large_file_3", assert(io.open("another_large_file","wb")))
    -- this writes the zip central directory (thus completing the zipfile), and
    -- closes the file
    out:close()
