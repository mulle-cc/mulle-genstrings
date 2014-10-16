//
//  NSMutableDictionary+MulleSingleOrMultiValueObjects.m
//  Dienstag
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

#import "NSMutableDictionary+MulleSingleOrMultiValueObjects.h"


@implementation NSMutableDictionary (MulleSingleOrMultiValueObjects)

static Class  nsArrayClass;

+ (void) load
{
   nsArrayClass = [NSArray class];
}


- (void) mulleAddObject:(id) obj
                 forKey:(id <NSCopying>) key
{
   id   value;
   
   NSParameterAssert( nsArrayClass);
   
   value = [self objectForKey:key];
   if( ! value)
   {
      [self setObject:obj
               forKey:key];
      return;
   }
   
   if( ! [value isKindOfClass:nsArrayClass])
   {
      value = [NSMutableArray arrayWithObject:value];
      [self setObject:value
               forKey:key];
   }
   [value addObject:obj];
}


- (void) mulleAddObject:(id) obj
       withSortSelector:(SEL) sel
                 forKey:(id <NSCopying>) key
{
   id   value;
   
   NSParameterAssert( nsArrayClass);

   value = [self objectForKey:key];
   if( ! value)
   {
      [self setObject:obj
               forKey:key];
      return;
   }
   
   if( ! [value isKindOfClass:nsArrayClass])
   {
      value = [NSMutableArray arrayWithObject:value];
      [self setObject:value
               forKey:key];
   }
   NSParameterAssert( [value indexOfObjectIdenticalTo:obj] == NSNotFound);
   [value addObject:obj];
   [value sortUsingSelector:sel];
}

@end


@implementation NSDictionary (MulleSingleOrMultiValueObjects)

- (NSArray *) mulleObjectsForKey:(id <NSCopying>) key
{
   id   value;
   
   value = [self objectForKey:key];
   if( ! value)
      return( nil);
   if( [value isKindOfClass:nsArrayClass])
      return( value);
   return( [NSArray arrayWithObject:value]);
}

@end
