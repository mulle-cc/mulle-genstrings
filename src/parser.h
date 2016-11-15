//
//  parser.h
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


#ifndef MULLE_NO_RETURN
#  ifdef NO_RETURN
#   define MULLE_NO_RETURN   NO_RETURN
#  else
#   define MULLE_NO_RETURN   __attribute(( __noreturn__))
#  endif
//# define NO_RETURN __declspec(noreturn)
# else
#  define MULLE_NO_RETURN
#endif


typedef struct _parser_memo
{
   unichar      *curr;
   NSUInteger   lineNumber;
} parser_memo;


typedef struct   _parser
{
   unichar       *buf;
   unichar       *sentinel;
   
   unichar       *curr;
   NSUInteger    lineNumber;
   
   parser_memo   memo;
   parser_memo   memo_interesting;
   
   void          (*parser_do_error)( id self, SEL sel, NSString *filename, NSUInteger line, NSString *message);
   
   id            self;
   SEL           sel;
   NSString      *fileName;
} parser;


void   parser_init( parser *p, unichar *buf, size_t len);

void  MULLE_NO_RETURN  parser_error( parser *p, char *c_format, ...);
NSString   * NS_RETURNS_RETAINED parser_get_retained_string( parser *p);
void   parser_set_error_callback( parser *p, id self, SEL sel);

int   parser_grab_text_until_comment_end( parser *p);
void   parser_grab_text_until_identifier_end( parser *p);

NSString  *parser_do_string( parser *p);
NSMutableArray  *parser_do_array( parser *p);
void   parser_do_token_character( parser *p, unichar expect);
NSString  *parser_do_identifier( parser *p);

void   parser_skip_whitespace( parser *p);
void   parser_skip_whitespace_and_comments( parser *p);

void   parser_skip_after_newline( parser *p);

/*
 *
 */
static inline void   parser_set_filename( parser *p, NSString *s)
{
   p->fileName = s;
}


static inline void   parser_memorize( parser *p, parser_memo *memo)
{
   memo->curr       = p->curr;
   memo->lineNumber = p->lineNumber;
}


static inline NSString   *parser_get_string( parser *p)
{
   return( [parser_get_retained_string( p) autorelease]);
}


static inline unichar   parser_peek_character( parser *p)
{
   return( p->curr < p->sentinel ? *p->curr : 0);
}


static inline void  parser_skip_peeked_character( parser *p, unichar c)
{
   assert( p->curr < p->sentinel);
   assert( *p->curr == c);
   p->curr++;
}


