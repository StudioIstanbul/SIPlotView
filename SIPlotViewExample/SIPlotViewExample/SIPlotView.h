//
//  SIPlotView.h
//  SIPlotViewExample
//
//  Created by Andreas Zöllner on 27.03.15.
//  Copyright (c) 2015 Studio Istanbul Medya Hiz. Tic. Ltd. Sti. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class SIPlotViewChannel, SIPlotView, SIPlotViewChannelView, SIPlotViewChannelLegendView;

// Describing one Point
@interface SIPlotViewPoint : NSObject
@property (assign) NSTimeInterval time;
@property (assign) double value;
@property (weak, nonatomic) SIPlotViewChannel* channel;
+(SIPlotViewPoint*)plotViewPointWithValue:(double)value atTime:(NSTimeInterval)time;
@end

// Describing one Channel
@interface SIPlotViewChannel : NSObject
@property (strong, nonatomic) NSString* title;
@property (strong, nonatomic) NSString* unit;
@property (strong, nonatomic) NSColor* lineColor;
@property (assign, nonatomic) BOOL active;
@property (strong, readonly) NSArray* points;
@property (weak, nonatomic) SIPlotView* view;
@property (weak, nonatomic) SIPlotViewChannelView* channelView;
@property (assign, readonly) NSTimeInterval minTime;
@property (assign, readonly) NSTimeInterval maxTime;
@property (assign, readonly) double minVal;
@property (assign, readonly) double maxVal;
@property (assign, nonatomic) BOOL needsRedraw;
-(void)addPoint:(SIPlotViewPoint*)point;
@end

// The main plot view
@interface SIPlotView : NSView
@property (strong, nonatomic) NSMutableArray* channels;
@property (assign, readonly) NSTimeInterval minTime;
@property (assign, readonly) NSTimeInterval maxTime;
@property (strong, nonatomic) IBOutlet SIPlotViewChannelLegendView* legendView;
-(void)addChannel:(SIPlotViewChannel*)channel;
@end
