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

#import "NSTask+System.h"
#import "NSString+MulleQuotedString.h"
#import "NSString+MulleCaseInsensitiveCompare.h"
#import "NSString+MulleValiantFile.h"
#import "NSMutableDictionary+MulleSingleOrMultiValueObjects.h"
#import "parser.h"


@implementation MulleCommentedLocalizableStrings

- (void) dealloc
{
   [_keyValues release];
   [_keyComments release];
   [_lastComment release];
   [_translatorScript release];

   [super dealloc];
}


- (void) parseComment:(parser *) p
{
   parser_skip_peeked_character( p, '/');

   // treat // comments as real "invisible" comments
   if( parser_peek_character( p) == '/')
   {
      parser_skip_after_newline( p);
      return;
   }
   else
   {
      parser_do_token_character( p, '*');

      if( ! parser_grab_text_until_comment_end( p))
         parser_error( p, "unexpected end of file in comment");
   }

   [_lastComment autorelease];
   _lastComment = [[NSString alloc] initWithCharacters:p->memo.curr
                                                length:p->curr - p->memo.curr - 2];
}


- (void) parseKeyValue:(parser *) p
{
   NSString   *key;
   NSString   *value;
   NSString   *comment;
   NSCharacterSet  *whitespace;

   if( parser_peek_character( p) == '"')
      key = parser_do_quoted_string( p);
   else
      key = parser_do_string( p);

   parser_do_token_character( p, '=');

   parser_skip_whitespace( p);

   if( parser_peek_character( p) == '"')
      value = parser_do_quoted_string( p);
   else
      value = parser_do_string( p);

   parser_do_token_character( p, ';');

   if( [_keyValues objectForKey:key])
      NSLog( @"duplicate key \"%@\" found, will overwrite previous value", key);

   [_keyValues setObject:value
                  forKey:key];

   if( ! _lastComment)
      return;

   whitespace = [NSCharacterSet whitespaceCharacterSet];
   comment    = [_lastComment stringByTrimmingCharactersInSet:whitespace];

   if( ! getenv("mulle-genstrings-dont-split-comment-lines"))
   {
      NSArray         *components;
      NSEnumerator    *rover;
      NSString        *s;
      NSMutableArray  *array;

      components = [_lastComment componentsSeparatedByString:@"\n"];
      if( [components count] != 1)
      {
         rover = [components objectEnumerator];
         array = [NSMutableArray array];

         while( s = [rover nextObject])
         {
            s = [s stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            if( ! [array containsObject:s])
               [array addObject:s];
         }
         comment = [array componentsJoinedByString:@"\n"];
      }
   }

   [_keyComments setObject:comment
                    forKey:key];
   [_lastComment autorelease];
   _lastComment = nil;
}


- (void) parse:(parser *) p
{
   unichar   c;
   NSData    *data;
   NSError   *error;
   id        plist;

   c = parser_peek_character( p);
   if( c == 0xFEFF)
      parser_skip_peeked_character( p, c);

   c = parser_peek_character( p);
   if( c == '{') // it's really a propertylist
   {
      plist = [NSDictionary dictionaryWithContentsOfFile:p->fileName];
      if( ! plist)
         parser_error( p, "Text looks like a plist, but can't be parsed.");
      _plistFormat = NSPropertyListOpenStepFormat;
      [_keyValues addEntriesFromDictionary:plist];
      return;
   }

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


- (void) parserDidFail:(struct parser_error *) error
{
   fprintf( stderr, "error in %s line %d: %s\n",
         [error->fileName fileSystemRepresentation],
         (int) error->lineNumber,
         [error->message UTF8String]);
   exit( 1);
}


- (id) init
{
   self = [super init];
   if( ! self)
      return( self);

   _keyValues   = [NSMutableDictionary new];
   _keyComments = [NSMutableDictionary new];
   _verbose     = getenv( "VERBOSE") != NULL;
   _plistFormat = -1;
   return( self);
}


- (id) initWithParametersArray:(NSArray *) collection
{
   self = [self init];
   [self mergeParametersArray:collection
                         mode:MergeReplace];
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

   s = [NSString stringWithValiantlyDeterminedContentsOfFile:file];
   if( ! s)
   {
      [self autorelease];
      return( nil);
   }

   data = [s dataUsingEncoding:NSUnicodeStringEncoding];
   parser_init( &p, (void *) [data bytes], [data length] / sizeof( unichar));
   parser_set_filename( &p, file);
   parser_set_error_callback( &p, self, @selector( parserDidFail:));

   [self parse:&p];

   return( self);
}


- (BOOL) mergeKey:(NSString *) key
            value:(NSString *) value
          comment:(NSString *) comment
             mode:(enum MergeMode) mode
{
   NSString   *oldValue;
   NSArray    *comments;
   BOOL       chchchchchanges;

   oldValue = [_keyValues objectForKey:key];
   if( mode & MergeUpdate)
   {
      if( ! oldValue)
         return( NO);
   }

   chchchchchanges = NO;

   if ( [comment rangeOfString:@"*/"].length)
      comment = [[comment componentsSeparatedByString:@"*/"] componentsJoinedByString:@"* /"];


   if ( [oldValue rangeOfString:@"*/"].length)
      oldValue = [[oldValue componentsSeparatedByString:@"*/"] componentsJoinedByString:@"* /"];

   if( ! [oldValue isEqualToString:value])
   {
      if( ! (mode & MergeAdd) || ! oldValue)
      {
         if( _verbose)
         {
            if( oldValue)
               NSLog( @"--> update \"%@\"", key);
            else
               NSLog( @"--> add \"%@\"", key);
         }

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
         if( _verbose)
            NSLog( @"--> add comment to \"%@\"", key);

         [_keyComments mulleAddObject:comment
                               forKey:key];
         return( YES);
      }
      return( chchchchchanges);
   }

   if( [comments containsObject:comment])
      return( chchchchchanges);

   if( _verbose)
      NSLog( @"--> add comment to \"%@\"", key);

   [_keyComments mulleAddObject:comment
               withSortSelector:@selector( mulleCaseInsensitiveCompare:)
                         forKey:key];
   return( YES);
}


- (BOOL) mergeParameters:(NSArray *) parameters
                    mode:(enum MergeMode) mode
{
   NSString   *key;
   NSString   *value;
   NSString   *comment;

   key     = [parameters objectAtIndex:0];
   value   = [parameters objectAtIndex:1];
   comment = [parameters objectAtIndex:2];

   return( [self mergeKey:key
                    value:value
                  comment:comment
                     mode:mode]);
}


- (BOOL) mergeParametersArray:(NSArray *) collection
                         mode:(enum MergeMode) mode
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
                                             mode:mode];
      }
   }
   return( chchchchchanges);
}


