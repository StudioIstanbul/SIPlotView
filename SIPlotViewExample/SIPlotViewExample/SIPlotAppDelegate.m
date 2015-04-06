//
//  SIPlotAppDelegate.m
//  SIPlotViewExample
//
//  Created by Andreas Zöllner on 27.03.15.
//  Copyright (c) 2015 Studio Istanbul Medya Hiz. Tic. Ltd. Sti. All rights reserved.
//

#import "SIPlotAppDelegate.h"

@implementation SIPlotAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
    [self performSelectorInBackground:@selector(populatePlotView) withObject:nil];
}

-(void)populatePlotView {
    SIPlotViewChannel* firstChannel = [[SIPlotViewChannel alloc] init];
    firstChannel.lineColor = [NSColor redColor];
    firstChannel.unit = @"V";
    firstChannel.title = @"U1";
    [self.plotView addChannel:firstChannel];
    SIPlotViewChannel* secondChannel = [[SIPlotViewChannel alloc] init];
    secondChannel.lineColor = [NSColor blueColor];
    secondChannel.unit = @"V";
    secondChannel.title = @"U2";
    [self.plotView addChannel:secondChannel];
    SIPlotViewChannel* thirdChannel = [[SIPlotViewChannel alloc] init];
    thirdChannel.lineColor = [NSColor greenColor];
    thirdChannel.unit = @"mAh";
    thirdChannel.title = @"charge";
    thirdChannel.active = NO;
    [self.plotView addChannel:thirdChannel];
    BOOL toggle = YES;
    while (1 == 1) {
        if (toggle) {
            SIPlotViewPoint* myPoint = [SIPlotViewPoint plotViewPointWithValue:(double)arc4random_uniform(1000)/10 atTime:[NSDate timeIntervalSinceReferenceDate]];
            [firstChannel addPoint:myPoint];
        } else {
            SIPlotViewPoint* myPoint2 = [SIPlotViewPoint plotViewPointWithValue:(double)arc4random_uniform(2000)/10 atTime:[NSDate timeIntervalSinceReferenceDate]];
            [secondChannel addPoint:myPoint2];
            SIPlotViewPoint* myPoint3 = [SIPlotViewPoint plotViewPointWithValue:(double)arc4random_uniform(200)/10 atTime:[NSDate timeIntervalSinceReferenceDate]];
            [thirdChannel addPoint:myPoint3];
        }
        if (thirdChannel.points.count == 15) thirdChannel.active = YES;
        toggle = !toggle;
        [NSThread sleepForTimeInterval:1];
    }
}

@end
