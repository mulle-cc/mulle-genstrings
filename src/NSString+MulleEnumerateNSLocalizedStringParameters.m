//
//  NSString+MulleEnumerateNSLocalizedStrings.m
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

#import "NSString+MulleEnumerateNSLocalizedStringParameters.h"

#import "parser.h"


@interface NSData ( MulleNSLocalizedStringEnumerator)

- (NSArray *) mulleUTF16NSLocalizedStringParametersWithCharacterRange:(NSRange) range
                                           numberOfConsumedCharacters:(NSUInteger *) consumed;

@end


@implementation  NSData( MulleNSLocalizedStringEnumerator)

typedef enum
{
   NSLocalizedStringCall = 0,
   NSLocalizedStringFromTableCall,
   NSLocalizedStringFromTableInBundleCall,
   NSLocalizedStringWithDefaultValueCall
} NSLocalizedStringCallType;


static NSLocalizedStringCallType  callTypeForString( NSString *s)
{
   switch( [s length])
   {
   default : return( NSLocalizedStringCall);
   case 26 : return( NSLocalizedStringFromTableCall);
   case 34 : return( NSLocalizedStringFromTableInBundleCall);
   case 33 : return( NSLocalizedStringWithDefaultValueCall);
   }
}


//
// uniform output: key, value, comment
//
- (NSMutableArray *) mulleParseNSLocalizedStringParameters:(parser *) p
{
   NSString         *s;
   NSUInteger       n;
   NSMutableArray   *array;
   
   parser_memorize( p, &p->memo_interesting);

   s = parser_do_identifier( p);
 
   parser_skip_whitespace_and_comments( p);
 
   array = parser_do_array( p);
   if( ! array)
      return( nil);
   
   n = [array count];
   switch( callTypeForString( s))
   {
   case NSLocalizedStringCall :
      if( n != 2)
         return( nil);
      [array insertObject:[array objectAtIndex:0]
                  atIndex:1];
      break;
#if 0
   case NSLocalizedStringFromTableCall :
      if( n != 3)
         return( nil);
      [array removeObjectAtIndex:1];
      [array insertObject:[array objectAtIndex:0]
                  atIndex:1];
      break;

   case NSLocalizedStringFromTableInBundleCall :
      if( n != 4)
         return( nil);
      [array removeObjectAtIndex:1];
      [array removeObjectAtIndex:1];
      [array insertObject:[array objectAtIndex:0]
                  atIndex:1];
      break;

   case NSLocalizedStringWithDefaultValueCall :
      if( n != 5)
         return( nil);
      [array removeObjectAtIndex:1];
      [array removeObjectAtIndex:1];
      break;
#endif

   default :
      return( nil);
   }

   return( array);
}


- (void) parserErrorInFileName:(NSString *) fileName
                    lineNumber:(NSUInteger) lineNumber
                        reason:(NSString *) reason
{
   [NSException raise:NSInvalidArgumentException
               format:@"%@,%lu: %@", fileName ? fileName : @"template", (long) lineNumber, reason];
}


- (NSArray *) mulleUTF16NSLocalizedStringParametersWithCharacterRange:(NSRange) range
                                          numberOfConsumedCharacters:(NSUInteger *) consumed
{
   parser    p;
   NSArray   *values;
   unichar   *buf;
   
   buf    = (unichar *) [self bytes];
   values = nil;
   
NS_DURING
   parser_init( &p, &buf[ range.location], range.length);
   parser_set_error_callback( &p, self, @selector( parserErrorInFileName:lineNumber:reason:));
   
   values    = [self mulleParseNSLocalizedStringParameters:&p];
   *consumed = p.curr - p.buf;
NS_HANDLER
   *consumed = 0;
   // silently ignore
#if DEBUG
   NSLog( @"%@", localException);
#endif
NS_ENDHANDLER
   
   // now parse stuff into our
   return( values);
}

@end


@interface MulleNSLocalizedStringEnumerator : NSEnumerator
{
   NSUInteger   _length;
   NSRange      _range;
   NSData       *_data;
   NSData       *_searchData;
}
@end


@implementation MulleNSLocalizedStringEnumerator

- (void) dealloc
{
   [_data release];
   [_searchData release];
   
   [super dealloc];
}


- (id) initWithString:(NSString *) s
{
   if( self = [super init])
   {
      _length = [s length];
      _range  = NSMakeRange( 1, _length - 1);  // skip leading 0xFEFF
      _data   = [[s dataUsingEncoding:NSUTF16StringEncoding] retain];
      
      _searchData = [@"NSLocalizedString" dataUsingEncoding:NSUTF16StringEncoding];
      _searchData = [[_searchData subdataWithRange:NSMakeRange( 1 * sizeof( unichar), 17 * sizeof( unichar))] retain];
   }
   return( self);
}


- (id) nextObject
{
   NSRange      range;
   NSArray      *parameters;
   NSUInteger   consumed;
   
   if( ! _range.length)
      return( nil);
   
   range = [_data rangeOfData:_searchData
                      options:0
                        range:NSMakeRange( _range.location * sizeof( unichar), _range.length * sizeof( unichar))];
   
   if( ! range.length)
   {
      _range.length = 0;
      return( nil);
   }
   NSParameterAssert( ! (range.location & (sizeof( unichar) - 1)));
   NSParameterAssert( ! (range.length & (sizeof( unichar) - 1)));
   
   range.location /= sizeof( unichar);
   range.length   /= sizeof( unichar);
   
   range.length = _length - range.location;
   parameters   = [_data mulleUTF16NSLocalizedStringParametersWithCharacterRange:range
                                                      numberOfConsumedCharacters:&consumed];
   
   if( ! parameters)
   {
      NSParameterAssert( _range.length >= 17);
      _range.location += 17;  //
      _range.length  -= 17;
      return( [self nextObject]);  // try again
   }
   
  NSParameterAssert( _range.length >= consumed);
   _range.location += consumed;
   _range.length   -= consumed;
   
   return( parameters);
}

@end


@implementation NSString ( MulleEnumerateNSLocalizedStringParameters)

- (NSEnumerator *) mulleEnumerateNSLocalizedStringParameters
{
   return( [[[MulleNSLocalizedStringEnumerator alloc] initWithString:self] autorelease]);
}

@end
