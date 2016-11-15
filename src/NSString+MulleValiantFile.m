//
//  NSString+MulleValiantFile.m
//  mulle-genstrings
//
//  Created by Nat! on 15.11.16.
//  Copyright © 2016 Mulle kybernetiK. All rights reserved.
//

#import "NSString+MulleValiantFile.h"


@implementation NSString( MulleValiantFile)


static struct encoding_info
{
   NSStringEncoding   code;
   char               *name;
   short              bom_len;
   unsigned char      bom[ 4];
} encodings[] =
{
   { NSUTF8StringEncoding,              "NSUTF8StringEncoding", 3, { 0xEF, 0xBB, 0xBF, 0x0 } },
   { NSNonLossyASCIIStringEncoding,     "NSNonLossyASCIIStringEncoding", 0, { 0x0 } },
   { NSMacOSRomanStringEncoding,        "NSMacOSRomanStringEncoding", 0, { 0x0 } },
   { NSISOLatin1StringEncoding,         "NSISOLatin1StringEncoding", 0, { 0x0 } },
   { NSNEXTSTEPStringEncoding,          "NSNEXTSTEPStringEncoding", 0, { 0x0 } },
   { NSUTF32StringEncoding,             "NSUTF32StringEncoding",  4, { 0xFF, 0xFE, 0x00, 0x00 }},
   { NSUTF16LittleEndianStringEncoding, "NSUTF16LittleEndianStringEncoding", 2, { 0xFF, 0xFE, 0x00, 0x00 }},
   { NSUTF16BigEndianStringEncoding,    "NSUTF16BigEndianStringEncoding", 2, { 0xFE, 0xFF, 0x00, 0x00 } },
   { 0, 0 }
};


+ (id) stringWithValiantlyDeterminedContentsOfFile:(NSString *) file
{
   NSData          *data;
   NSError         *error;
   NSString        *s;
   NSUInteger      bom_len;
   NSUInteger      i;
   NSUInteger      len;
   unsigned char   bom[ 4];
   
   s    = nil;
   data = [NSData dataWithContentsOfFile:file
                                 options:0
                                   error:&error];
   if( ! data)
   {
      fprintf( stderr, "Failed to open \"%s\": %s\n",
           [file fileSystemRepresentation],
           [[error localizedFailureReason] fileSystemRepresentation]);
      return( nil);
   }

   len = [data length];
   if( ! len)
      return( @"");

   bom_len = len > 4 ? 4 : len;

   memset( bom, 0, sizeof( bom));
   [data getBytes:bom
           length:bom_len];
   
   // determine encoding by BOM if present
   for( i = 0; encodings[ i].code; i++)
   {
      if( ! encodings[ i].bom_len || encodings[ i].bom_len > bom_len)
         continue;
      if( memcmp( bom, encodings[ i].bom, encodings[ i].bom_len))
         continue;

      // ok looks like a winner, snip off bom
      data = [data subdataWithRange:NSMakeRange( encodings[ i].bom_len, len - encodings[ i].bom_len)];
      s    = [[[NSString alloc] initWithData:data
                                    encoding:encodings[ i].code] autorelease];
      if( s)
      {
         if( getenv( "VERBOSE"))
            NSLog( @"\"%@\" has a byte order mark identifying it as %s", file, encodings[ i].name);
         return( s);
      }
   }
   
   for( i = 0; encodings[ i].code; i++)
   {
      s = [[[NSString alloc] initWithData:data
                                 encoding:encodings[ i].code] autorelease];
      if( s)
      {
         if( getenv( "VERBOSE"))
            NSLog( @"\"%@\" appears to be encoded as %s", file, encodings[ i].name);
         return( s);
      }
   }
   
   fprintf( stderr, "Failed to read \"%s\": %s\n",
           [file fileSystemRepresentation],
           data ? [[error description] UTF8String] : "unknown encoding");

   return( nil);
}

@end
