//
//  main.m
//  mulle-genstrings
//
//  Created by Nat! on 16/10/14.
//  Copyright (c) 2014 Mulle kybernetiK. All rights reserved.
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.
//

#import <Foundation/Foundation.h>

#import "MulleCommentedLocalizableStrings.h"
#import "NSString+MulleEnumerateNSLocalizedStringParameters.h"
#import "NSString+MulleValiantFile.h"

#include <stdlib.h>


#define VERSION   "0.1848.7"

BOOL   verbose;

static void   usage()
{
   fprintf( stderr, "mulle-genstrings [options] <sourcefiles|stringsfiles>\n"
           "\n"
           "\tExtracts NSLocalizedStrings from sourcefiles. Parses strings\n"
           "\tfiles and keeps comments intact.\n"
           "\tCan merge the strings in various modes.\n"
           "\tThe default is to replace existing keys and add new keys.\n"
           "\n"
           "\tThe result will be printed, unless a -m or -o option is given\n"
           "\t"
           "\n"
           "Options:\n"
           "\t-a        : don't overwrite key, if it already exists\n"
           "\t-f        : force reading and writing of Localizable.strings file\n"
           "\t-m input  : the directory to contain the source Localizable.strings (or the filename)\n"
           "\t-o output : the directory to contain the Localizable.strings (or the filename)\n"
           "\t-v        : increase verbosity\n"
           "\t-s key    : replace key to search (default is NSLocalizedString)\n"
           "\t-t script : translation script to use for value (given as {}).\n"
           "\t-u        : don't add keys\n"
           "\n");
   exit( 1);
}


// static struct
// {
//    NSStringEncoding  code;
//    char              *name;
// } encodings[] =
// {
//    { NSUTF8StringEncoding,              "NSUTF8StringEncoding" },
//    { NSNonLossyASCIIStringEncoding,     "NSNonLossyASCIIStringEncoding" },
//    { NSUTF32StringEncoding,             "NSUTF32StringEncoding" },
//    { NSUTF16LittleEndianStringEncoding, "NSUTF16LittleEndianStringEncoding" },
//    { NSUTF16BigEndianStringEncoding,    "NSUTF16BigEndianStringEncoding" },
//    { NSMacOSRomanStringEncoding,        "NSMacOSRomanStringEncoding" },
//    { NSISOLatin1StringEncoding,         "NSISOLatin1StringEncoding" },
//    { NSNEXTSTEPStringEncoding,          "NSNEXTSTEPStringEncoding" },
//    { 0, 0 }
// };



static NSString   *valiantlyOpenFile( NSString *file)
{
   NSString  *s;

   s = [NSString stringWithValiantlyDeterminedContentsOfFile:file];
   if( s)
      return( s);
   exit( 1);
}


static NSArray  *parameterCollectionFromFile( NSString *file, NSString *key)
{
   NSArray        *parameters;
   NSEnumerator   *rover;
   NSMutableSet   *collection;
   NSString       *input;

   collection = [NSMutableSet set];
   @autoreleasepool
   {
      input = valiantlyOpenFile( file);

      if( ! [input rangeOfString:key].length)
         return( nil);  // nothing to do

      /* read NSLocalizedString parameters from input */
      rover = [input mulleEnumerateNSLocalizedStringParameters:key];
      while( parameters = [rover nextObject])
      {
         NSCParameterAssert( [parameters count] == 3);
         // can happen with malformed text
         if( [parameters objectAtIndex:0] == [NSNull null] ||
             [parameters objectAtIndex:1] == [NSNull null] ||
             [parameters objectAtIndex:2] == [NSNull null])
            continue;

         [collection addObject:parameters];
      }
   }
   return( [collection allObjects]);
}


static int  writeLocalizableStrings( MulleCommentedLocalizableStrings *strings,
                                     NSString *outputFile,
                                     BOOL isDictionary)
{
   NSString   *output;
   NSError    *error;

   output = [strings localizableStringsDescription];
   if( ! outputFile)
   {
      printf( "%s", [output UTF8String]);
      return( 0);
   }

   error = nil;
   if( ! [output writeToFile:outputFile
                  atomically:YES
                    encoding:NSUTF16StringEncoding
                       error:&error])
   {
      fprintf( stderr, "Failed to write \"%s\": %s\n",
              [outputFile fileSystemRepresentation],
              [[error description] cString]);
      exit( 2);
   }
   return( 0);
}


MulleCommentedLocalizableStrings   *setup_strings( NSString *file)
{
   MulleCommentedLocalizableStrings   *strings;

   /* now merge key/value/comment collection with previous contents */
   strings = nil;
   if( file)
   {
      /* trick: translate strings file by moving them to output
       and then getting them merged (don't use -c) */
      strings = [[[MulleCommentedLocalizableStrings alloc] initWithContentsOfFile:file] autorelease];
      if( ! strings)
      {
         if( [[NSFileManager defaultManager] fileExistsAtPath:file])
         {
            NSLog( @"can't parse %@", file);
            exit( 1);
         }
      }
      else
         if( verbose)
            NSLog( @"read contents of %@ (%ld entries)", file, (long) [[strings keyValues] count]);
   }

   if( ! strings)
   {
      strings = [[MulleCommentedLocalizableStrings new] autorelease];
      if( verbose)
         NSLog( @"creating fresh strings");
   }
   return( strings);
}


