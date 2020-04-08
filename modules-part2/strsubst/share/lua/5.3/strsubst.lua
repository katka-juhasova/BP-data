--license:
--: strsubst - string substitution engine
--: Copyright (C)                        Pipapo Project
--:  2015,                               Christian Thaeter <ct@pipapo.org>
--:
--: This program is free software: you can redistribute it and/or modify
--: it under the terms of the GNU General Public License as published by
--: the Free Software Foundation, either version 2 of the License, or
--: (at your option) any later version.
--:
--: This program is distributed in the hope that it will be useful,
--: but WITHOUT ANY WARRANTY; without even the implied warranty of
--: MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--: GNU General Public License for more details.
--:
--: You should have received a copy of the GNU General Public License
--: along with this program.  If not, see <http://www.gnu.org/licenses/>.

-- constants
local NaN = math.abs(0/0)

-- punctuation charachters are hardcoded because we do not want to depend on locales, moreover not all characters
-- the 'C' Locale would define are used here, notably no parentheses, no quotation marks and not the underscore
local punct = "-$%&/=?`@+*~#,;.:<>|^!"

--PLANNED: operator aliases

-- the variables
local strsubst_vars = {
  -- only the initial variable table holds these, the names conflict with temporary vars, but that should't matter
  _VERSION     = "strsubst 0.4",
  _LICENSE     = "GPL2+",
  _COPYRIGHT   = "Copyright (C) 2015 Christian Thäter <ct@pipapo.org>",
  _DESCRIPTION = "String Substitution Engine",
}

local function prepare_vartable()
  --configvars:
  --: `__BACKSLASH __BRACEOPEN __BRACECLOSE`::
  --:   Used for the escaping mechanism. Must not be changed.
  strsubst_vars.__BACKSLASH = "{$__BACKSLASH}"
  strsubst_vars.__BRACEOPEN = "{$__BRACEOPEN}"
  strsubst_vars.__BRACECLOSE = "{$__BRACECLOSE}"
  --: `__IMMUTABLE`::
  --:   A Lua pattern matching immutable variables. Defaults to
  --:   all uppercase (plus digits and underscores) names only.
  strsubst_vars.__IMMUTABLE = strsubst_vars.__IMMUTABLE or "^[A-Z0-9_]*$"
  --: `__TEMPORARY`::
  --:   A Lua pattern matching temporary variables. Defaults to
  --:   names starting with a underscore.
  strsubst_vars.__TEMPORARY = strsubst_vars.__TEMPORARY or "^_"
  --: `__PARAMETER`::
  --:   The variable name for the single parameter passed to metaevaluation. Defaults to
  --:   to '_'.
  strsubst_vars.__PARAMETER = strsubst_vars.__PARAMETER or "_"
  --: `__EXPLICIT`::
  --:   Flag when set to anyting but the empty string ("") then explicit mode is turned on.
  --:   Strsubst only operates on strings starting with a '{' then.
  strsubst_vars.__EXPLICIT = strsubst_vars.__EXPLICIT or ""
  --: `__PARTIAL`::
  --:   If set to anyting but the empty string ("") then partial evaluation mode is turned on.
  --:   In partial evaluation mode expressions are only evaluated as much as it is known, unknown
  --:   variables are kept as variable expansion expression `{$varname}`, expressions surounding
  --:   partial evaluated variables are retained for later evaluation.
  strsubst_vars.__PARTIAL = strsubst_vars.__PARTIAL or ""
end



prepare_vartable()

local strsubst_vars_tmp

-- Tokenizer patterns:
-- don't evaluate
local skip = {"(.*)", "(.*)"}
-- treat operators literally, evaluate braced expressions
local literal = {"([^{]*)(%b{})", "(.*)"}
-- treat operators including braced expressions literally, braces must still match!
local literalrec = {"(.*)", "(.*)"}
-- normal evaluation
local evaluate = {"\r?\n?([^{]-)\r?\n?(%b{})", "(["..punct.."]*)([^"..punct.."]*)"}

