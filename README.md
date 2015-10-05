# mulle-genstrings

This is like a version of Apple's <b><tt>genstrings</tt></b> first dumbed down 
and then put on steroids. With it's added muscle it is able to merge changes 
with the <tt>Localizable.strings</tt> file. 

The dumbing down, means that it has only two options -a and -o. It always reads 
UTF8 files and it always writes UTF16 files. Dumbest ofall, it can only deal 
with <tt>NSLocalizedString</tt>.

<b><tt>mulle-genstrings</tt></b> tries not to "fix" <b><tt>genstrings</tt></b> 
behaviour too much, except when the output would be clearly broken.

In my tests, the files created by <b><tt>mulle-genstrings</tt></b> are identical 
to the files created with <b><tt>genstrings</tt></b>.

## Usage

Assuming your project is in english and you wrote:

	NSLocalizedString( @"foo", @"this is foo as a verb");

You want to run `mulle-genstrings -o en.lproj *.m`  to generate the english 
<tt>Localizable.strings</tt> and `mulle-genstrings -a -o de.lproj *.m` for other 
language projects.

### -m Option, change search key

You can change the term to search for instead of NSLocalizedString. Useful if
you follow the suggestions from [\"Localizing library code, the right way ?\"](http://www.mulle-kybernetik.com/weblog/2015/localizing_library_code_the_r.html}.

### -t Option, translate key

You can push each value through a translate script, that you specify with the
-t option. Every occurence of {} will be replaced with the value to translate.
The scripe should echo the translated value.


## Author

Coded by Nat! on 16.10.2014