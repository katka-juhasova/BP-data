#!/usr/bin/env lua

require 'Test.More'

local tb = require 'Test.Builder'.new()
local function kv_is (t, k, expected, name)
    if type(t) ~= 'table' then
        tb:ok(false, name)
        tb:diag("    " .. tostring(t) .. " isn't a 'table' it's a '" .. type(t) .. "'")
    else
        local got = t[k]
        local pass = got == expected
        tb:ok(pass, name)
        if not pass then
            tb:diag("         got: " .. tostring(got)
               .. "\n    expected: " .. tostring(expected))
        end
    end
end

plan(223)

local ctor = require 'Silva.template'

type_ok( ctor, 'function' )
local sme, capture

sme = ctor'/foo/bar'
ok( sme('/foo/bar'), 'same string' )
nok( sme('/foo/baz') )
nok( sme('/foo/bar/baz') )

-- level 1
sme = ctor'/foo/{var}'
capture = sme('/foo/bar')
kv_is( capture, 'var', 'bar' )
capture = sme('/foo/Hello%20World%21')
kv_is( capture, 'var', 'Hello World!' )
capture = sme('/foo/')
kv_is( capture, 'var', '' )
nok( sme('/foo/bar/baz') )
nok( sme('/bar/baz') )

sme = ctor'/foo/0{var}/baz'
capture = sme('/foo/0bar/baz')
kv_is( capture, 'var', 'bar' )
capture = sme('/foo/%30%62%61%7a/%62%61%7a')
kv_is( capture, 'var', 'baz' )
capture = sme('/foo/0/baz')
kv_is( capture, 'var', '' )
nok( sme('/foo/0bar/bar') )

sme = ctor'/foo/{var}123/baz'
capture = sme('/foo/bar123/baz')
kv_is( capture, 'var', 'bar' )
capture = sme('/foo/123/baz')
kv_is( capture, 'var', '' )
nok( sme('/foo/bar0/baz') )
nok( sme('/foo/bar123/bar') )

sme = ctor'/foo/{bar}/{%62%61r}'
capture = sme('/foo/bar/%62%61r')
kv_is( capture, 'bar', 'bar' )
kv_is( capture, '%62%61r', 'bar' )
capture = sme('/foo/%62%61r/bar')
kv_is( capture, 'bar', 'bar' )
kv_is( capture, '%62%61r', 'bar' )

-- level 2
sme = ctor'/foo/{+var}'
capture = sme('/foo/bar')
kv_is( capture, 'var', 'bar' )
capture = sme('/foo/bar/baz')
kv_is( capture, 'var', 'bar/baz' )
capture = sme('/foo/')
kv_is( capture, 'var', '' )

sme = ctor'/foo/{+var}/here'
capture = sme('/foo/bar/baz/here')
kv_is( capture, 'var', 'bar/baz' )

sme = ctor'/foo/{+var}123'
capture = sme('/foo/bar123')
kv_is( capture, 'var', 'bar' )
capture = sme('/foo/bar/baz123')
kv_is( capture, 'var', 'bar/baz' )
capture = sme('/foo/123')
kv_is( capture, 'var', '' )

sme = ctor'here?ref={+var}'
capture = sme('here?ref=/foo/bar')
kv_is( capture, 'var', '/foo/bar' )

sme = ctor'/foo{#var}'
capture = sme('/foo#bar')
kv_is( capture, 'var', 'bar' )
capture = sme('/foo#Hello%20World%21')
kv_is( capture, 'var', 'Hello World!' )
capture = sme('/foo#')
kv_is( capture, 'var', '' )
capture = sme('/foo')
kv_is( capture, 'var', nil )
nok( sme('/foo/') )
nok( sme('/bar#baz') )

sme = ctor'/foo{#var}123'
capture = sme('/foo#bar123')
kv_is( capture, 'var', 'bar' )
nok( sme('/foo#bar0') )

-- level 3
sme = ctor'map?{x,y}'
capture = sme('map?1024,768')
kv_is( capture, 'x', '1024' )
kv_is( capture, 'y', '768' )
capture = sme('map?1024')
kv_is( capture, 'x', '1024' )
kv_is( capture, 'y', nil )
capture = sme('map?1024,')
kv_is( capture, 'x', '1024' )
kv_is( capture, 'y', '' )
nok( sme('map?1,2,3') )
capture = sme('map?')
kv_is( capture, 'x', '' )
kv_is( capture, 'y', nil )
capture = sme('map?,')
kv_is( capture, 'x', '' )
kv_is( capture, 'y', '' )