local function strsubst_tokenize(text, tokenize)
  -- add a {} at the end to make the tokenizer pattern happy (there is no '%b{}?' for optional braces)
  text = text.."{}"

  local tokenized = {}
  for pre, braced in text:gmatch(tokenize[1]) do
    for nopunct, punct in pre:gmatch(tokenize[2]) do
      if nopunct ~= "" then
        table.insert(tokenized, nopunct)
      end
      if punct ~= "" then
        table.insert(tokenized, punct)
      end
    end
    if braced then
      table.insert(tokenized, braced)
    end
  end

  -- remove the final {}
  tokenized[#tokenized] = nil
  return tokenized
end


local strsubst_operators = {tokenize = evaluate}


local function strsubst_intern(text, operators)
  -- tokenize {braced} structure into a list of nopunct, punct and braced subexpressions
  local tokenized = strsubst_tokenize(text, operators.tokenize)

  -- single punctuation character in a block escape the character itself "{$}" -> "$"
  if #tokenized == 1 and tokenized[1]:match("^["..punct.."]$") then
    return tokenized[1]
  end

  -- evaluate
  local result = ""
  local buf = ""
  local infixfn
  local prefix = ""
  local infixop = ""
  local partial

  for i=1, #tokenized do
    local op = operators[tokenized[i]]

    if op and not partial then
      if infixfn then
        local r = infixfn(result, buf)
        if r then
          result = r
        else
          result = prefix..result..infixop..buf
          partial = true
        end
        buf = ""
      end
      infixfn = op.infix
      if infixfn then
        infixop = tokenized[i]
      end

      result = result..buf
      buf = ""

      if op.postfix then
        if not partial then
          prefix = result..tokenized[i]
          result, operators = op.postfix(result)
          operators = operators or strsubst_operators
        else
          result = result..tokenized[i]
          infixop = ""
        end
      end

    elseif operators.tokenize ~= literalrec and operators.tokenize ~= skip and tokenized[i]:match("^{") then
      local r, p = strsubst_intern(tokenized[i]:sub(2,-2), strsubst_operators)
      partial = partial or p
      if p then
        buf = buf.."{"..r.."}"
      else
        buf = buf..r
      end

    elseif operators.tokenize ~= skip then
      buf = buf..tokenized[i]
    end
  end

  if infixfn then
    if not partial then
      local r = infixfn(result, buf)
      if r then
        result = r
      else
        result = prefix..result..infixop..buf
        partial = true
      end
    else
      result = result..infixop..buf
    end
  else
    result = result..buf
  end

  if partial then
    return prefix..result, partial
  else
    return result, partial
  end
end


--MAIN:
--: String Substitutions
--: --------------------
--:
--: Replacing expressions within strings. An expression is defined as possibly nested
--: sequence of text, operators and subexpressions in braces.
--:
--: This is similar to the string expansions many shells offer, with a slightly different syntax and semantic
--: as the expressions are completely within braces and operators work on text, not variables.
--: In unix shell '${x}' expands a variable, here it is {$x} for example.
--:
--: There are operators for many common tasks like defining variables, string handling like search/replacment,
--: math and comparsions.
--:
--: Running the engine over a text will always return a string. Errors in math may return 'nan' or 'inf'. Few
--: other errors will return a textual error message. Everything else has sane defaults to return at least an
--: empty string.
--:
--: The lua api does some checks to ensure correct types. Nevertheless it is possible to manipulate some internal
--: variables in a way which would break the engine.
--:
--:
--: Syntax
--: ~~~~~~
--:
--: The input text is tokenized into braced expressions (Top level text is always treated as literal text). The
--: subexpressions are tokenized at nopunct/punctuation character transitions and nested subexpressions.
--: Each sequence of punctuation characters becomes a candidate for operator evaluation. If no matching operator exists
--: then the characters are returned literally. A subexpression which only contains a single punctuation character will always
--: return this character literally. The backslash can be used to escape any character.
--:
--: Text containing punctuation characters within braces must escape this characters properly, so that they are not
--: misinterpreted as operators.
--:
--: Strsubst defines its own set of punctuation characters to be independent from the current locale settings.
--: This set of punctuation characters does not contain all the characters the 'C' Locale would define, notably
--: no parentheses, no quotation marks and not the underscore.
--:
--: To make expressions more readable, a single "\r?\n?" in front of '}' and after '{' will be removed to write
--: expressions on multiple lines:
--:
--:  {
--:  {$condition}
--:  ?{this}
--:  :{that}
--:  }
--:
--: Evaluation
--: ~~~~~~~~~~
--:
--: Text is evaluated left to right, one operator at a time, when a operand contains a subexpressions these are
--: evaluated recursively and their result is inserted into the surounding text. If one wants to change the
--: evaluation order then braces must be used.
--:
--:  strsubst "{first=second$third}}"
--:
--: Will first assign 'second' to 'first' and then expand the variable 'third'
--:
--:  strsubst "{first={second$third}}}"
--:
--: The assignment to 'first' will recursively evaluate the subexpression with the text 'second' and append
--: the value of variable 'third' to it.
--:
--: Generally it is always a good idea to use braces a lot to make things explicit without ambiguity.
--:
--: Variables
--: ~~~~~~~~~
--:
--: Strsubst has different flavors of variables, which are still always global.
--: The flavor of a variable is defined by its name.
--:
--: normal variables::
--:  Thats any name which does not fall into one of the categories below,
--:  can be assigned and reassigned from within expressions.
--:
--: implementation defined variables::
--:  Start with two underscores (this is hardcoded), strsubst stores some internal configuration
--:  and special variables. Some can be used to reconfigure the semantics from the lua api.
--:
--: immutable variables::
--:  Names containing (by default) only uppercase characters, digits and the underscore,
--:  can only be assigned once, reassignments are silently ignored (old value is returned).
--:
--: temporary variables::
--:  start (by default) with a single underscore. These variables are only valid for the current strsubst()
--:  call and removed afterwards. One special case is that the meta operator '$$' which calls strsubst() recursively
--:  will see the temporary variables from the calling environment, defining new temporary variables inside a
--:  metacalls will still free them after the call completes. Temporary variables can be made immutable too.
--:
--: The lua api is free to change/define any kinds of variables without restrictions.
--:
--: Configuration Variables
--: ^^^^^^^^^^^^^^^^^^^^^^^
--:
--: Following configuration variables are used by the strsubst engine and can be used to configure certain aspects:
--:
--=configvars
--:
--: Examples
--: ~~~~~~~~
--:
--: The best way to describe how strsubst works is by examples, however these examples
--: do not cover every operator.
--:
--: Text without defined operators is returned verbatim (see the dot at the end is not a defined operator)
--:
--:  strsubst "Only text {here.}" == "Only text here."
--:
--: Undefined variables return an empty string (unless in partial evaluation mode)
--:
--:  strsubst "You see {$nothing}" == "You see "
--:
--: Operator characters and braces can be escaped by a backslash or put them into braces. Note that Lua literal strings
--: need to escape the backslash by itself.
--:
--:  strsubst "\\{foo=bar\\}" == "{foo=bar}"
--:  strsubst "{foo\\=bar}" == "foo=bar"
--:  strsubst "{foo{=}bar}" == "foo=bar"
--:
--: Variables are silently defined with ':=' and print their value with '='
--:
--:  strsubst "{foo:=bar}" == ""
--:  strsubst "{foo=bar}" == "bar"
--:
--: Normal variables are global and their definition is retained
--:
--:  strsubst "assigned above: {$foo}" == "assigned above: bar"
--:
--: Variables with only uppercase characters, digits and underscores in the name are immutable. Once set,
--: they can not reassigned from within expressions (but still from the lua api).
--:
--:  strsubst "{BAR=bar}{BAR=baz}" == "barbar"
--:
--: Variables starting with one underscore are temporary. Their definition is cleared on the next invocation.
--:
--:  strsubst "{_tmp:=temporary}{$_tmp}" == "temporary"
--:  strsubst "{$_tmp}" == ""
--:
--: Variables starting with 2 underscores are internally used and are immutable.
--:
--:  strsubst "{__IMMUTABLE=hack the system}" == "^[A-Z0-9_]*$"
--:
--: The '$$' operator calls a recursive substr evaluation on a variable, the lvalue of $$ is stored in '{$_}'
--: (configureable in __PARAMETER) this way one can create simple macros
--:
--:  strsubst "{macro={``{got $_}}}" == "{got $_}"
--:  strsubst "{parameter$$macro}" == "got parameter"
--:
--: named parameter can be passed in in (temporary) variables.
--:
--:  strsubst "{macro={``{_tmp is $_tmp}}}" == "{_tmp is $_tmp}"
--:  strsubst "{_tmp:=first$$macro}" == "_tmp is first"
--:  strsubst "{_tmp:=second$$macro}" == "_tmp is second"
--:
--: The '$$$' operator calls a indirect recursive substr evaluation on a variable,
--: the lvalue of $$ is stored in '{$_}', unlike the '$$' operator the rvalue is
--: evaluated to produce a new variable name like "{lvalue$${lvalue$$rvalue}}" would do.
--:
--:  strsubst "{foo_bar:={``foobar selected}}" == ""
--:  strsubst "{select:=bar}" == ""
--:  strsubst "{foo:={foo_$select}}" == ""
--:  strsubst "{$$$foo}" == "foobar selected"
--:
--: Metacalls which are recursive will eventually yield an error which is passed up as result of the evaluation.
--:
--: The '~~' postfix operator discards its operand, but side effects are evaluated
--:
--:  strsubst "{foo=bar~~}{$foo~~}" == ""
--:
--: There are no prefix operators, only infix and postfix. What looks like a prefix is actually a empty string followed
--: by the operator. Evaluated expressions are concatenated from left to right.
--:
--:  strsubst "{foo:=bar}{foo$foo}" == "foobar"
--:
--: Nested subexpressions are evaluated first, their result is then inserted into the enclosing level. This way one can construct
--: variable names dynamically.
--:
--:  strsubst "{foo:=bar}{ooh:=o}{foo is ${f{{$ooh}{o}}}}" == "foo is bar"
--:
--: In logic only empty strings count as *false*, everything else ist *true*. Comparsions return either a empty string
--: or the string 'true'.
--:
--:  strsubst "{a==b}" == ""
--:  strsubst "{a==a}" == "true"
--:  strsubst "{==}" == "true"  -- compare an empty string wth an empty string
--:
--: The logic operators || and && operate left to right with short-circruit evaluation like in C
--:
--:  strsubst "{a||{b:=set}}{$b}" == "a"
--:  strsubst "{||{b=set}}{$b}" == "setset"
--:
--: Arithmetic operators are prepended with a #, If an operand can not be interpreted as a number, 'nan' will be returned.
--: Divison by zero returns 'inf'. Numbers are interpreted in any formats lua 'tonumber()' understands
--:
--:  strsubst "{foo#+bar}" == "nan"
--:  strsubst "{0xbabe#*1e-1}" == "4780.6"
--:  strsubst "{1#/0}" == "inf"
--:
--: Everything, even arithmetic is evaluated left to right there is no operator precedence
--:
--:  strsubst "{1#+2#*3}" == "9"
--:  strsubst "{1#+{2#*3}}" == "7"
--:
--: To output numbers in other bases one can use the string format operator '@'
--:
--:  strsubst "{30@0x%X}" == "0x1E"
--:
--:
--: Prededfined Operators
--: ~~~~~~~~~~~~~~~~~~~~~
--:
--@strsubst
--:
--:
--: Lua API
--: ~~~~~~~
--:
--: The API is completely realized using a metatable/operators, this allows easily readable usage.
--: Using only metacalls allows unique access to the stored variables with the indexing operators.
--:
--@strsubst_api
--:
--:
--: License
--: ~~~~~~~
--:
--=license
--:
local function strsubst(text, tmpvars)
  if strsubst_vars.__EXPLICIT ~= "" and not text:match("^{") then
    return text
  end
  -- expand character escapes
  if strsubst_vars.__PARTIAL ~= "" then
    text = text:gsub("\\([{}\\])",
                     {
                       ["\\"] = "{$__BACKSLASH}{$__BACKSLASH}",
                       ["{"] = "{$__BACKSLASH}{$__BRACEOPEN}",
                       ["}"] = "{$__BACKSLASH}{$__BRACECLOSE}",
                     }
    ):gsub("\\(["..punct.."])", "{%1}")
  else
    text = text:gsub("\\([{}\\])",
                     {
                       ["\\"] = "{$__BACKSLASH}",
                       ["{"] = "{$__BRACEOPEN}",
                       ["}"] = "{$__BRACECLOSE}",
                     }
    ):gsub("\\(["..punct.."])", "{%1}")
  end

  -- existing tmp variables are available to metacalls
  local tmp = strsubst_vars_tmp
  strsubst_vars_tmp = setmetatable(tmpvars or {},
    {
      __index = strsubst_vars_tmp or strsubst_vars
    }
  )

  local ok, partial
  --text, partial = strsubst_intern(text, {tokenize = literal})
  ok, text, partial = pcall(strsubst_intern, text, {tokenize = literal})

  strsubst_vars_tmp = tmp

  -- covert character escapes back
  return (text:gsub("{$([^}]*)}",
                    {
                      __BACKSLASH = "\\",
                      __BRACEOPEN = "{",
                      __BRACECLOSE = "}",
                    }
  )), partial
end





--strsubst:literal
--: .{`literal}
--: The text in 'literal' is treated as-is, no operators are evaluated. Nested braced expressions are still evaluated
strsubst_operators["`"] = {
  postfix = function(val)
    return val, {}
  end
}

--strsubst:literal
--: .{``literal recursive}
--: The text in 'literal recursive' is treated as-is, no operators are evaluated including nested braced expressions.
strsubst_operators["``"] = {
  postfix = function(val)
    return val, {tokenize = literalrec}
  end
}

--strsubst:discard
--: .{discard~~}
--: evaluates 'discard' for its side-effects but throws the result away.
strsubst_operators["~~"] = {
  postfix = function()
    return "", strsubst_operators
  end
}

--strsubst:variable
--: .{$var}
--: Expands to the value of variable 'var'. When 'var' is not defined, expands to an empty string.
strsubst_operators["$"] = {
  infix = function(lval, rval)
    -- if strsubst_vars.__PARTIAL ~= ""  or strsubst_vars_tmp[rval] or rval == "" then
    if strsubst_vars.__PARTIAL == "" or strsubst_vars_tmp[rval]  then
      return lval..(strsubst_vars_tmp[rval] or "")
    else
      return nil
    end
  end
}

--strsubst:variable
--: .{param$$var}
--: Meta expansion to the value of variable 'var'. When 'var' is not defined, expands to an empty string.
--: Expressions within the variable value are expanded recursively. Temporary variables from the calling
--: environment are available. Temporary variables defined inside the expansion are deleted at return.
--: the 'param' is passed passed in the variable '_' as temporary variable. This name can be changed
--: with the '__PARAMETER' variable.
strsubst_operators["$$"] = {
  infix = function(lval, rval)
    if strsubst_vars.__PARTIAL == "" or strsubst_vars_tmp[rval]  then
      return strsubst(strsubst_vars_tmp[rval] or "", {[strsubst_vars.__PARAMETER] = lval})
    else
      return nil
    end
  end
}


--strsubst:variable
--: .{param$$$var}
--: Meta expansion of variable 'var' with one extra layer of indirection.
--: Same as "{param$${param$$var}}".
strsubst_operators["$$$"] = {
  infix = function(lval, rval)
    if strsubst_vars.__PARTIAL == "" or strsubst_vars_tmp[rval]  then
      return strsubst
      (
        strsubst_vars_tmp
        [
          (strsubst(strsubst_vars_tmp[rval],{[strsubst_vars.__PARAMETER] = lval})) or ""
        ] or "",
        {[strsubst_vars.__PARAMETER] = lval}
      )
    else
      return nil
    end
  end
}


--strsubst:variable
--: .{var=value}
--: Assigns 'value' to 'var' and returns the variables content.
--: See [[Variables]] above for different flavors of variables.
strsubst_operators["="] = {
  infix = function(lval, rval)
    if #lval > 0 and not strsubst_vars_tmp[lval] or (not lval:match("^__") and not lval:match(strsubst_vars.__IMMUTABLE)) then
      if lval:match(strsubst_vars.__TEMPORARY) then
        strsubst_vars_tmp[lval] = rval
      else
        strsubst_vars[lval] = rval
      end
    end
    return strsubst_vars_tmp[lval] or ""
  end
}

--strsubst:variable
--: .{var:=value}
--: Assigns 'value' to variable 'var', returns an empty string.
strsubst_operators[":="] = {
  infix = function(lval, rval)
    if #lval > 0 and not strsubst_vars_tmp[lval] or (not lval:match("^__") and not lval:match(strsubst_vars.__IMMUTABLE)) then
      if lval:match(strsubst_vars.__TEMPORARY) then
        strsubst_vars_tmp[lval] = rval
      else
        strsubst_vars[lval] = rval
      end
    end
    return ""
  end
}


--strsubst:ifthenelse
--: .{if?then:else}
--: When the string in 'if' is not an empty string then evaluate the 'then' part, otherwise evaluate the 'else' part.
strsubst_operators["?"] = {
  postfix = function(val)
    if val ~= "" then
      return "",
      {
        tokenize = evaluate,
        [":"] = {
          postfix = function (val)
            return val, {tokenize = skip}
          end
        },
      }
    else
      return "",
      {
        tokenize = skip,
        [":"] = {
          postfix = function (val)
            return "", strsubst_operators
          end,
          infix = function (lval, rval)
            return rval
          end
        }
      }
    end
  end
}


--strsubst:substring
--: .{text:offset} {text:offset:length}
--: Returns the substring from 'text' starting at 'offset', starting at one. from the begin of offset is positive or from the end
--: when offset is negative. When 'length' is given, then the result is limited to the length.
--:
--: 'offset' and 'length' can be in any number format lua understands, or a string, then the length of the string minus one is taken
--: to calculate the number. If 'offset' is a string and starts with an uppercase 'R' then the offset is taken from the end of 'text'.
strsubst_operators[":"] = {
  postfix = function(val)
    return val,
    {
      tokenize = evaluate,
      [":"] = {
        infix = function (lval, rval)
          return lval:sub(1, tonumber(rval) or (#rval-1))
        end
      }
    }
  end,
  infix = function(lval, rval)
    return lval:sub(tonumber(rval) or ((rval:match("^R") and -#rval+1 or #rval)))
  end
}

--strsubst:length
--: .{#length}
--: Returns the length in bytes of the string 'length'.
strsubst_operators["#"] = {
  infix = function(lval, rval)
    return lval..#rval
  end
}

--strsubst:length
--: .{text##repeat}
--: repeats 'text' for 'repeat' times. When 'repeat' can not be interpreted as number
--: then its length in bytes minus one is taken as number of repeats.
strsubst_operators["##"] = {
  infix = function(lval, rval)
    local r = ""
    for i=1,(tonumber(rval) or #rval-1) do
      r = r..lval
    end
    return r
  end
}

--strsubst:searchreplace
--: .{text/search/replace}
--: Replaces the first occurence of the lua pattern 'search' within 'text' with 'replace'.
strsubst_operators["/"] = {
  postfix = function(val)
    return "",
    {
      tokenize = evaluate,
      ["/"] = {
        infix = function (lval, rval)
          return (val:gsub(lval, rval, 1))
        end
      }
    }
  end
}

--strsubst:searchreplace
--: .{text//search/replace}
--: Replaces all occurences of the lua pattern 'search' within 'text' with 'replace'.
strsubst_operators["//"] = {
  postfix = function(val)
    return "",
    {
      tokenize = evaluate,
      ["/"] = {
        infix = function (lval, rval)
          return (val:gsub(lval, rval))
        end
      }
    }
  end
}

--strsubst:caseconf
--: .{^^text}
--: Returns the (ASCII) uppercase conversion of 'text'.
strsubst_operators["^^"] = {
  infix = function(lval, rval)
    return lval..rval:upper()
  end,
}

--strsubst:caseconf
--: .{,,text}
--: Returns the (ASCII) lowercase conversion of 'text'.
strsubst_operators[",,"] = {
  infix = function(lval, rval)
    return lval..rval:lower()
  end,
}

-- logic ops
--strsubst:logic
--: .{x||y}
--: Logic OR with left to right short-circruit evaluation. When 'x' is true, 'x' is returned,
--: else if 'y' is true 'y' is returned, otherwise a empty string is returned.
strsubst_operators["||"] = {
  postfix = function(val)
    if val ~= "" then
      return val, {tokenize = skip}
    else
      return "", strsubst_operators
    end
  end,
  infix = function(lval, rval)
    return lval ~= "" and lval or rval
  end,
}

--: .{x&&y}
--: Logic AND with left to right short-circruit evaluation. When 'x' is false, an empty string
--: is returned, else if 'y' is true 'y' is returned, otherwise a empty string is returned.
strsubst_operators["&&"] = {
  postfix = function(val)
    if val ~= "" then
      return "", strsubst_operators
    else
      return "", {tokenize = skip}
    end
  end,
  infix = function(lval, rval)
    return rval
  end,
}

--: .{!!x}
--: Logic NOT operator. When 'x' is false (empty string) then "true" is returned, otherwise an empty string is returned
strsubst_operators["!!"] = {
  infix = function(lval, rval)
    return lval..( rval ~= "" and "" or "true")
  end,
}

-- comparisons
--strsubst:matching
--: .{text=~pattern}
--: Returns "true" when 'text' matches 'pattern' are equal, otherwise an empty string.
strsubst_operators["=~"] = {
  infix = function(lval, rval)
    return lval:match(rval) and "true" or ""
  end,
}

-- comparisons
--strsubst:comparisons
--: .{x==y}
--: Lexicographic equivalence. Returns "true" when 'x' and 'y' are equal, otherwise an empty string.
strsubst_operators["=="] = {
  infix = function(lval, rval)
    return lval == rval and "true" or ""
  end,
}

--: .{x#==y}
--: Numeric equivalence. Returns "true" when 'x' and 'y' hold the same numeric value, otherwise an empty string.
strsubst_operators["#=="] = {
  infix = function(lval, rval)
    return (tonumber(lval) or NaN) == (tonumber(rval) or NaN) and "true" or ""
  end,
}

--: .{x!=y}
--: Lexicographic inequality. Returns "true" when 'x' and 'y' are not equal, otherwise an empty string
strsubst_operators["!="] = {
  infix = function(lval, rval)
    return lval ~= rval and "true" or ""
  end,
}

--: .{x#!=y}
--: Numeric inequality. Returns "true" when 'x' and 'y' are not equal numbers, otherwise an empty string
strsubst_operators["#!="] = {
  infix = function(lval, rval)
    return (tonumber(lval) or NaN) ~= (tonumber(rval) or NaN) and "true" or ""
  end,
}

--: .{x<=y}
--: Lexicographic less or equal than. Returns "true" when 'x' sorts same or before 'y', otherwise an empty string
strsubst_operators["<="] = {
  infix = function(lval, rval)
    return lval <= rval and "true" or ""
  end,
}

--strsubst:
--: .{x#<=y}
--: Numeric less or equal than. Returns "true" when 'x' is smaller than 'y', otherwise an empty string
strsubst_operators["#<="] = {
  infix = function(lval, rval)
    return (tonumber(lval) or NaN) <= (tonumber(rval) or NaN) and "true" or ""
  end,
}

--: .{x>=y}
--: Lexicographic biggier or equal than. Returns "true" when 'x' sorts same or after 'y', otherwise an empty string
strsubst_operators[">="] = {
  infix = function(lval, rval)
    return lval >= rval and "true" or ""
  end,
}

--strsubst:
--: .{x#>=y}
--: Numeric more or equal than. Returns "true" when 'x' is biggier or the same as 'y', otherwise an empty string
strsubst_operators["#>="] = {
  infix = function(lval, rval)
    return (tonumber(lval) or NaN) >= (tonumber(rval) or NaN) and "true" or ""
  end,
}

--: .{x<y}
--: Lexicographic less than. Returns "true" when 'x' before 'y', otherwise an empty string
strsubst_operators["<"] = {
  infix = function(lval, rval)
    return lval < rval and "true" or ""
  end,
}

--strsubst:
--: .{x#<y}
--: Numeric less than. Returns "true" when 'x' is smaller than 'y', otherwise an empty string
strsubst_operators["#<"] = {
  infix = function(lval, rval)
    return (tonumber(lval) or NaN) < (tonumber(rval) or NaN) and "true" or ""
  end,
}

--strsubst:
--: .{x>y}
--: Lexicographic biggier than. Returns "true" when 'x' sorts same or before 'y', otherwise an empty string
strsubst_operators[">"] = {
  infix = function(lval, rval)
    return lval > rval and "true" or ""
  end,
}

--strsubst:
--: .{x#>y}
--: Numeric biggier than. Returns "true" when 'x' is biggier than 'y', otherwise an empty string
strsubst_operators["#>"] = {
  infix = function(lval, rval)
    return (tonumber(lval) or NaN) > (tonumber(rval) or NaN) and "true" or ""
  end,
}


--strsubst:
--: .{text@format}
--: Returns 'text' formatted with the 'format' specifier as lua string.format does.
strsubst_operators["@"] = {
  infix = function(lval, rval)
    return string.format(rval, lval)
  end,
}


--strsubst:
--: .{text@@func}
--: call user defined funcion
--strsubst_operators["@@"] = {
--  infix = function(lval, rval)
--    return string.format(rval, lval)
--  end,
--}




-- arithmetic
--strsubst:
--: .{x#+y}
--: Arithmetic addition, returns 'x+y'.
strsubst_operators["#+"] = {
  infix = function(lval, rval)
    return (tonumber(lval) or NaN) + (tonumber(rval) or NaN)
  end,
}

--strsubst:
--: .{x#-y}
--: Arithmetic subtraction, returns 'x-y'.
strsubst_operators["#-"] = {
  infix = function(lval, rval)
    return (tonumber(lval) or NaN) - (tonumber(rval) or NaN)
  end,
}

--strsubst:
--: .{#*}
--: Arithmetic multiplication, returns 'x-y'.
strsubst_operators["#*"] = {
  infix = function(lval, rval)
    return (tonumber(lval) or NaN) * (tonumber(rval) or NaN)
  end,
}

--strsubst:
--: .{#/}
--: Arithmetic division, returns 'x/y'.
strsubst_operators["#/"] = {
  infix = function(lval, rval)
    return (tonumber(lval) or NaN) / (tonumber(rval) or NaN)
  end,
}

--strsubst:
--: .{#%}
--: Arithmetic modulo, returns the remainder of the interger divison of 'x/y'.
strsubst_operators["#%"] = {
  infix = function(lval, rval)
    return (tonumber(lval) or NaN) % (tonumber(rval) or NaN)
  end,
}

--strsubst:
--: .{#**}
--: Arithmetic power, returns pow(x,y).
strsubst_operators["#**"] = {
  infix = function(lval, rval)
    return (tonumber(lval) or NaN) ^ (tonumber(rval) or NaN)
  end,
}

--strsubst:
--: .{func#@x}
--: Math function calls math.func(x) from the lua math library.
--: If 'func' is not a math function then "error: no math function 'func'" is returned.
--: if 'x' can't be interpreted as number then "nan" is returned.
--: This operator passes only one argument to math functions. thus functions requireing more
--: parameters are not supported.
strsubst_operators["#@"] = {
  infix = function(lval, rval)
    if type(math[lval]) == 'function' then
      return math[lval](tonumber(rval) or NaN)
    else
      return "error: no math function '"..lval.."'"
    end
  end
}


return setmetatable (
  {},
  {
    __index = function (_, name)
      assert(type(name) == 'string')
      if not name:match("^["..punct.."]$") then
        --strsubst_api:variable
        --: `strsubst[name]`::
        --:   Returns the value of variable 'name'.
        --:
        return strsubst_vars[name]
      else
        --strsubst_api:operator
        --: `strsubst[operator]`::
        --:   Returns the definition of the operator 'name'
        --:
        return strsubst_operators[name]
      end
    end,


    __newindex = function (_, name, value)
      assert(type(name) == 'string')
      if not name:match("^["..punct.."]$") then
        --strsubst_api:variable
        --: `strsubst[name] = definition`::
        --: `strsubst.name = definition`::
        --:   When the 'name' does not match the 'punct' pattern (operator names) and definition is a string or a number or nil,
        --:   a variable is set or deleted. One can set and change any variable from this API call, even internally used ones
        --:   (and possibly break something).
        --:
        assert(not value or (type(value) == 'string' or type(value) == 'number'))
        strsubst_vars[name] = value
      else
        --strsubst_api:operator
        --: `strsubst[name] = definition`::
        --:
        --:   When the 'name' matches the 'punct' pattern (operator names) and definition is a table or nil an operator is
        --:   modified.
        --:
        --:   Extends the engine with a new custom defined operator.
        --:   'name' must be the new operator token consisting from any combination of the character set
        --:     "-$%&/=?`@+*~#,;.:<>|^!".
        --:
        --:   'definition' must be a table containing up to 2 functions named:
        --:    `postfix`::
        --:      A function which is immediately called with the left operand of the operator.
        --:      Returns the result of applying the operator to this value.
        --:      Additionally it may return a new operator table to implement special tokenizers and ternary
        --:      operators. Refer to the strsubst source for details.
        --:    `infix`::
        --:      A function with is called with the left and right operands and return the result
        --:      of the operation. May return 'nil' in partial evaluation mode to signify that the operation
        --:      can not be evaluated at this time.
        --:
        --:    The operands are always strings or numbers.
        --:
        assert(not definition or type(definition) == 'table' and type(definition.infix) == 'function' or type(definition.postfix) == 'function')
        strsubst_operators[name] = definition
      end
    end,


    __call = function(_, op, ...)
      assert(type(op) == 'string' or type(op) == 'table')
      if type(op) == 'string' then
        --strsubst_api:call
        --: `strsubst "text"`::
        --: `strsubst("text", {tmpvars})`::
        --:   Calls the subtitution engine,'tmpvars' can be used to pass a optional table of temporary variables for this call.
        --:   Returns the result of replacing expressions in 'text' and a optional second return which is 'true' when in partial
        --:   evaluation mode the expression could not be completely evaluated.
        local tmpvars = ...
        if tmpvars then
          assert(type(tmpvars) == 'table')
          for k,v in pairs(tmpvars) do
            assert(type(k) == 'string' and (type(v) == 'string' or type(v) == 'number'))
          end
        end

        return strsubst(op, tmpvars)
      else
        --strsubst_api:vartable
        --: `strsubst {newvars}`::
        --:   Associate a new variable table to the string substitution engine.
        --:   A variable table must only contain key:value pairs of type 'string'.
        --:   Adds some internally used variables if necessary.
        --:   Returns the old variable table. There is already an empty variable table at startup,
        --:   if one doesn't want to swap it, defaults are ok.
        for k,v in pairs(op) do
          assert(type(k) == 'string' and (type(v) == 'string' or type(v) == 'number'))
        end
        local oldvars = strsubst_vars
        strsubst_vars = op
        prepare_vartable()
        return oldvars
      end
    end,
  }
)
