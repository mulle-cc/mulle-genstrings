//
//  NSTask+System.m
//
//  Copyright (c) 2011 Mulle kybernetiK. All rights reserved.
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

#import "NSTask+System.h"


@implementation NSTask( _System)

+ (NSString *) runCommandArray:(NSArray *) argv
              workingDirectory:(NSString *) dir
                      encoding:(NSStringEncoding) encoding
                trimWhitespace:(BOOL) trimWhitespace
{
   NSString      *path;
   NSTask        *task;
   NSPipe        *pipe;
   NSArray       *arguments;
   NSFileHandle  *file;
   NSString      *s;
   NSData        *data;
   int           argc;
   
   argc = [argv count];
   NSParameterAssert( argc);
      
   task = [[NSTask new] autorelease];
   pipe = [NSPipe pipe];

   path = [argv objectAtIndex:0];
   if( ! [path isAbsolutePath])
   {
      [NSException raise:NSGenericException
                  format:@"need absolute path for %@", path];
   }
   [task setLaunchPath:path];

   arguments = [argv subarrayWithRange:NSMakeRange( 1, argc - 1)];
   [task setArguments:arguments];
   [task setStandardInput:[NSPipe pipe]];
   [task setStandardOutput:pipe];
   if( [dir length])
      [task setCurrentDirectoryPath:dir];
   [task launch];
   [task waitUntilExit];   
   if( [task terminationStatus] != 0)
      return( nil);

   file = [pipe fileHandleForReading];
   data = [file readDataToEndOfFile];
   s    = [[[NSString alloc] initWithData:data
                                 encoding:encoding] autorelease];
   
   if( trimWhitespace)
      s = [s stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

   NSParameterAssert( s);
   return( s);
}


//
// simplistic form of system,
// quoting is somewhat similiar to what the shell would do, don't try to stress
// it though
//
+ (NSString *) systemWithString:(NSString *) s
               workingDirectory:(NSString *) dir
{
   NSArray          *argv;
   NSEnumerator     *rover;
   NSString         *substring;
   NSMutableArray   *array;
   NSCharacterSet   *white;
   
   array = [NSMutableArray array];
   white = [NSCharacterSet whitespaceAndNewlineCharacterSet];
   argv  = [s componentsSeparatedByString:@" "];

   rover = [argv objectEnumerator];
   while( substring = [rover nextObject])
   {
      substring = [substring stringByTrimmingCharactersInSet:white];
      if( [substring length])
      {
         if( [substring hasPrefix:@"\'"] && [substring hasSuffix:@"\'"])
         {
            substring = [substring substringWithRange:NSMakeRange( 1, [substring length] - 2)];
            substring = [substring stringByReplacingOccurrencesOfString:@"\\\'"
                                                             withString:@"\'"];
         }
         else
            if( [substring hasPrefix:@"\""] && [substring hasSuffix:@"\""])
            {
               substring = [substring substringWithRange:NSMakeRange( 1, [substring length] - 2)];
               substring = [substring stringByReplacingOccurrencesOfString:@"\\\""
                                                                withString:@"\""];
            }
         [array addObject:substring];
      }
   }
   
   return( [self runCommandArray:array
                workingDirectory:dir
                        encoding:NSUTF8StringEncoding
                  trimWhitespace:YES]);
}

@end
