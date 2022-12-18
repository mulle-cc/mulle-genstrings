//
//  parser.c
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
#import "parser.h"

#include <ctype.h>


// "cheap"
#ifndef __MULLE_OBJC__
# define objc_va_list     va_list
# define objc_va_start    va_start
# define objc_va_end      va_end
# define objcVarargList   arguments
#endif


void   parser_init( parser *p, unichar *buf, size_t len)
{
   memset( p, 0, sizeof( parser));
   if( buf && len)
   {
      p->buf        = p->curr = buf;
      p->sentinel   = &p->buf[ len];
      p->lineNumber = 1;
   }
}


void   parser_set_error_callback( parser *p, id self, SEL sel)
{
   p->self        = self;
   p->sel         = sel;
   p->parser_do_error = (void *) [p->self methodForSelector:sel];
}


//
// there is no return, stuff just leaks and we abort
//
void  MULLE_NO_RETURN  parser_error( parser *p, char *c_format, ...)
{
   NSString              *reason;
   NSString              *s;
   size_t                p_len;
   size_t                s_len;
   size_t                i;
   objc_va_list          args;
   unichar               *prefix;
   unichar               *suffix;
   struct parser_error   error;

   if( p->parser_do_error)
   {
      objc_va_start( args, c_format);
      reason = [[[NSString alloc] initWithFormat:[NSString stringWithCString:c_format]
                                  objcVarargList:args] autorelease];
      objc_va_end( args);

      //
      // p->memo_scion.curr is about the start of the parsed object
      // p->curr is where the parsage failed, try to print something interesting
      // near the parse failure (totally heuristic), but not too much
      //
      p_len = p->curr - p->memo_interesting.curr;
      if( p_len > 32)
         p_len = 32;
      if( p_len < 12)
         p_len += 3;

      s_len  = p_len >= 6 ? 12 : 12 + 6 - p_len;
      prefix = &p->curr[ -p_len];
      suffix = &p->curr[ 1];

      if( prefix < p->buf)
      {
         prefix = p->buf;
         p_len  = p->curr - p->buf;
      }

      if( &suffix[ s_len] > p->sentinel)
         s_len  = p->sentinel - p->curr;

      // stop tail at linefeed
      for( i = 0; i < s_len; i++)
         if( suffix[ i] == '\r' || suffix[ i] == '\n' || suffix[ i] == ';' || suffix[ i] == '}' || suffix[ i] == '%')
            break;
      s_len = i;

      // terminal escape sequences
#if HAVE_TERMINAL
#define RED   "\033[01;31m"
#define NONE  "\033[00m"
#else
#define RED   ""
#define NONE  ""
#endif

      s = [NSString stringWithFormat:@"%.*S" RED "%c" NONE "%.*S", (int) p_len, prefix, *p->curr, (int) s_len, suffix];
      s = [s stringByReplacingOccurrencesOfString:@"\n"
                                       withString:@" "];
      s = [s stringByReplacingOccurrencesOfString:@"\r"
                                       withString:@""];
      s = [s stringByReplacingOccurrencesOfString:@"\t"
                                       withString:@" "];
      s = [s stringByReplacingOccurrencesOfString:@"\""
                                       withString:@"\\\""];
      s = [s stringByReplacingOccurrencesOfString:@"'"
                                       withString:@"\\'"];

      s = [NSString stringWithFormat:@"at '%C' near \"%@\", %@", *p->curr, s, reason];

      error.parser     = p;
      error.fileName   = p->fileName;
      error.lineNumber = p->memo.lineNumber;
      error.message    = p->fileName;

      (*p->parser_do_error)( p->self, p->sel, &error);
   }
   abort();
}


# pragma mark -
# pragma mark Tokenizing

static inline void   parser_nl( parser *p)
{
   p->lineNumber++;
}


# pragma mark -
# pragma mark whitespace

void   parser_skip_whitespace( parser *p)
{
   unichar   c;

   for( ; p->curr < p->sentinel; p->curr++)
   {
      c = *p->curr;
      switch( c)
      {
      case '\n' :
         parser_nl( p);
         break;

      default :
         if( c > ' ')
            return;
      }
   }
}


int   parser_skip_text_until_comment_end( parser *p)
{
   unichar   c;
   int       matched;

   matched = 0;

   for( ; p->curr < p->sentinel;)
   {
      c = *p->curr++;
      if( c == '\n')
      {
         parser_nl( p);
         continue;
      }

      if( matched)
      {
         if( c == '/')
            return( 1);

         matched = 0;
         continue;
      }

      if( c == '*')
         matched = 1;
   }
   return( 0);
}


void   parser_skip_after_newline( parser *p)
{
   unichar   c;

   for( ; p->curr < p->sentinel;)
   {
      c = *p->curr++;
      if( c == '\n')
      {
         parser_nl( p);
         break;
      }
   }
}


void   parser_skip_whitespace_and_comments( parser *p)
{
   unichar   c;

   for( ; p->curr < p->sentinel; p->curr++)
   {
      c = *p->curr;
      switch( c)
      {
      case '\n' :
         parser_nl( p);
         break;

      case '/'  :
         switch( parser_peek_character( p))
         {
         case '/' :
            parser_skip_after_newline( p);
            --p->curr; // because we add it again in for
            continue;

         case '*' :
            ++p->curr;
            parser_skip_text_until_comment_end( p);
            --p->curr; // because we add it again in for
            continue;
         }

      default :
         if( c > ' ')
            return;
      }
   }
}


