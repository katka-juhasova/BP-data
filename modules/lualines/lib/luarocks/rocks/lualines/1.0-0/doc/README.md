# LuaLines
>*Small line parser written in pure Lua*

##Overview
I needed fast small parser for my school project (parsing .gpx file with thousands lines). I needed to parse whole <tag> block with patterns between them, which I was looking for. For example:

```
<wpt lat="47.9576349" lon="16.787799">
  <name>Jois</name>
  <extensions>
    <ogr:osm_id>538174</ogr:osm_id>
    <ogr:other_tags>&quot;traffic_sign&quot;=&gt;&quot;city_limit&quot;</ogr:other_tags>
  </extensions>
</wpt>
<wpt lat="48.1896356" lon="17.2557963">
    <ogr:osm_id>702570</ogr:osm_id>
    ....
</wpt>
<rte lat=...
...
</rte>
```
And from this file I needed all with *wpt* tags and contains *traffic_sign*. Sure you can do it with some regex, but to me, this is more handy and easier to work with. 
I added some easy parsing with single or more patterns and going to add more functionality to LuaLines. Just scroll down and check for its options.

##Usage
```
Usage: [-hsvn] [-m num] [-f file] <input file>

	-h 	    	help
	-s	    	parse lines based on single pattern match
	-m [num]	parse lines based on more patterns match
	-v	    	don't print parsed output
	-n	    	parse lines based on more patterns insi
```
* -s  - used to find lines which contains our typed pattern
* -m [num]  - used to find lines which contains our typed patterns (num could be 1, so will be same as *-s*)
* -n  - follow instructions, first type starting and ending pattern, then which patterns find between them. If you want to parse whole paragraph, then type <pre>How many patterns to find: <b>0</b></pre>

##Installation
Make:
```
git clone https://github.com/robooo/LuaLines.git
cd LuaLines/
make
```
Or with luarocks:
``` 
TO DO
```

##Examples
###single parse
 * lualines -s -f /path/to/save /file/path/to/parse

###multi parse
 * lualines -m 3 -f /path/to/save /file/path/to/parse

###inner parse
Let's work this file, its path is */file/path/to/parse.txt*:
```
<tag1>This is what I want</tag1>
<tag1>This is not what I want</tag1>
<tag2>Bad too<tag2>
<bad_tag>This is what I want2</tag1>
```
and we want get 1. and 4. line
<pre>
> <b>lualines -n -f /path/to/save.txt /file/path/to/parse.txt</b>
> First tag: <b>&lt;tag1&gt;</b>
> Last tag: <b>&lt;/tag1&gt;</b>
> How many patterns to find: <b>1</b>
> 1.pattern: <b>is what</b>
> OUTPUT:
> <i>&lt;tag1&gt;This is what I want&lt;/tag1&gt;</i>
> 1 lines parsed, save to file? y/n
> <b>y</b>
> Continue? y/n
> <b>y</b>
> First tag: <b>&lt;bad_tag&gt;</b>
> Last tag: <b>&lt;/tag1&gt;</b>
> How many patterns to find: <b>1</b>
> 1.pattern: <b>is what</b>
> OUTPUT:
> <i>&lt;bad_tag&gt;This is what I want2&lt;/h1&gt;</i>
> 1 lines parsed, save to file? y/n
> <b>y</b>
> Continue? y/n
> <b>n</b>
</pre>


Now when we open *save.txt* file, we will see our parsed lines.		
