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
   fprintf( stderr, "mulle-genstrings [-o <outputDir>] <sources>\n"
           "\n"
           "\t-o outputDir : the directory to contain the Localizable.strings file\n"
           "\n"
           "\tsources : any kind of text files, probably .m files\n");
   _exit( 1);
}


static NSArray  *parameterCollectionFromFile( NSString *file)
{
   NSString         *input;
   NSEnumerator     *rover;
   NSArray          *parameters;
   NSMutableArray   *collection;
   NSError          *error;
   
   collection = [NSMutableArray array];
   @autoreleasepool
   {
      input = [NSString stringWithContentsOfFile:file
                                        encoding:NSUTF8StringEncoding
                                           error:&error];
      if( ! input)
      {
         fprintf( stderr, "Failed to read \"%s\": %s\n",
              [file fileSystemRepresentation],
              [[error description] cString]);
         exit( 1);
      }
      
      if( ! [input rangeOfString:@"NSLocalizedString"].length)
         return( nil);  // nothing to do
      
      /* read NSLocalizedString parameters from input */
      rover = [input mulleEnumerateNSLocalizedStringParameters];
      while( parameters = [rover nextObject])
      {
         NSCParameterAssert( [parameters count] == 3);
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


int main( int argc, const char * argv[])
{
   MulleCommentedLocalizableStrings   *strings;
   NSArray                            *collection;
   NSString                           *outputFile;
   NSString                           *inputFile;
   BOOL                               chchchchchanges;
   int                                i;
   
   @autoreleasepool
   {
      if( argc <= 2)
         usage();
   
      outputFile      = nil;
      strings         = nil;
      chchchchchanges = YES;
      
      for( i = 1; i < argc; i++)
      {
         if( ! strcmp( argv[ i], "-o"))
         {
            if( outputFile || ++i >= argc)
               usage();
            
            outputFile = [NSString stringWithCString:argv[ i]];
            outputFile = [outputFile stringByAppendingPathComponent:@"Localizable.strings"];

            chchchchchanges = NO;  // do change tracking
            continue;
         }
      
         @autoreleasepool
         {
            inputFile = [NSString stringWithCString:argv[ i]];
            collection = parameterCollectionFromFile( inputFile);
            if( ! collection)
               continue;
            NSCParameterAssert( [collection count]);
            
            [collection retain];
         }
      
         if( ! strings)
         {
            /* now merge key/value/comment collection with previous contents */
            strings = [[[MulleCommentedLocalizableStrings alloc] initWithContentsOfFile:outputFile] autorelease];
            if( ! strings)
               strings = [[MulleCommentedLocalizableStrings new] autorelease];
         }
      
         @autoreleasepool
         {
            chchchchchanges |= [strings mergeParametersArray:collection];
            [collection autorelease];
         }
      }
   
      /* changed something ? then update */
      if( chchchchchanges)
         return( writeLocalizableStrings( strings, outputFile));
   }
   
   return( 0);
}
