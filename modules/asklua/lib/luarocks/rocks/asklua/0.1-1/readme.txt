---------------------------------------------------------------
Module:  AskLua

Purpose: to add interactive help to other modules

Author:  Julio Manuel Fernandez-Diaz
         Profesor Titular, Department of Physics
         University of Oviedo (Spain)

Date:    February 2010

Version: 0.1

License: Public domain
---------------------------------------------------------------


Introduction
------------

AskLua implements a help integrated system for on line use in the
interactive interpreter, and for generating documentation in "html"
and printed formats.

AskLua provides a unique module, "ask", which is little intrusive and,
although it occupies some memory, it can be deleted by the user at any
time if he/she does not want to continue with the help on line.

The system is fairly integrated, in such a way that it is possible to
easily add help for an existing module, even of binary type.


Files provided
--------------

readme.txt               -- this file
license.txt              -- license information

doc/asklua.pdf           -- descriptive document (in English) about `asklua`
doc/asklua_spanish.pdf   -- documento descriptivo (en español) sobre `asklua`

ask.lua                  -- the module
doc/ask.html             -- "html" file created by
                              lua -e "require'ask'; ask.doc''"
doc/ask.pdf              -- the same converted to PDF

doc/default.css          -- style sheet used in the "html" generation

example/mininum.lua      -- a numerical sample module to accompany "ask"
example/mininum.html     -- "html" file created by
                              lua -e "require'mininum'; ask.doc''"
example/mininum.pdf      -- the same converted to PDF

example/mininum_test.lua -- lua file for testing "mininum"


Installing
----------

* From tar.gz and zip formats:
       unpack it and move "ask.lua" to a convenient path.

* From luarocks: 
       luarocks install asklua


Using it
--------

$ lua
> require "ask"

From this point we have help for the module "ask".

If other module with help, v.g., "mininum" that accompanies "ask",
is loaded:

> require "mininum"

From this point we have help for "mininum", v.g.:

> ask"^l"

list the functions in "mininum", and:

> ask"root^u"

shows the usage help for function "root" in "mininum".

To generate all the documentation about "mininum" in "html" format:

$ lua -e "require'mininum'; ask.doc''"