- (BOOL) mergeCommentedLocalizableStrings:(MulleCommentedLocalizableStrings *) other
                                     mode:(enum MergeMode) mode
{
   NSEnumerator   *rover;
   NSString       *key;
   NSString       *value;
   NSString       *comment;
   BOOL           chchchchchanges;

   chchchchchanges = NO;

   rover = [other->_keyValues keyEnumerator];
   while( key = [rover nextObject])
   {
      value   = [other->_keyValues objectForKey:key];
      comment = [other->_keyComments objectForKey:key];

      chchchchchanges |= [self mergeKey:key
                                  value:value
                                comment:comment
                                   mode:mode];
   }
   return( chchchchchanges);
}


- (NSString *) translatedValue:(NSString *) value
{
   NSString   *s;
   NSString   *t;

   if( ! _translatorScript)
      return( value);

   s = [_translatorScript stringByReplacingOccurrencesOfString:@"{}"
                                                    withString:value];

   t = [NSTask systemWithString:s
               workingDirectory:nil];
   if( ! t)
   {
      NSLog( @"failed to execute translation script \"%@\"", s);
      exit( 1);
   }

   return( [t length] ? t : s);
}


- (NSUInteger) count
{
   return( [_keyValues count]);
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

   if( _plistFormat == NSPropertyListOpenStepFormat)
      return( [_keyValues description]);

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

      [buf appendString:[key mulleQuotedString]];
      [buf appendString:@" = "];

      value = [_keyValues objectForKey:key];
      value = [self translatedValue:value];
      [buf appendString:[value mulleQuotedString]];
      [buf appendString:@";\n"];
      [buf appendString:@"\n"];
   }
   return( buf);
}

@end
