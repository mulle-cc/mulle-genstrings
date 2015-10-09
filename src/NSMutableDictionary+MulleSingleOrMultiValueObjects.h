//
//  NSMutableDictionary+MulleSingleOrMultiValueObjects.h
//  mulle-genstrings
//
//  Created by Nat! on 12.09.14.
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

// stripped down 4 mulle-genstrings

@interface NSMutableDictionary( MulleSingleOrMultiValueObjects)

- (void) mulleAddObject:(id) obj
                 forKey:(id <NSCopying>) key;

- (void) mulleAddObject:(id) obj
       withSortSelector:(SEL) sel
                 forKey:(id <NSCopying>) key;
@end


@interface NSDictionary (MulleSingleOrMultiValueObjects)

- (NSArray *) mulleObjectsForKey:(id <NSCopying>) key;

@end