static NSString  *completeLocalizableStringsFile( NSString *file)
{
   BOOL   isDirectory;

   if( [[NSFileManager defaultManager] fileExistsAtPath:file
                                            isDirectory:&isDirectory] && isDirectory)
   {
      file = [file stringByAppendingPathComponent:@"Localizable.strings"];
   }
   return( file);
}


static MulleCommentedLocalizableStrings   *readSourceFile( NSString *filename,
                                                           NSString *NSLocalizedStringKey)
{
   MulleCommentedLocalizableStrings   *strings;
   NSArray                            *collection;

   collection = parameterCollectionFromFile( filename, NSLocalizedStringKey);
   if( verbose)
      NSLog( @"%@ contains %ld occurrences of %@", filename, (long) [collection count], NSLocalizedStringKey);
   strings = [[[MulleCommentedLocalizableStrings alloc] initWithParametersArray:collection] autorelease];
   return( strings);
}


static MulleCommentedLocalizableStrings  *readStringsFile( NSString **filename)
{
   MulleCommentedLocalizableStrings   *strings;

   *filename = completeLocalizableStringsFile( *filename);
   strings  = setup_strings( *filename);
   return( strings);
}


static MulleCommentedLocalizableStrings
   *readSourceOrStringsFile( NSString **p_filename,
                             NSString *NSLocalizedStringKey)
{
   MulleCommentedLocalizableStrings   *strings;
   NSString                           *filename;

   @autoreleasepool
   {
      filename = *p_filename;
      if( [[[filename pathExtension] lowercaseString] isEqualToString:@"strings"])
         strings = readStringsFile( p_filename);
      else
         strings = readSourceFile( filename, NSLocalizedStringKey);
      [strings retain];
   }
   [strings autorelease];

   NSLog( @"\"%@\" read %ld string entries", filename, (long) [strings count]);
   return( strings);
}


int main( int argc,  char *argv[])
{
   MulleCommentedLocalizableStrings   *strings;
   MulleCommentedLocalizableStrings   *inputStrings;
   NSString                           *outputFile;
   NSString                           *mergeFile;
   NSString                           *inputFile;
   NSString                           *translator;
   NSString                           *NSLocalizedStringKey;
   BOOL                               chchchanges;
   BOOL                               force;
   BOOL                               isDictionary;
   enum MergeMode                     mergeMode;
   int                                i;

   NSLocalizedStringKey = @"NSLocalizedString";
   translator           = nil;

   force        = NO;
   isDictionary = NO;
   mergeMode    = MergeReplace;
   verbose      = getenv( "VERBOSE") != NULL;

   @autoreleasepool
   {
      if( argc < 2)
         usage();

      outputFile  = nil;
      strings     = nil;
      chchchanges = YES;
      mergeFile   = nil;

      for( i = 1; i < argc; i++)
      {
         if( ! strcmp( argv[ i], "--version"))
         {
            fprintf( stderr, "mulle-genstrings " VERSION "\n");
            exit( 0);
         }

         if( ! strcmp( argv[ i], "-a"))
         {
            mergeMode |= MergeAdd;
            continue;
         }

         if( ! strcmp( argv[ i], "-f"))
         {
            force = YES;
            continue;
         }

         if( ! strcmp( argv[ i], "-h") || ! strcmp( argv[ i], "--help"))
            usage();

         if( ! strcmp( argv[ i], "-m"))
         {
            if( outputFile || strings || mergeFile || ++i >= argc)
               usage();

            mergeFile   = [NSString stringWithCString:argv[ i]];
            strings     = readStringsFile( &mergeFile);
            chchchanges = NO;     // do change tracking
            continue;
         }

         if( ! strcmp( argv[ i], "-o"))
         {
            if( outputFile || ++i >= argc)
               usage();

            outputFile  = [NSString stringWithCString:argv[ i]];
            outputFile  = completeLocalizableStringsFile( outputFile);
            if( ! mergeFile || ! [mergeFile isEqualToString:outputFile])
               chchchanges = YES;   // do no change tracking
            continue;
         }

         if( ! strcmp( argv[ i], "-s"))
         {
            if( i == argc-1)
               exit( 1);

            NSLocalizedStringKey = [[[NSString alloc] initWithCString:argv[ ++i]] autorelease];
            continue;
         }

         if( ! strcmp( argv[ i], "-t"))
         {
            if( i == argc-1)
               exit( 1);

            translator = [[[NSString alloc] initWithCString:argv[ ++i]] autorelease];
            continue;
         }

         if( ! strcmp( argv[ i], "-u"))
         {
            mergeMode |= MergeUpdate;
            continue;
         }

         if( ! strcmp( argv[ i], "-f"))
         {
            verbose = YES;
            continue;
         }

         inputFile    = [[[NSString alloc] initWithCString:argv[ i]] autorelease];
         inputStrings = readSourceOrStringsFile( &inputFile, NSLocalizedStringKey);
         if( ! [inputStrings count])
            continue;

         if( ! strings)
            strings = setup_strings( nil);

         @autoreleasepool
         {
            chchchanges |= [strings mergeCommentedLocalizableStrings:inputStrings
                                                                mode:mergeMode];
         }
      }

      /* changed something ? then update */
      if( chchchanges || force)
      {
         [strings setTranslatorScript:translator];
         return( writeLocalizableStrings( strings, outputFile ? outputFile : mergeFile, isDictionary));
      }
      else
         if( verbose)
            NSLog( @"No changes to write");
   }

   return( 0);
}

