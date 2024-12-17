### 18.48.7

* fix for deficient Xcode

### 18.48.6 

Some changes for hand-made Localizable.strings files:

* allow // comments, which will be ignored completely
* be lenient if duplicate keys are present, but warn 
* can deal with input UTF8 Localizable string. Merging previously only worked
with UTF16.
* fix output of stray color code in helper scripts


### 18.48.5

* use VERBOSE environment variable to slightly more output
* fix a variety of (apparently harmless) bugs introduced by being able to 
specify the "-s" option.

### 18.48.4
                      
* genstrings doesn't merge anymore by default, you have to explicity specify a
  strings file to merge with "-m".
    