sme = ctor'/foo/{+path,x}/here'
capture = sme('/foo/bar/baz,1024/here')
kv_is( capture, 'path', 'bar/baz' )
kv_is( capture, 'x', '1024' )
capture = sme('/foo/bar/baz/here')
kv_is( capture, 'path', 'bar/baz' )
kv_is( capture, 'x', nil )
capture = sme('/foo/bar/baz,/here')
kv_is( capture, 'path', 'bar/baz' )
kv_is( capture, 'x', '' )

sme = ctor'/foo{#path,x}/here'
capture = sme('/foo#bar,1024/here')
kv_is( capture, 'path', 'bar' )
kv_is( capture, 'x', '1024' )
capture = sme('/foo#bar/here')
kv_is( capture, 'path', 'bar' )
kv_is( capture, 'x', nil )
capture = sme('/foo#bar,/here')
kv_is( capture, 'path', 'bar' )
kv_is( capture, 'x', '' )

sme = ctor'/foo{.var}'
capture = sme('/foo.txt')
kv_is( capture, 'var', 'txt' )
capture = sme('/foo.')
kv_is( capture, 'var', '' )
capture = sme('/foo')
kv_is( capture, 'var', nil )

sme = ctor'/foo{.x,y}'
capture = sme('/foo.1024.768')
kv_is( capture, 'x', '1024' )
kv_is( capture, 'y', '768' )
capture = sme('/foo.1024')
kv_is( capture, 'x', '1024' )
kv_is( capture, 'y', nil )
capture = sme('/foo.1024.')
kv_is( capture, 'x', '1024' )
kv_is( capture, 'y', '' )

sme = ctor'/foo{.x}{.y}'
capture = sme('/foo.1024.768')
kv_is( capture, 'x', '1024' )
kv_is( capture, 'y', '768' )
capture = sme('/foo.1024')
kv_is( capture, 'x', '1024' )
kv_is( capture, 'y', nil )
capture = sme('/foo.1024.')
kv_is( capture, 'x', '1024' )
kv_is( capture, 'y', '' )

sme = ctor'/foo{.x,y}bar'
capture = sme('/foo.1024.768bar')
kv_is( capture, 'x', '1024' )
kv_is( capture, 'y', '768' )
capture = sme('/foo.1024bar')
kv_is( capture, 'x', '1024' )
kv_is( capture, 'y', nil )
capture = sme('/foo.1024.bar')
kv_is( capture, 'x', '1024' )
kv_is( capture, 'y', '' )

sme = ctor'/foo{.x}{.y}bar'
capture = sme('/foo.1024.768bar')
kv_is( capture, 'x', '1024' )
kv_is( capture, 'y', '768' )
capture = sme('/foo.1024bar')
kv_is( capture, 'x', '1024' )
kv_is( capture, 'y', nil )
capture = sme('/foo.1024.bar')
kv_is( capture, 'x', '1024' )
kv_is( capture, 'y', '' )

sme = ctor'/foo{/var}'
capture = sme('/foo/bar')
kv_is( capture, 'var', 'bar' )
capture = sme('/foo/')
kv_is( capture, 'var', '' )
capture = sme('/foo')
kv_is( capture, 'var', nil )

sme = ctor'/foo{/x,y}123'
capture = sme('/foo/bar/baz123')
kv_is( capture, 'x', 'bar' )
kv_is( capture, 'y', 'baz' )
capture = sme('/foo/bar123')
kv_is( capture, 'x', 'bar' )
kv_is( capture, 'y', nil )
capture = sme('/foo/bar/123')
kv_is( capture, 'x', 'bar' )
kv_is( capture, 'y', '' )
capture = sme('/foo123')
kv_is( capture, 'x', nil )
kv_is( capture, 'y', nil )
capture = sme('/foo/123')
kv_is( capture, 'x', '' )
kv_is( capture, 'y', nil )

