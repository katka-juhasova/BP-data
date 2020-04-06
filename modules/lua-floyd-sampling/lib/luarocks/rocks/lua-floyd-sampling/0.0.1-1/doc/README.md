Floyd's random sampling algorithm
=================================
"Programming Pearls: a sample of brilliance," Communications of the ACM, Volume 30 Issue 9, Sept. 1987, Pages 754-757 

This module implements functions such as sampling, shuffling, and random permutation generator in lua.

Methods
=======

sample
------
`syntax: iter = sample(M, N)`

Generate a random sequence of M intergers in the range [1,N] without replacement.

shuffle
-------
- `syntax: iter = shuffle(N)`
- `syntax: iter = shuffle(M, N)`

Generate a random permutation of M intergers in the range [1,N] without replacement.

doc
---
`pdftex column13.tex`

The column of the "More Programming Pearls".

Author
======
Soojin Nam jsunam@gmail.com

License
=======
Public Domain
