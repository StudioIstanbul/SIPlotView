//
//  NSString+timeInterval.m
//  Photoroute
//
//  Created by Andreas Zöllner on 10.01.15.
//  Copyright (c) 2015 Studio Istanbul Medya Hiz. Tic. Ltd. Sti. All rights reserved.
//

#import "NSString+timeInterval.h"

@implementation NSString (timeInterval)

+ (NSString *)stringFromTimeInterval:(NSTimeInterval)interval {
    NSInteger ti = (NSInteger)interval;
    NSInteger seconds = ti % 60;
    NSInteger minutes = (ti / 60) % 60;
    NSInteger hours = (ti / 3600);
    NSMutableString* myString = [NSMutableString string];
    if (hours != 0) [myString appendFormat:@"%02ld:", (long)hours];
    [myString appendFormat:@"%02ld:%02ld", (long)minutes, (long)seconds];
    return [NSString stringWithString:myString];
}

@end
