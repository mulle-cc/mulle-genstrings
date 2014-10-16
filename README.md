# mulle-genstrings

This is like a version of Apple's <b><tt>genstrings</tt></b> first dumbed down and then put on steroids. With it's added muscle it is now able to merge changes with the <tt>Localizable.strings</tt> file. 

The dumbing down, means that it has no options except -o. It always reads UTF8 files and it always writes UTF16 files. Dumbest of
all, it can only deal with <tt>NSLocalizedString</tt>.

<b><tt>mulle-genstrings</tt></b> tries not to "fix" <b><tt>genstrings</tt></b> behaviour too much, except when the output would be clearly broken.

In my tests, the files created by <b><tt>mulle-genstrings</tt></b> are identical to the files created with <b><tt>genstrings</tt></b>.


## Author

Coded by Nat! on 16.10.2014