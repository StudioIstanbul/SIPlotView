//
//  SIPlotView.m
//  SIPlotViewExample
//
//  Created by Andreas Zöllner on 27.03.15.
//  Copyright (c) 2015 Studio Istanbul Medya Hiz. Tic. Ltd. Sti. All rights reserved.
//

#import "SIPlotView.h"
#import "NSString+timeInterval.h"

@implementation SIPlotViewPoint
@synthesize time, value;

+(SIPlotViewPoint*)plotViewPointWithValue:(double)value atTime:(NSTimeInterval)time {
    SIPlotViewPoint* point = [[SIPlotViewPoint alloc] init];
    point.value = value;
    point.time = time;
    return point;
}

@end

@interface SIPlotViewChannel () {
    NSMutableArray* points;
}

@end

@implementation SIPlotViewChannel
@synthesize unit, active, points=_points;

-(id)init {
    self = [super init];
    if (self) {
        points = [NSMutableArray array];
        active = YES;
    }
    return self;
}

-(void)addPoint:(SIPlotViewPoint *)point {
    point.channel = self;
    [points addObject:point];
    [self.view setNeedsDisplay:YES];
}

-(NSTimeInterval)minTime {
    double minTime = DBL_MAX;
    if (active) {
        for (SIPlotViewPoint* point in self.points) {
            if (point.time < minTime) minTime = point.time;
        }
    }
    return minTime;
}

-(NSTimeInterval)maxTime {
    double maxTime = DBL_MIN;
    if (active) {
        for (SIPlotViewPoint* point in self.points) {
            if (point.time > maxTime) maxTime = point.time;
        }
    }
    return maxTime;
}

-(double)minVal {
    double minVal = DBL_MAX;
    if (active) {
        for (SIPlotViewPoint* point in self.points) {
            if (point.value < minVal) minVal = point.value;
        }
    }
    return minVal;
}

-(double)maxVal {
    double maxVal = DBL_MIN;
    if (active) {
        for (SIPlotViewPoint* point in self.points) {
            if (point.value > maxVal) maxVal = point.value;
        }
    }
    return maxVal;
}

-(NSArray*)points {
    return [points sortedArrayUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"time" ascending:YES]]];
}

@end

@implementation SIPlotView
@synthesize channels;

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
        channels = [NSMutableArray array];
        self.wantsLayer = YES;
    }
    
    return self;
}

