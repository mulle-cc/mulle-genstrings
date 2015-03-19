//
//  MulleCommentedStringsFileParser.m
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
#import "MulleCommentedLocalizableStrings.h"

#import "NSString+MulleQuotedString.h"
#import "NSString+MulleCaseInsensitiveCompare.h"
#import "NSMutableDictionary+MulleSingleOrMultiValueObjects.h"
#import "parser.h"


@implementation MulleCommentedLocalizableStrings

- (void) dealloc
{
   [_keyValues release];
   [_keyComments release];
   [_lastComment release];

   [super dealloc];
}


- (void) parseComment:(parser *) p
{
   parser_skip_peeked_character( p, '/');
   parser_do_token_character( p, '*');
   
   if( ! parser_grab_text_until_comment_end( p))
      parser_error( p, "unexpected end of file in comment");

   [_lastComment autorelease];
   _lastComment = [[NSString alloc] initWithCharacters:p->memo.curr
                                                length:p->curr - p->memo.curr - 2];
}


- (void) parseKeyValue:(parser *) p
{
   NSString   *key;
   NSString   *value;
   NSString   *comment;
   
   key = parser_do_string( p);
   
   parser_do_token_character( p, '=');

   parser_skip_whitespace( p);
   if( parser_peek_character( p) != '"')
      parser_error( p, "'\"' expected");
   
   value = parser_do_string( p);

   parser_do_token_character( p, ';');

   if( [_keyValues objectForKey:key])
      [NSException raise:NSInvalidArgumentException
                  format:@"duplicate key %@ found", key];

   [_keyValues setObject:value
                  forKey:key];
   
   if( _lastComment)
   {
      comment = [_lastComment stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
      [_keyComments setObject:comment
                       forKey:key];

      [_lastComment autorelease];
      _lastComment = nil;
   }
}



- (void) parse:(parser *) p
{
   unichar   c;
   
   c = parser_peek_character( p);
   if( c == 0xFEFF)
      parser_skip_peeked_character( p, c);
 
   for(;;)
   {
      parser_memorize( p, &p->memo_interesting);
      parser_skip_whitespace( p);
      
      c = parser_peek_character( p);
      switch( c)
      {
         case '/' : // comment
            [self parseComment:p];
            break;
            
         case '"' : // string = string
            [self parseKeyValue:p];
            break;
            
         case 0   :
            return;
            
         default  :
            parser_error( p, "unexpected character, expected comment or string");
      }
   }
}


- (void) parserErrorInFileName:(NSString *) fileName
                    lineNumber:(NSUInteger) lineNumber
                        reason:(NSString *) reason
{
   [NSException raise:NSInvalidArgumentException
               format:@"%@", reason];
}


- (id) init
{
   self = [super init];
   if( ! self)
      return( self);
   
   _keyValues   = [NSMutableDictionary new];
   _keyComments = [NSMutableDictionary new];
   
   return( self);
}


- (id) initWithContentsOfFile:(NSString *) file
{
   parser    p;
   NSData    *data;
   NSString  *s;
   
   self = [self init];
   if( ! self)
      return( self);
   
   s = [NSString stringWithContentsOfFile:file];
   if( ! s)
   {
      [self autorelease];
      return( nil);
   }
   
   data = [s dataUsingEncoding:NSUTF16StringEncoding];
   parser_init( &p, [data bytes], [data length] / sizeof( unichar));
   parser_set_filename( &p, file);
   parser_set_error_callback( &p, self, @selector( parserErrorInFileName:lineNumber:reason:));
   
   [self parse:&p];
   
   // now parse stuff into our
   return( self);
}


- (BOOL) mergeKey:(NSString *) key
            value:(NSString *) value
          comment:(NSString *) comment
          addOnly:(BOOL) addOnly
{
   NSString       *oldValue;
   NSArray        *comments;
   BOOL           chchchchchanges;
   
   chchchchchanges = NO;
   
   if ( [comment rangeOfString:@"*/"].length)
      comment = [[comment componentsSeparatedByString:@"*/"] componentsJoinedByString:@"* /"];
   
   oldValue = [_keyValues objectForKey:key];
   if ( [oldValue rangeOfString:@"*/"].length)
      oldValue = [[oldValue componentsSeparatedByString:@"*/"] componentsJoinedByString:@"* /"];
   
   if( ! [oldValue isEqualToString:value])
   {
      if( ! addOnly || ! oldValue)
      {
         [_keyValues setObject:value
                        forKey:key];
         chchchchchanges = YES;
      }
   }
   
   comment  = [comment stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
   comments = [_keyComments mulleObjectsForKey:key];
   if( ! comments)
   {
      if( comment)
      {
         [_keyComments mulleAddObject:comment
                               forKey:key];
         return( YES);
      }
      return( chchchchchanges);
   }
   
   if( [comments containsObject:comment])
      return( chchchchchanges);
   
   [_keyComments mulleAddObject:comment
               withSortSelector:@selector( mulleCaseInsensitiveCompare:)
                         forKey:key];
   return( YES);
}


- (BOOL) mergeParameters:(NSArray *) parameters
                  addOnly:(BOOL) addOnly
{
   NSString       *key;
   NSString       *value;
   NSString       *comment;
   
   key     = [parameters objectAtIndex:0];
   value   = [parameters objectAtIndex:1];
   comment = [parameters objectAtIndex:2];
   
   return( [self mergeKey:key
                    value:value
                  comment:comment
                  addOnly:addOnly]);
}


- (BOOL) mergeParametersArray:(NSArray *) collection
                      addOnly:(BOOL) addOnly
{
   NSEnumerator   *rover;
   NSArray        *parameters;
   BOOL           chchchchchanges;
   
   chchchchchanges = NO;
   
   rover = [collection objectEnumerator];
   while( parameters = [rover nextObject])
   {
      @autoreleasepool
      {
         chchchchchanges |= [self mergeParameters:parameters
                                          addOnly:addOnly];
      }
   }
   return( chchchchchanges);
}


- (NSString *) localizableStringsDescription
{
   NSArray           *keys;
   NSArray           *comments;
   NSEnumerator      *rover;
   NSMutableString   *buf;
   NSString          *key;
   NSString          *value;
   NSString          *comment;
   
   buf = [NSMutableString string];
   
   keys  = [_keyValues allKeys];
   keys  = [keys sortedArrayUsingSelector:@selector( mulleCaseInsensitiveCompare:)];
   
   rover = [keys objectEnumerator];
   while( key = [rover nextObject])
   {
      comments = [_keyComments mulleObjectsForKey:key];
      if( comments)
      {
         comment = [comments componentsJoinedByString:@"\n   "];
         
         [buf appendString:@"/* "];
         
         // pedantic
         NSParameterAssert( ! [comment rangeOfString:@"*/"].length);
         
         [buf appendString:comment];
         [buf appendString:@" */\n"];
      }
      
      value = [_keyValues objectForKey:key];
      
      [buf appendString:[key mulleQuotedString]];
      [buf appendString:@" = "];
      [buf appendString:[value mulleQuotedString]];
      [buf appendString:@";\n"];
      [buf appendString:@"\n"];
   }
   return( buf);
}

@end
