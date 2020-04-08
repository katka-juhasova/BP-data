#! /usr/bin/lua

require 'Test.More'
require 'Test.LongString'

plan(5)

is_string('str', 'str', "is_string")
like_string('str', '^%w+', "like_string")
unlike_string('str', '^%d+', "unlike_string")
contains_string('a string', 'str', "contains_string")
lacks_string('a string', 'STR', "lacks_string")