sme = ctor'/foo{/x}{/y}123'
capture = sme('/foo/bar/baz123')
kv_is( capture, 'x', 'bar' )
kv_is( capture, 'y', 'baz' )
capture = sme('/foo/bar123')
kv_is( capture, 'x', 'bar' )
kv_is( capture, 'y', nil )
capture = sme('/foo/bar/123')
kv_is( capture, 'x', 'bar' )
kv_is( capture, 'y', '' )
capture = sme('/foo123')
kv_is( capture, 'x', nil )
kv_is( capture, 'y', nil )
capture = sme('/foo/123')
kv_is( capture, 'x', '' )
kv_is( capture, 'y', nil )

sme = ctor'/foo{/var,x}/here'
capture = sme('/foo/bar/1024/here')
kv_is( capture, 'var', 'bar' )
kv_is( capture, 'x', '1024' )
capture = sme('/foo/bar//here')
kv_is( capture, 'var', 'bar' )
kv_is( capture, 'x', '' )

sme = ctor'/foo{/var}{/x}/here'
capture = sme('/foo/bar/1024/here')
kv_is( capture, 'var', 'bar' )
kv_is( capture, 'x', '1024' )
capture = sme('/foo/bar//here')
kv_is( capture, 'var', 'bar' )
kv_is( capture, 'x', '' )

sme = ctor'/foo{;x,y}'
capture = sme('/foo;x=1024;y=768')
kv_is( capture, 'x', '1024' )
kv_is( capture, 'y', '768' )
capture = sme('/foo;x;y')
kv_is( capture, 'x', '' )
kv_is( capture, 'y', '' )
nok( sme('/foo;x=1024;y=768;z=0') )
capture = sme('/foo')
kv_is( capture, 'x', nil )
kv_is( capture, 'y', nil )
capture = sme('/foo;')
kv_is( capture, 'x', nil )
kv_is( capture, 'y', nil )
nok( sme('/foo;z=0') )

sme = ctor'/foo{;x,y}/here'
capture = sme('/foo;x=1024;y=768/here')
kv_is( capture, 'x', '1024' )
kv_is( capture, 'y', '768' )
capture = sme('/foo;x;y/here')
kv_is( capture, 'x', '' )
kv_is( capture, 'y', '' )
nok( sme('/foo;x=1024;y=768;z=0/here') )
capture = sme('/foo/here')
kv_is( capture, 'x', nil )
kv_is( capture, 'y', nil )
capture = sme('/foo;/here')
kv_is( capture, 'x', nil )
kv_is( capture, 'y', nil )
nok( sme('/foo;z=0/here') )

sme = ctor'/foo{;x,y}bar/here'
capture = sme('/foo;x=1024;y=768bar/here')
kv_is( capture, 'x', '1024' )
kv_is( capture, 'y', '768' )
nok( sme('/foo;x;ybar/here') )
capture = sme('/foobar/here')
kv_is( capture, 'x', nil )
kv_is( capture, 'y', nil )
nok( sme('/foo;bar/here') )
nok( sme('/foo;z=0bar/here') )

sme = ctor'/foo{;x,y}?fixed'
capture = sme('/foo;x=1024;y=768?fixed')
kv_is( capture, 'x', '1024' )
kv_is( capture, 'y', '768' )
capture = sme('/foo;x;y?fixed')
kv_is( capture, 'x', '' )
kv_is( capture, 'y', '' )
nok( sme('/foo;x=1024;y=768;z=0?fixed') )
capture = sme('/foo?fixed')
kv_is( capture, 'x', nil )
kv_is( capture, 'y', nil )
capture = sme('/foo;?fixed')
kv_is( capture, 'x', nil )
kv_is( capture, 'y', nil )
nok( sme('/foo;z=0?fixed') )

sme = ctor'/foo{;x,y}#fixed'
capture = sme('/foo;x=1024;y=768#fixed')
kv_is( capture, 'x', '1024' )
kv_is( capture, 'y', '768' )
capture = sme('/foo;x;y#fixed')
kv_is( capture, 'x', '' )
kv_is( capture, 'y', '' )
nok( sme('/foo;x=1024;y=768;z=0#fixed') )
capture = sme('/foo#fixed')
kv_is( capture, 'x', nil )
kv_is( capture, 'y', nil )
capture = sme('/foo;#fixed')
kv_is( capture, 'x', nil )
kv_is( capture, 'y', nil )
nok( sme('/foo;z=0#fixed') )

