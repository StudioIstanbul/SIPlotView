//
//  NSBezierPath+XUIKit.m
//  SIPlotViewExample
//
//  Created by Andreas Zöllner on 28.03.15.
//  Copyright (c) 2015 Studio Istanbul Medya Hiz. Tic. Ltd. Sti. All rights reserved.
//

#import "NSBezierPath+XUIKit.h"

@implementation NSBezierPath (XUIKit)

- (CGPathRef) CGPath
{
    CGMutablePathRef path = CGPathCreateMutable();
    NSPoint p[3];
    BOOL closed = NO;
    
    NSInteger elementCount = [self elementCount];
    for (NSInteger i = 0; i < elementCount; i++) {
        switch ([self elementAtIndex:i associatedPoints:p]) {
            case NSMoveToBezierPathElement:
                CGPathMoveToPoint(path, NULL, p[0].x, p[0].y);
                break;
                
            case NSLineToBezierPathElement:
                CGPathAddLineToPoint(path, NULL, p[0].x, p[0].y);
                closed = NO;
                break;
                
            case NSCurveToBezierPathElement:
                CGPathAddCurveToPoint(path, NULL, p[0].x, p[0].y, p[1].x, p[1].y, p[2].x, p[2].y);
                closed = NO;
                break;
                
            case NSClosePathBezierPathElement:
                CGPathCloseSubpath(path);
                closed = YES;
                break;
        }
    }
    
    if (!closed)  CGPathCloseSubpath(path);
    
    CGPathRef immutablePath = CGPathCreateCopy(path);
    CGPathRelease(path);
    
    return immutablePath;
}


@end
