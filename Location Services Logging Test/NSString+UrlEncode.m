//
//  NSString+UrlEncode.m
//  Location Services Logging Test
//
//  Created by Robert Ryan on 6/27/13.
//  Copyright (c) 2013 Robert Ryan. All rights reserved.
//

#import "NSString+UrlEncode.h"

@implementation NSString (UrlEncode)

+ (NSString *)stringByAddingPercentEscapesFor:(NSString *)string
                legalURLCharactersToBeEscaped:(NSString *)legalURLCharactersToBeEscaped
                                usingEncoding:(NSStringEncoding)encoding
{
    [string stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];

    return CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
                                                                     (CFStringRef)string,
                                                                     NULL,
                                                                     (CFStringRef)legalURLCharactersToBeEscaped,
                                                                     CFStringConvertNSStringEncodingToEncoding(encoding)
                                                                     ));
}

- (NSString *)stringByAddingPercentEscapesFor:(NSString *)legalURLCharactersToBeEscaped
                                usingEncoding:(NSStringEncoding)encoding
{
    return [NSString stringByAddingPercentEscapesFor:self
                       legalURLCharactersToBeEscaped:legalURLCharactersToBeEscaped
                                       usingEncoding:encoding];
}

- (NSString *)stringByAddingPercentEscapesForURLParameterUsingEncoding:(NSStringEncoding)encoding
{
    return [NSString stringByAddingPercentEscapesFor:self
                       legalURLCharactersToBeEscaped:@"&?+:"
                                       usingEncoding:encoding];
}

@end
