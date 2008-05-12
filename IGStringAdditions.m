//
//  IGStringAdditions.m
//  IconGrabber
//
//  Created by Mac-arena the Bored Zo on 2004-11-21.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "IGStringAdditions.h"

static NSString *pathSeparator = @"/", *substitutePathSeparator = @"-";

@implementation NSString(IGStringAdditions)

- (NSString *)stringByEscapingPathSeparators {
	NSMutableString *string = [NSMutableString stringWithString:self];
	NSRange range = { 0U, [string length] };
	[string replaceOccurrencesOfString:pathSeparator withString:substitutePathSeparator options:NSLiteralSearch range:range];
	return [NSString stringWithString:string];
}

@end
