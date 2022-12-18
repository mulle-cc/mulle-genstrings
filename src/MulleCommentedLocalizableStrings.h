//
//  MulleCommentedStringsFileParser.h
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


enum MergeMode
{
   MergeReplace = 0,
   MergeAdd     = 1,   // don't overwrite old, add new ones
   MergeUpdate  = 2    // only update existing keys
};


@interface MulleCommentedLocalizableStrings : NSObject

@property( retain, nonatomic) NSMutableDictionary   *keyValues;
@property( retain, nonatomic) NSMutableDictionary   *keyComments;
@property( copy, nonatomic)   NSString              *lastComment;
@property( copy, nonatomic)   NSString              *translatorScript;
@property( assign, nonatomic) NSPropertyListFormat  plistFormat; // -1 : strings
@property( assign, nonatomic) BOOL                  verbose;

- (id) initWithContentsOfFile:(NSString *) file;
- (id) initWithParametersArray:(NSArray *) collection;

- (NSUInteger) count;
- (NSString *) localizableStringsDescription;

- (BOOL) mergeParametersArray:(NSArray *) collection
                         mode:(enum MergeMode) mode;

- (BOOL) mergeCommentedLocalizableStrings:(MulleCommentedLocalizableStrings *) other
                                     mode:(enum MergeMode) mode;

@end