sme = ctor'/foo{?x,y}'
capture = sme('/foo?x=1024&y=768')
kv_is( capture, 'x', '1024' )
kv_is( capture, 'y', '768' )
capture = sme('/foo?x=&y=')
kv_is( capture, 'x', '' )
kv_is( capture, 'y', '' )
nok( sme('/foo?x=1024&y=768&z=0') )
capture = sme('/foo')
kv_is( capture, 'x', nil )
kv_is( capture, 'y', nil )
capture = sme('/foo?')
kv_is( capture, 'x', nil )
kv_is( capture, 'y', nil )
nok( sme('/foo?z=0') )

sme = ctor'/foo{?x,y}#fixed'
capture = sme('/foo?x=1024&y=768#fixed')
kv_is( capture, 'x', '1024' )
kv_is( capture, 'y', '768' )
capture = sme('/foo?x=&y=#fixed')
kv_is( capture, 'x', '' )
kv_is( capture, 'y', '' )
nok( sme('/foo?x=1024&y=768&z=0#fixed') )
capture = sme('/foo#fixed')
kv_is( capture, 'x', nil )
kv_is( capture, 'y', nil )
capture = sme('/foo?#fixed')
kv_is( capture, 'x', nil )
kv_is( capture, 'y', nil )
nok( sme('/foo?z=0#fixed') )

sme = ctor'/foo?fixed=yes{&x,y}'
capture = sme('/foo?fixed=yes&x=1024&y=768')
kv_is( capture, 'x', '1024' )
kv_is( capture, 'y', '768' )
capture = sme('/foo?fixed=yes&x=&y=')
kv_is( capture, 'x', '' )
kv_is( capture, 'y', '' )
nok( sme('/foo?fixed=yes&x=1024&y=768&z=0') )
capture = sme('/foo?fixed=yes')
kv_is( capture, 'x', nil )
kv_is( capture, 'y', nil )
capture = sme('/foo?fixed=yes&')
kv_is( capture, 'x', nil )
kv_is( capture, 'y', nil )
nok( sme('/foo?fixed=yes&z=0') )

sme = ctor'/foo?fixed=yes{&x,y}#fixed'
capture = sme('/foo?fixed=yes&x=1024&y=768#fixed')
kv_is( capture, 'x', '1024' )
kv_is( capture, 'y', '768' )
capture = sme('/foo?fixed=yes&x=&y=#fixed')
kv_is( capture, 'x', '' )
kv_is( capture, 'y', '' )
nok( sme('/foo?fixed=yes&x=1024&y=768&z=0#fixed') )
capture = sme('/foo?fixed=yes#fixed')
kv_is( capture, 'x', nil )
kv_is( capture, 'y', nil )
capture = sme('/foo?fixed=yes&#fixed')
kv_is( capture, 'x', nil )
kv_is( capture, 'y', nil )
nok( sme('/foo?fixed=yes&z=0#fixed') )

-- x-www-form-urlencoded
sme = ctor'/foo/{path}{?query}{#frag}'
capture = sme('/foo/bar+baz')
kv_is( capture, 'path', 'bar+baz' )
kv_is( capture, 'query', nil )
kv_is( capture, 'frag', nil )
capture = sme('/foo/bar+baz?query=foo+bar+baz')
kv_is( capture, 'path', 'bar+baz' )
kv_is( capture, 'query', 'foo bar baz' )
kv_is( capture, 'frag', nil )
capture = sme('/foo/bar+baz?query=foo+bar+baz#baz+bar')
kv_is( capture, 'path', 'bar+baz' )
kv_is( capture, 'query', 'foo bar baz' )
kv_is( capture, 'frag', 'baz+bar' )

sme = ctor'/foo/{path}?first=yes%20or%20no{&query}#foo{frag}'
capture = sme('/foo/bar+baz?first=yes+or+no#foo')
kv_is( capture, 'path', 'bar+baz' )
kv_is( capture, 'query', nil )
kv_is( capture, 'frag', '' )
capture = sme('/foo/bar+baz?first=yes+or+no&query=foo+bar+baz#foo')
kv_is( capture, 'path', 'bar+baz' )
kv_is( capture, 'query', 'foo bar baz' )
kv_is( capture, 'frag', '' )
capture = sme('/foo/bar+baz?first=yes+or+no&query=foo+bar+baz#foobaz+bar')
kv_is( capture, 'path', 'bar+baz' )
kv_is( capture, 'query', 'foo bar baz' )
kv_is( capture, 'frag', 'baz+bar' )
