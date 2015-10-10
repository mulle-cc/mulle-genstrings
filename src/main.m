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


static void   usage()
{
   fprintf( stderr, "mulle-genstrings [options] <sources>\n"
           "\n"
           "options\n"
           "\t-a        : don't overwrite key, if it already exists\n"
           "\t-f        : force reading and writing of Localizable.strings file\n"
           "\t-m input  : the directory to contain the source Localizable.strings (or the filename)\n"
           "\t-o output : the directory to contain the Localizable.strings (or the filename)\n"
           "\t-v        : print version\n"
           "\t-s key    : replace key to search (default is NSLocalizedString)\n"
           "\t-t script : translation script to use for value (given as {}).\n"
           "\n"
           "sources\n"
           "\t          : any kind of text files, probably .m files\n");
   _exit( 1);
}


static NSStringEncoding   encodings[] =
{
   NSUTF8StringEncoding,
   NSNonLossyASCIIStringEncoding,
   NSMacOSRomanStringEncoding,
   NSISOLatin1StringEncoding,
   NSNEXTSTEPStringEncoding,
   NSUTF16LittleEndianStringEncoding,
   NSUTF16BigEndianStringEncoding,
   NSUTF32StringEncoding,
   0
};


static NSString   *valiantlyOpenFile( NSString *file)
{
   NSError      *error;
   NSData       *data;
   NSString     *s;
   NSUInteger   i;
   
   s    = nil;
   data = [NSData dataWithContentsOfFile:file
                                 options:0
                                   error:&error];
   if( ! data)
   {
      fprintf( stderr, "Failed to open \"%s\": %s\n",
           [file fileSystemRepresentation],
           [[error localizedFailureReason] fileSystemRepresentation]);
      exit( 1);
   }
   
   for( i = 0; encodings[ i]; i++)
   {
      s = [[[NSString alloc] initWithData:data
                                 encoding:encodings[ i]] autorelease];
      if( s)
         return( s);
   }
   
   fprintf( stderr, "Failed to read \"%s\": %s\n",
           [file fileSystemRepresentation],
           data ? [[error description] UTF8String] : "unknown encoding");
   exit( 1);
}


static NSArray  *parameterCollectionFromFile( NSString *file, NSString *key)
{
   NSString           *input;
   NSEnumerator       *rover;
   NSArray            *parameters;
   NSMutableArray     *collection;
   
   collection = [NSMutableArray array];
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
   return( collection);
}


static int  writeLocalizableStrings( MulleCommentedLocalizableStrings *strings, NSString *outputFile)
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
   }
   
   if( ! strings)
      strings = [[MulleCommentedLocalizableStrings new] autorelease];
   return( strings);
}

static NSString  *completeLocalizableStringsFile( NSString *file)
{
   BOOL isDirectory;
   
   if( [[NSFileManager defaultManager] fileExistsAtPath:file
                                            isDirectory:&isDirectory] && isDirectory)
   {
      file = [file stringByAppendingPathComponent:@"Localizable.strings"];
   }
   return( file);
}


int main( int argc, const char * argv[])
{
   MulleCommentedLocalizableStrings   *strings;
   NSArray                            *collection;
   NSString                           *outputFile;
   NSString                           *mergeFile;
   NSString                           *inputFile;
   NSString                           *translator;
   NSString                           *NSLocalizedStringKey;
   BOOL                               chchchanges;
   BOOL                               addOnly;
   BOOL                               force;
   int                                i;
   
   NSLocalizedStringKey = @"NSLocalizedString";
   translator           = nil;
   
   addOnly = NO;
   force   = NO;
   
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
         if( ! strcmp( argv[ i], "-v"))
         {
            fprintf( stderr, "mulle-genstrings v18.48.4\n");
            continue;
         }

         if( ! strcmp( argv[ i], "-a"))
         {
            addOnly = YES;
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
            if( strings || mergeFile || ++i >= argc)
               usage();
            
            mergeFile = [NSString stringWithCString:argv[ i]];
            mergeFile = completeLocalizableStringsFile( mergeFile);
            
            strings = setup_strings( mergeFile);
            
            continue;
         }
         
         if( ! strcmp( argv[ i], "-o"))
         {
            if( outputFile || ++i >= argc)
               usage();
            
            outputFile = [NSString stringWithCString:argv[ i]];
            outputFile = completeLocalizableStringsFile( outputFile);
            chchchanges = NO;  // do change tracking
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

         @autoreleasepool
         {
            inputFile = [NSString stringWithCString:argv[ i]];
            collection = parameterCollectionFromFile( inputFile, NSLocalizedStringKey);
            if( ! [collection count])
               continue;
            
            [collection retain];
         }
      
         if( ! strings)
            strings = setup_strings( nil);
      
         @autoreleasepool
         {
            chchchanges |= [strings mergeParametersArray:collection
                                                 addOnly:addOnly];
            [collection autorelease];
         }
      }
   
      /* changed something ? then update */
      if( chchchanges || force)
      {
         [strings setTranslatorScript:translator];
         return( writeLocalizableStrings( strings, outputFile));
      }
   }
   
   return( 0);
}