# pragma mark -
# pragma mark scion tags

void   parser_grab_text_until_identifier_end( parser *p)
{
   unichar   c;

   parser_memorize( p, &p->memo);

   for( ; p->curr < p->sentinel; p->curr++)
   {
      c = *p->curr;

      if( c >= '0' && c <= '9')
      {
         if( p->memo.curr == p->curr)
            break;
         continue;
      }

      if( c >= 'A' && c <= 'Z')
         continue;

      if( c >= 'a' && c <= 'z')
         continue;

      if( c == '_')
         continue;

      break;
   }
}


void   parser_grab_text_until_nonidentifier( parser *p)
{
   unichar   c;

   parser_memorize( p, &p->memo);

   for( ; p->curr < p->sentinel;)
   {
      c = *p->curr++;
      if( ispunct( c) || isspace( c))
      {
         p->curr--;
         break;
      }
   }
}


int   parser_grab_text_until_quote( parser *p)
{
   unichar   c;
   int       escaped;

   parser_memorize( p, &p->memo);

   escaped = 0;

   for( ; p->curr < p->sentinel;)
   {
      c = *p->curr++;
      if( c == '\n')
         parser_nl( p);

      if( escaped)
      {
         escaped = 0;
         continue;
      }
      if( c == '\\')
      {
         escaped  = 1;
         continue;
      }
      if( c == '"')
      {
         p->curr--;
         return( 1);
      }
   }
   return( 0);
}


NSString   * NS_RETURNS_RETAINED parser_get_retained_string( parser *p)
{
   NSUInteger   length;
   NSString     *s;

   length = p->curr - p->memo.curr ;
   if( ! length)
      return( nil);

   s = [[NSString alloc] initWithCharacters:p->memo.curr
                                     length:length];
   return( s);
}


unichar   parser_next_character( parser *p)
{
   unichar   c;

   if( p->curr >= p->sentinel)
      return( 0);
   c = *p->curr++;
   if( c == '\n')
      parser_nl( p);
   return( c);
}


void   parser_do_token_character( parser *p, unichar expect)
{
   unichar   c;

   parser_skip_whitespace( p);
   c = parser_next_character( p);
   if( c != expect)
      parser_error( p, "a '%C' character was expected", expect);
}


# pragma mark -
# pragma mark Simple Expressions

NSString  *parser_do_identifier( parser *p)
{
   NSString   *s;

   parser_grab_text_until_identifier_end( p);
   s = parser_get_string( p);
   if( ! s)
      parser_error( p, "an identifier was expected");
   parser_skip_whitespace( p);
   return( s);
}

//
// a parameter is either a string [string]* or an identifier
//
id   parser_do_parameter( parser *p)
{
   unichar    c;
   NSString   *s;
   NSString   *tmp;
   int        ignore;

   ignore = NO;

   s = nil;
   for(;;)
   {
      parser_skip_whitespace_and_comments( p);
      c = parser_peek_character( p);
      if( ! c)
         return( nil);
      if( c == ',' || c == ')')
         return( s ? s : [NSNull null]);

      if( ignore)
      {
         parser_next_character( p);
         continue;
      }

      if( c == '@')
      {
         parser_skip_peeked_character( p, c);
         parser_skip_whitespace_and_comments( p);
         c = parser_peek_character( p);
      }

      if( c == '"')
      {
         tmp = parser_do_quoted_string( p);
         if( s)
            tmp = [s stringByAppendingString:tmp];
         s = tmp;
         continue;
      }

      if( ! c)
         return( nil);

      ignore = YES;
      parser_next_character( p);
   }
}


NSMutableArray  *parser_do_array( parser *p)
{
   NSMutableArray   *array;
   id               obj;
   unichar          c;

   parser_do_token_character( p, '(');

   array = [NSMutableArray array];
   while( obj = parser_do_parameter( p))
   {
      [array addObject:obj];
      c = parser_peek_character( p);
      if( c != ',')
         break;

      parser_next_character( p);
   }

   parser_do_token_character( p, ')');

   return( array);
}



NSString  *parser_do_quoted_string( parser *p)
{
   NSString   *s;

   NSCParameterAssert( parser_peek_character( p) == '"');

   parser_skip_peeked_character( p, '\"');   // skip '"'
   if( ! parser_grab_text_until_quote( p))
      parser_error( p, "a closing double quote '\"' was expected");

   s = parser_get_string( p);
   parser_skip_peeked_character( p, '\"');   // skip '"'
   parser_skip_whitespace( p);

   return( s ? s : @"");
}


NSString  *parser_do_string( parser *p)
{
   NSString   *s;

   parser_grab_text_until_nonidentifier( p);

   s = parser_get_string( p);
   parser_skip_whitespace( p);

   return( s ? s : @"");
}



int   parser_grab_text_until_comment_end( parser *p)
{
   parser_memorize( p, &p->memo);
   return( parser_skip_text_until_comment_end( p));
}