- (void)drawRect:(NSRect)dirtyRect
{
    // Drawing code here.
    
    double height = self.bounds.size.height - 100;
    double startx = 10;
    double starty = 50;
    
    //// Color Declarations
    NSColor* color = [NSColor colorWithCalibratedRed: 0.667 green: 0.667 blue: 0.667 alpha: 1];
    NSColor* color2 = [NSColor colorWithCalibratedRed: 0.833 green: 0.833 blue: 0.833 alpha: 1];
    
    //// Gradient Declarations
    NSGradient* gradient = [[NSGradient alloc] initWithStartingColor: color endingColor: color2];
    
    //// Shadow Declarations
    NSShadow* shadow = [[NSShadow alloc] init];
    [shadow setShadowColor: [[NSColor blackColor] colorWithAlphaComponent: 0.55]];
    [shadow setShadowOffset: NSMakeSize(2.1, -2.1)];
    [shadow setShadowBlurRadius: 5];
    
    //// Rectangle 3 Drawing
    NSBezierPath* rectangle3Path = [NSBezierPath bezierPathWithRoundedRect:self.bounds xRadius:10 yRadius:10];
    [gradient drawInBezierPath: rectangle3Path angle: -90];
    
    double maxTime = self.maxTime;
    double minTime = self.minTime;
    
    int numHorizSpacers = height / 50;
    
    double spacerHeight = (height/numHorizSpacers);
    
    NSSet *uniqueUnits = [NSSet setWithArray:[channels valueForKey:@"unit"]];
    
    NSMutableDictionary* minsForUnits = [NSMutableDictionary dictionaryWithCapacity:uniqueUnits.count];
    NSMutableDictionary* maxsForUnits = [NSMutableDictionary dictionaryWithCapacity:uniqueUnits.count];
    NSMutableDictionary* channelCol = [NSMutableDictionary dictionaryWithCapacity:uniqueUnits.count];
    
    for (NSString* unit in uniqueUnits) {
        // plot unit labels
        double unitMax = DBL_MIN;
        double unitMin = DBL_MAX;
        for (SIPlotViewChannel* channel in self.channels) {
            if (channel.active && [channel.unit isEqualToString:unit]) {
                if (channel.maxVal > unitMax) unitMax = channel.maxVal;
                if (channel.minVal < unitMin) unitMin = channel.minVal;
                [channelCol setValue:channel.lineColor forKey:unit];
            }
        }
        
        if (unitMax != DBL_MIN && unitMin != DBL_MAX) {
            int maxFracDigits = 2;
            int minFracDigits = 2;
            if (unitMax - unitMin <= 2) maxFracDigits = 4;
            
            double intpart;
            double fractpart = modf(unitMax, &intpart);
            
            if (fractpart == 0) maxFracDigits = 0;
            else if (fractpart <= 10) maxFracDigits = 1;
            else if (fractpart <= 100) maxFracDigits = 2;
            else if (fractpart <= 1000) maxFracDigits = 3;
            
            fractpart = modf(unitMin, &intpart);
            
            if (fractpart == 0) minFracDigits = 0;
            else if (fractpart <= 10) minFracDigits = 1;
            else if (fractpart <= 100) minFracDigits = 2;
            else if (fractpart <= 1000) minFracDigits = 3;
            
            if (minFracDigits > maxFracDigits) maxFracDigits = minFracDigits;
            
            NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
            [formatter setMaximumFractionDigits:maxFracDigits];
            [formatter setMinimumFractionDigits:maxFracDigits];
            [formatter setMinimumIntegerDigits:1];
            [formatter setRoundingMode: NSNumberFormatterRoundUp];
            
            [maxsForUnits setValue:[formatter numberFromString:[formatter stringFromNumber:[NSNumber numberWithDouble:unitMax]]] forKey:unit];
            
            [formatter setRoundingMode:NSNumberFormatterRoundDown];
            [minsForUnits setValue:[formatter numberFromString:[formatter stringFromNumber:[NSNumber numberWithDouble:unitMin]]] forKey:unit];
            //NSLog(@"max frac digits %i (%f)",maxFracDigits, fractpart);
            NSMutableParagraphStyle* textStyle = [[NSMutableParagraphStyle defaultParagraphStyle] mutableCopy];
            [textStyle setAlignment: NSRightTextAlignment];
            
            NSColor* col = [NSColor blackColor];
            NSShadow* sh = nil;
            if (channelCol.allKeys.count > 1) {
                //sh = shadow;
                col = [channelCol valueForKey:unit];
            }
            
            NSDictionary* textFontAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                                [NSFont fontWithName: @"Helvetica" size: 10], NSFontAttributeName,
                                                col, NSForegroundColorAttributeName,
                                                textStyle, NSParagraphStyleAttributeName,
                                                sh, NSShadowAttributeName, nil];
            NSString* textContent = [NSString stringWithFormat:@"%@ %@",[formatter stringFromNumber:[NSNumber numberWithDouble:unitMax]], unit];

            NSSize textSize = [textContent sizeWithAttributes:textFontAttributes];
            for (int i=0; i<=numHorizSpacers; i++) {
                double val = i * (([[maxsForUnits valueForKey:unit] doubleValue] - [[minsForUnits valueForKey:unit] doubleValue]) / numHorizSpacers);
                //// Abstracted Attributes
                NSString* textContent = [NSString stringWithFormat:@"%@ %@",[formatter stringFromNumber:[NSNumber numberWithDouble:val]], unit];
                
                NSRect textRect = NSMakeRect(startx, starty + (height*i/numHorizSpacers) - (textSize.height/2), textSize.width, textSize.height);
                
                //// Text Drawing
                [textContent drawInRect: NSOffsetRect(textRect, 0, 1) withAttributes: textFontAttributes];
            }
            startx += textSize.width + 5;

        }
        
    }
    
    double width = self.bounds.size.width - startx - 20;

    
    for (int i = 0; i <= numHorizSpacers; i++) {
        NSBezierPath* spacerLine = [NSBezierPath bezierPath];
        [spacerLine moveToPoint:NSMakePoint(startx, starty + (height*i/numHorizSpacers))];
        [spacerLine lineToPoint:NSMakePoint(startx + width + 10, starty + (height*i/numHorizSpacers))];
        [color2 setStroke];
        [spacerLine setLineWidth:2];
        [spacerLine stroke];
        if (i != numHorizSpacers) {
            for (int j = 0; j < 5; j++) {
                NSBezierPath* smallSpacer = [NSBezierPath bezierPath];
                [smallSpacer moveToPoint:NSMakePoint(startx, starty + (height*i/numHorizSpacers) + (j*(spacerHeight/5)))];
                [smallSpacer lineToPoint:NSMakePoint(startx + width + 10, starty + (height*i/numHorizSpacers) + (j*(spacerHeight/5)))];
                [color2 setStroke];
                [smallSpacer setLineWidth:0.5];
                [smallSpacer stroke];
            }
        }
    }
    
    int numSpacers = width / 50;
    double spacerWidth = width/numSpacers;
    double spaceTime = (maxTime - minTime) / numSpacers;
    
    for (int i = 0; i <= numSpacers; i++) {
        NSBezierPath* spacerLine = [NSBezierPath bezierPath];
        [spacerLine moveToPoint:NSMakePoint(startx + (width*i/numSpacers), starty-10)];
        [spacerLine lineToPoint:NSMakePoint(startx + (width*i/numSpacers), starty + height)];
        [color2 setStroke];
        [spacerLine setLineWidth:2];
        [spacerLine stroke];
        if (i != numSpacers) {
            for (int j = 0; j < 5; j++) {
                NSBezierPath* smallSpacer = [NSBezierPath bezierPath];
                [smallSpacer moveToPoint:NSMakePoint(startx + (width*i/numSpacers) + (j * (spacerWidth/5)), starty-10)];
                [smallSpacer lineToPoint:NSMakePoint(startx + (width*i/numSpacers) + (j * (spacerWidth/5)), starty + height)];
                [color2 setStroke];
                [smallSpacer setLineWidth:0.5];
                [smallSpacer stroke];
            }
        }
        
        //// Abstracted Attributes
        NSString* textContent = [NSString stringFromTimeInterval:spaceTime*i];
        
        
        //// Text Drawing
        NSRect textRect = NSMakeRect(startx + (width*i/numSpacers), starty -70, 0, 0);
        textRect = NSInsetRect(textRect, -50, -50);
        NSMutableParagraphStyle* textStyle = [[NSMutableParagraphStyle defaultParagraphStyle] mutableCopy];
        [textStyle setAlignment: NSCenterTextAlignment];
        
        NSDictionary* textFontAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                            [NSFont fontWithName: @"Helvetica" size: 10], NSFontAttributeName,
                                            [NSColor blackColor], NSForegroundColorAttributeName,
                                            textStyle, NSParagraphStyleAttributeName, nil];
        
        [textContent drawInRect: NSOffsetRect(textRect, 0, 1) withAttributes: textFontAttributes];
    }
    
    NSBezierPath* timeline = [NSBezierPath bezierPath];
    [timeline moveToPoint:NSMakePoint(startx, starty - 11)];
    [timeline lineToPoint:NSMakePoint(startx + width + 10, starty - 11)];
    [[NSColor blackColor] setStroke];
    [timeline stroke];
    
    NSBezierPath* valueLine = [NSBezierPath bezierPath];
    [valueLine moveToPoint:NSMakePoint(startx, starty - 11)];
    [valueLine lineToPoint:NSMakePoint(startx, starty + height + 10)];
    [[NSColor blackColor] setStroke];
    [valueLine stroke];
    

    
    for (SIPlotViewChannel* channel in self.channels) {
        if (channel.active) {
            double maxVal = [[maxsForUnits valueForKey:channel.unit] doubleValue];
            double minVal = [[minsForUnits valueForKey:channel.unit] doubleValue];
            NSBezierPath* channelPath = [NSBezierPath bezierPath];
            int i = 0;
            for (SIPlotViewPoint* point in channel.points) {
                double y = starty + ((point.value - minVal) / (maxVal - minVal)) * height;
                double x = startx + ((point.time - minTime) / (maxTime - minTime)) * width;
                NSBezierPath* pointRect = [NSBezierPath bezierPathWithRect:NSMakeRect(x - 3, y -3, 6, 6)];
                [NSGraphicsContext saveGraphicsState];
                [shadow set];
                if (channel.lineColor) [channel.lineColor setFill]; else [[NSColor blackColor] setFill];
                [pointRect fill];
                [NSGraphicsContext restoreGraphicsState];
                if (i == 0) [channelPath moveToPoint:NSMakePoint(x, y)]; else [channelPath lineToPoint:NSMakePoint(x, y)];
                i++;
            }
            [NSGraphicsContext saveGraphicsState];
            [shadow set];
            if (channel.lineColor) [channel.lineColor setStroke]; else [[NSColor blackColor] setStroke];
            [channelPath setLineWidth: 2];
            [channelPath stroke];
            [NSGraphicsContext restoreGraphicsState];
        }
    }
}

-(void)addChannel:(SIPlotViewChannel *)channel {
    channel.view = self;
    [channels addObject:channel];
    [self setNeedsDisplay:YES];
}

-(NSTimeInterval)minTime {
    double minTime = DBL_MAX;
    for (SIPlotViewChannel* channel in self.channels) {
        if (channel.minTime < minTime) minTime = channel.minTime;
    }
    return minTime;
}

-(NSTimeInterval)maxTime {
    double maxTime = DBL_MIN;
    for (SIPlotViewChannel* channel in self.channels) {
        if (channel.maxTime > maxTime) maxTime = channel.maxTime;
    }
    return maxTime;
}

@end
