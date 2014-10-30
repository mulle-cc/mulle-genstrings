//
//  NSString+MulleCaseInsensitiveCompare.m
//  mulle-genstrings
//
//  Created by Nat! on 17/10/14.
//  Copyright (c) 2014 Mulle kybernetiK. All rights reserved.
//

#import "NSString+MulleCaseInsensitiveCompare.h"


@implementation NSString( MulleCaseInsensitiveCompare)

- (NSComparisonResult) mulleCaseInsensitiveCompare:(NSString *) other
{
   return( [self compare:other
                 options:NSCaseInsensitiveSearch]);
}

@end
