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

- (NSArray *) mulleLocalizedStringParametersWithCharacterRange:(NSRange) range
                                                                 type:(NSLocalizedStringCallType) type
                                           numberOfConsumedCharacters:(NSUInteger *) consumed;

@end


@implementation  NSData( MulleNSLocalizedStringEnumerator)


//
// uniform output: key, value, comment
//
- (NSMutableArray *) mulleParseNSLocalizedStringParameters:(parser *) p
                                                      type:(NSLocalizedStringCallType) type
{
   NSUInteger       n;
   NSMutableArray   *array;

   parser_memorize( p, &p->memo_interesting);

   parser_do_identifier( p);
   parser_skip_whitespace_and_comments( p);

   array = parser_do_array( p);
   if( ! array)
      return( nil);

   n = [array count];
   switch( type)
   {
   case NSLocalizedStringCall :
      if( n != 2)
         return( nil);
      [array insertObject:[array objectAtIndex:0]
                  atIndex:1];
      break;

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

   default :
      return( nil);
   }

   return( array);
}


- (void) parserDidFail:(struct parser_error *) error
{
   [NSException raise:NSInvalidArgumentException
               format:@"%@", error->message];
}


- (NSArray *) mulleLocalizedStringParametersWithCharacterRange:(NSRange) range
                                                                 type:(NSLocalizedStringCallType) type
                                           numberOfConsumedCharacters:(NSUInteger *) consumed
{
   parser    p;
   NSArray   *values;
   unichar   *buf;

   buf    = (unichar *) [self bytes];
   values = nil;

NS_DURING
   parser_init( &p, &buf[ range.location], range.length);
   parser_set_error_callback( &p, self, @selector( parserDidFail:));

   values    = [self mulleParseNSLocalizedStringParameters:&p
                                                      type:type];
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
   NSUInteger   _searchLen;

   NSLocalizedStringCallType   _type;
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
            searchKey:(NSString *) key
                 type:(NSLocalizedStringCallType) type
{
   NSData   *data;

   if( self = [super init])
   {
      _type   = type;

      _data   = [[s dataUsingEncoding:NSUnicodeStringEncoding] retain];
      _length = [_data length] / sizeof( unichar);
      _range  = NSMakeRange( 0, _length);

      // snip off BOM from search key
      data = [key dataUsingEncoding:NSUnicodeStringEncoding];
      data = [data subdataWithRange:NSMakeRange( sizeof( unichar), [data length] - sizeof( unichar))];

      _searchLen  = [data length] / sizeof( unichar);
      _searchData = [data retain];
   }
   return( self);
}


- (id) nextObject
{
   NSRange      range;
   NSRange      consumeRange;
   NSArray      *parameters;
   NSUInteger   consumed;

retry:
   if( ! _range.length)
      return( nil);

   // search in data, but treat range as "unichar" unit
   {
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
   }

   consumeRange.location = range.location;
   consumeRange.length   = _length - consumeRange.location;

   parameters = [_data mulleLocalizedStringParametersWithCharacterRange:consumeRange
                                                                   type:_type
                                             numberOfConsumedCharacters:&consumed];

   if( ! parameters)
   {
      NSParameterAssert( _range.length >= _searchLen);

      _range.location += _searchLen;  //
      _range.length   -= _searchLen ;
      goto retry;
   }

  NSParameterAssert( _range.length >= consumed);

   _range.location = range.location + consumed;
   _range.length   = _length - _range.location ;

   return( parameters);
}

@end


@implementation NSString ( MulleEnumerateNSLocalizedStringParameters)

- (NSEnumerator *) mulleEnumerateNSLocalizedStringParameters:(NSString *) key
                                                        type:(NSLocalizedStringCallType) type
{
   return( [[[MulleNSLocalizedStringEnumerator alloc] initWithString:self
                                                           searchKey:key
                                                                type:type] autorelease]);
}

- (NSEnumerator *) mulleEnumerateNSLocalizedStringParameters:(NSString *) key
{
   return( [self mulleEnumerateNSLocalizedStringParameters:key
                                                      type:NSLocalizedStringCall]);
}

@end
