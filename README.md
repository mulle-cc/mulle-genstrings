# mulle-genstrings

This is like a version of Apple's <b><tt>genstrings</tt></b> first dumbed down 
and then put on steroids. With it's added muscle it is able to merge changes 
with the <tt>Localizable.strings</tt> file. 

The dumbing down, means that it only has limited options. It always reads 
UTF8 files and it always writes UTF16 files. Dumbest of all, it can only deal 
with one keyword <tt>NSLocalizedString</tt> (or a substitution keyword)

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

### -s option: change search key

You can change the term to search for instead of ""NSLocalizedString"". Useful if
you follow the suggestions from [\"Localizing library code, the right way ?\"](http://www.mulle-kybernetik.com/weblog/2015/localizing_library_code_the_r.html}.

### -t option: translate value

You can push each localizable strings value through a translate script. The script is specifed with the -t option. Every occurence of {} will be replaced with the value to translate.
The script should echo the translated value.

As an example the "ms-translate.sh" script is provided, that uses [Microsofts Translation API](https://msdn.microsoft.com/en-us/library/mt146806.aspx)
to translate pages. You would call **mulle-genstrings** with `-t "./mulle-ms-translate.sh de pt {}"` to create a translated `Localizable.strings` from german to portugese.

In order for this script to work, you have to register with Microsoft and get the proper secret into `~/.mulle-genstrings-v0/secret`. Currently the MS translation API is free for small loads.
                                                                               
                                                                               
                                                                               
                                                                           
## Author

Coded by Nat! on 16.10.2014