# luafudge

## fudge.set_lang(lang)
Set a language of FUDGE levels. May be "english", "russian" or "german".
By default, english used. Other languages may be added later.

## fudge.is_valid(level)
Returns `true` if `level` is valid FUDGE level or `false` otherwise.

## fudge.normalize(level)
Returns a normalized level to diceroll. As stated in FUDGE rulebook,
minimal level is `terrible` and maximum is `legendary`. So you can do
`fudge.normalize("very very terrible")` and get `terrible` in result.
If `level` is already accepted FUDGE level, level returned.

## fudge.roll()
Roll 4dF and return 4-table as result. e.g. {-1, -1, 0, +1}

## fudge.dices_to_string(dices)
Convert 4-string of dices (e.g. returned by `fudge.roll()`) to
string of pluses, minuses and equal signs for fancy look.
`assert(fudge.dices_to_string({-1, -1, 0, +1}) == "--=+")`

## fudge.diff(x, y)
Returns a difference between two fudge levels.
`assert(fudge.diff("good", "mediocre") == 2)`

## fudge.add_modifiers(level, ...)
Returns a FUDGE level with appended modifiers. Takes a FUDGE level
and any number of *numbers* or *tables of numbers*.

`assert(fudge.add_modifiers("poor", +1, +1, -3) == "terrible")`

`assert(fudge.add_modifiers("poor", {+1, +1, -3}) == "terrible")`

`fudge.add_modifiers("good", fudge.roll())` will return "terrible"
if dices will misscrit.

----
Authors: hunterdelyx1, vegasd
