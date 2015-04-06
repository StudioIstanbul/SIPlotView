//
//  SIPlotView.m
//  SIPlotViewExample
//
//  Created by Andreas Zöllner on 27.03.15.
//  Copyright (c) 2015 Studio Istanbul Medya Hiz. Tic. Ltd. Sti. All rights reserved.
//

#import "SIPlotView.h"
#import "NSString+timeInterval.h"
#import "NSView+Fade.h"
#import "NSColor+M3Extensions.h"

@interface SIPlotViewCalcs : NSObject

@property (assign) double           height;
@property (assign) double           width;
@property (assign) double           startx;
@property (assign) double           starty;
@property (assign) int              numSpacers;
@property (assign) int              numHorizSpacers;
@property (assign) double           spacerHeight;
@property (assign) double           spacerWidth;
@property (assign) NSTimeInterval   spaceTime;
@property (assign) NSTimeInterval   maxTime;
@property (assign) NSTimeInterval   minTime;
@property (strong) NSMutableDictionary* minsForUnits;
@property (strong) NSMutableDictionary* maxsForUnits;
@property (strong) NSMutableDictionary* channelCol;
@property (strong) NSMutableDictionary* channelLabelStartx;

-(void)calcForMasterView:(SIPlotView*)masterView;

@end

@interface SIPlotView () {
    SIPlotViewChannelLegendView* _legendView;
}
@property (strong, nonatomic) SIPlotViewCalcs* plotViewCalcs;

@end

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
@synthesize unit, active, points=_points, needsRedraw;

-(id)init {
    self = [super init];
    if (self) {
        points = [NSMutableArray array];
        active = YES;
        needsRedraw = YES;
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

@interface SIPlotViewChannelView : NSView
@property (strong, nonatomic) SIPlotViewChannel* channel;

@end

@implementation SIPlotViewChannelView
@synthesize channel;

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
        self.wantsLayer = YES;
    }
    return self;
}

- (void)drawRect:(NSRect)dirtyRect {
    [channel.view.plotViewCalcs calcForMasterView:channel.view];
    if (channel.active) {
        //// Shadow Declarations
        NSShadow* shadow = [[NSShadow alloc] init];
        [shadow setShadowColor: [[NSColor blackColor] colorWithAlphaComponent: 0.55]];
        [shadow setShadowOffset: NSMakeSize(2.1, -2.1)];
        [shadow setShadowBlurRadius: 5];
        
        double maxVal = [[self.channel.view.plotViewCalcs.maxsForUnits valueForKey:channel.unit] doubleValue];
        double minVal = [[self.channel.view.plotViewCalcs.minsForUnits valueForKey:channel.unit] doubleValue];
        NSBezierPath* channelPath = [NSBezierPath bezierPath];
        int i = 0;
        for (SIPlotViewPoint* point in channel.points) {
            double y = self.channel.view.plotViewCalcs.starty + ((point.value - minVal) / (maxVal - minVal)) * self.channel.view.plotViewCalcs.height;
            double x = self.channel.view.plotViewCalcs.startx + ((point.time - self.channel.view.plotViewCalcs.minTime) / (self.channel.view.plotViewCalcs.maxTime - self.channel.view.plotViewCalcs.minTime)) * self.channel.view.plotViewCalcs.width;
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

@end

@implementation SIPlotViewCalcs
@synthesize height, startx, width, numHorizSpacers, spacerHeight, starty, maxTime, minTime, minsForUnits, maxsForUnits, channelCol, numSpacers, spacerWidth, spaceTime, channelLabelStartx;

-(void)calcForMasterView:(SIPlotView *)masterView {
    height = masterView.bounds.size.height - 100;
    startx = 10;
    starty = 50;
    
    double oldMaxTime = maxTime;
    double oldMinTime = minTime;
    
    maxTime = masterView.maxTime;
    minTime = masterView.minTime;
    
    if (oldMaxTime != maxTime || oldMinTime != minTime) {
        //[self markAllLayersRedraw];
        // tell delegate to update all layers!
    }
    
    numHorizSpacers = height / 50;
    spacerHeight = (height/numHorizSpacers);
    
    NSSet *uniqueUnits = [NSSet setWithArray:[masterView.channels valueForKey:@"unit"]];
    
    minsForUnits = [NSMutableDictionary dictionaryWithCapacity:uniqueUnits.count];
    maxsForUnits = [NSMutableDictionary dictionaryWithCapacity:uniqueUnits.count];
    channelCol = [NSMutableDictionary dictionaryWithCapacity:uniqueUnits.count];
    channelLabelStartx = [NSMutableDictionary dictionaryWithCapacity:uniqueUnits.count];
    
    for (NSString* unit in uniqueUnits) {
        // plot unit labels
        double unitMax = DBL_MIN;
        double unitMin = DBL_MAX;
        for (SIPlotViewChannel* channel in masterView.channels) {
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
            [channelLabelStartx setValue:@(startx) forKey:unit];
            startx += textSize.width + 5;
        }
        
    }
    width = masterView.bounds.size.width - startx - 20;
    numSpacers = width / 50;
    spacerWidth = width/numSpacers;
    spaceTime = (maxTime - minTime) / numSpacers;
}

@end

@interface SIPlotViewChannelLegendBackgroundView : NSView
@property (strong) NSColor* bgColor;
@end

@implementation SIPlotViewChannelLegendBackgroundView

-(void)drawRect:(NSRect)dirtyRect {
    //// General Declarations
    CGContextRef context = [[NSGraphicsContext currentContext] graphicsPort];
    
    //// Color Declarations
    NSColor* color = self.bgColor;
    NSColor* color2 = [self.bgColor m3_colourByAdjustingBrightness:-0.35];
    NSColor* color3 = [NSColor colorWithCalibratedRed: 1 green: 1 blue: 1 alpha: 1];
    
    //// Gradient Declarations
    NSGradient* gradient = [[NSGradient alloc] initWithStartingColor: color endingColor: color2];
    
    //// Shadow Declarations
    NSShadow* shadow = [[NSShadow alloc] init];
    [shadow setShadowColor: [[NSColor blackColor] colorWithAlphaComponent: 0.58]];
    [shadow setShadowOffset: NSMakeSize(2.1, -2.1)];
    [shadow setShadowBlurRadius: 4];
    NSShadow* shadow2 = [[NSShadow alloc] init];
    [shadow2 setShadowColor: color3];
    [shadow2 setShadowOffset: NSMakeSize(2.1, -2.1)];
    [shadow2 setShadowBlurRadius: 2.5];
    
    //// Frames
    NSRect frame = self.bounds;
    
    
    //// Rounded Rectangle Drawing
    NSBezierPath* roundedRectanglePath = [NSBezierPath bezierPathWithRoundedRect: NSMakeRect(NSMinX(frame), NSMinY(frame) + 5, NSWidth(frame) - 5, NSHeight(frame) - 5) xRadius: 4 yRadius: 4];
    [NSGraphicsContext saveGraphicsState];
    [shadow set];
    CGContextBeginTransparencyLayer(context, NULL);
    [gradient drawInBezierPath: roundedRectanglePath angle: -90];
    CGContextEndTransparencyLayer(context);
    
    ////// Rounded Rectangle Inner Shadow
    NSRect roundedRectangleBorderRect = NSInsetRect([roundedRectanglePath bounds], -shadow2.shadowBlurRadius, -shadow2.shadowBlurRadius);
    roundedRectangleBorderRect = NSOffsetRect(roundedRectangleBorderRect, -shadow2.shadowOffset.width, -shadow2.shadowOffset.height);
    roundedRectangleBorderRect = NSInsetRect(NSUnionRect(roundedRectangleBorderRect, [roundedRectanglePath bounds]), -1, -1);
    
    NSBezierPath* roundedRectangleNegativePath = [NSBezierPath bezierPathWithRect: roundedRectangleBorderRect];
    [roundedRectangleNegativePath appendBezierPath: roundedRectanglePath];
    [roundedRectangleNegativePath setWindingRule: NSEvenOddWindingRule];
    
    [NSGraphicsContext saveGraphicsState];
    {
        NSShadow* shadow2WithOffset = [shadow2 copy];
        CGFloat xOffset = shadow2WithOffset.shadowOffset.width + round(roundedRectangleBorderRect.size.width);
        CGFloat yOffset = shadow2WithOffset.shadowOffset.height;
        shadow2WithOffset.shadowOffset = NSMakeSize(xOffset + copysign(0.1, xOffset), yOffset + copysign(0.1, yOffset));
        [shadow2WithOffset set];
        [[NSColor grayColor] setFill];
        [roundedRectanglePath addClip];
        NSAffineTransform* transform = [NSAffineTransform transform];
        [transform translateXBy: -round(roundedRectangleBorderRect.size.width) yBy: 0];
        [[transform transformBezierPath: roundedRectangleNegativePath] fill];
    }
    [NSGraphicsContext restoreGraphicsState];
    [NSGraphicsContext restoreGraphicsState];

}

/*-(BOOL)wantsDefaultClipping {
    return NO;
}*/

@end

@interface SIPlotViewChannelLegendView : NSView
@property (weak) SIPlotView* plotView;

-(void)updateChannelLegend;

@end

@implementation SIPlotViewChannelLegendView
@synthesize plotView;

-(void)awakeFromNib {
    [self addObserver:self forKeyPath:@"frame" options:0 context:NULL];
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"frame"]) [self updateChannelLegend];
}

-(void)dealloc {
    [self removeObserver:self forKeyPath:@"frame"];
}

-(void)updateChannelLegend {
    [[NSArray arrayWithArray: [self subviews]] makeObjectsPerformSelector:
     @selector(removeFromSuperviewWithoutNeedingDisplay)];
    double y = 10;
    int i;
    NSView* lastBut = nil;
    NSView* lastLineBut = nil;
    double lineWitdh = 10;
    //NSView* legendView = [[NSView alloc] initWithFrame:self.frame];
    //[legendView setTranslatesAutoresizingMaskIntoConstraints:NO];
    for (SIPlotViewChannel* channel in plotView.channels) {
        NSButton* button = [[NSButton alloc] init];
        [button setButtonType:NSSwitchButton];
        button.title = channel.title;
        //button.state = channel.active ? NSOnState : NSOffState;
        [button bind:@"value" toObject:channel withKeyPath:@"active" options:nil];
        button.action = @selector(switchActive:);
        button.tag = i;
        [button sizeToFit];
        SIPlotViewChannelLegendBackgroundView* buttonBG = [[SIPlotViewChannelLegendBackgroundView alloc] initWithFrame:self.bounds];
        [buttonBG addSubview:button];
        buttonBG.bgColor = channel.lineColor;
        [button setFrame:NSMakeRect(5, 5, button.frame.size.width, button.frame.size.height)];
        [self addSubview:buttonBG];
        [buttonBG setTranslatesAutoresizingMaskIntoConstraints:NO];
        [buttonBG setFrameSize:NSInsetRect(button.frame, -10, -10).size];
        if (lineWitdh + buttonBG.frame.size.width > self.frame.size.width - 10) {
            lastLineBut = lastBut;
            lastBut = nil;
            lineWitdh = 10 + buttonBG.frame.size.width;
        } else {
            lineWitdh += buttonBG.frame.size.width + 10;
        }
        if (lastBut) {
            [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"[lastBut]-10-[newBut(==%f)]", button.frame.size.width + 10] options:0 metrics:nil views:@{@"lastBut": lastBut, @"newBut": buttonBG}]];
        } else {
            [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"|-10-[newBut(==%f)]", button.frame.size.width + 10] options:0 metrics:nil views:@{@"newBut": buttonBG}]];
        }
        if (lastLineBut) {
            [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"V:[lastBut]-10-[newBut(>=%f)]", button.frame.size.height+5] options:0 metrics:nil views:@{@"lastBut": lastLineBut, @"newBut": buttonBG}]];
        } else {
            [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"V:|-(==10)-[newBut(>=%f)]", button.frame.size.height+5] options:0 metrics:nil views:@{@"newBut": buttonBG}]];
        }
        lastBut = buttonBG;
        y += 10;
        i++;
    }
    [self setNeedsDisplay:YES];
}

-(IBAction)switchActive:(id)sender {
    NSLog(@"switch active for channel %@", [sender title]);
    NSInteger num = ((NSButton*)sender).tag;
    ((SIPlotViewChannel*)[plotView.channels objectAtIndex:num]).active = !((SIPlotViewChannel*)[plotView.channels objectAtIndex:num]).active;
}

-(void)drawRect:(NSRect)dirtyRect {
    //// Color Declarations
    NSColor* color = [NSColor colorWithCalibratedRed: 0.667 green: 0.667 blue: 0.667 alpha: 1];
    NSColor* color2 = [NSColor colorWithCalibratedRed: 0.833 green: 0.833 blue: 0.833 alpha: 1];
    
    //// Gradient Declarations
    NSGradient* gradient = [[NSGradient alloc] initWithStartingColor: color endingColor: color2];
    NSBezierPath* rectangle3Path = [NSBezierPath bezierPathWithRoundedRect:self.bounds xRadius:10 yRadius:10];
    [gradient drawInBezierPath: rectangle3Path angle: -90];
}

@end

@implementation SIPlotView
@synthesize channels, plotViewCalcs, legendView = _legendView;

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
        channels = [NSMutableArray array];
        plotViewCalcs = [[SIPlotViewCalcs alloc] init];
    }
    
    return self;
}

-(void)awakeFromNib {
    self.wantsLayer = YES;
}

- (void)drawRect:(NSRect)dirtyRect
{
    // Drawing code here.
    [self.plotViewCalcs calcForMasterView:self];
    
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
    
    NSSet *uniqueUnits = [NSSet setWithArray:[channels valueForKey:@"unit"]];
    
    for (NSString* unit in uniqueUnits) {
        // plot unit labels
        double unitMax = [[[self.plotViewCalcs maxsForUnits] valueForKey:unit] doubleValue];
        double unitMin = [[[self.plotViewCalcs minsForUnits] valueForKey:unit] doubleValue];
        
        if ([[self.plotViewCalcs maxsForUnits] valueForKey:unit] && [[self.plotViewCalcs minsForUnits] valueForKey:unit]) {
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
            NSMutableParagraphStyle* textStyle = [[NSMutableParagraphStyle defaultParagraphStyle] mutableCopy];
            [textStyle setAlignment: NSRightTextAlignment];
            
            NSColor* col = [NSColor blackColor];
            NSShadow* sh = nil;
            if (self.plotViewCalcs.channelCol.allKeys.count > 1) {
                //sh = shadow;
                col = [self.plotViewCalcs.channelCol valueForKey:unit];
            }
            
            NSDictionary* textFontAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                                [NSFont fontWithName: @"Helvetica" size: 10], NSFontAttributeName,
                                                col, NSForegroundColorAttributeName,
                                                textStyle, NSParagraphStyleAttributeName,
                                                sh, NSShadowAttributeName, nil];
            NSString* textContent = [NSString stringWithFormat:@"%@ %@",[formatter stringFromNumber:[NSNumber numberWithDouble:unitMax]], unit];

            NSSize textSize = [textContent sizeWithAttributes:textFontAttributes];
            for (int i=0; i<=self.plotViewCalcs.numHorizSpacers; i++) {
                double val = i * (([[self.plotViewCalcs.maxsForUnits valueForKey:unit] doubleValue] - [[self.plotViewCalcs.minsForUnits valueForKey:unit] doubleValue]) / self.plotViewCalcs.numHorizSpacers);
                //// Abstracted Attributes
                NSString* textContent = [NSString stringWithFormat:@"%@ %@",[formatter stringFromNumber:[NSNumber numberWithDouble:val]], unit];
                
                NSRect textRect = NSMakeRect([[self.plotViewCalcs.channelLabelStartx valueForKey:unit] doubleValue], self.plotViewCalcs.starty + (self.plotViewCalcs.height*i/self.plotViewCalcs.numHorizSpacers) - (textSize.height/2), textSize.width, textSize.height);
                
                //// Text Drawing
                [textContent drawInRect: NSOffsetRect(textRect, 0, 1) withAttributes: textFontAttributes];
            }
        }
    }
    
    for (int i = 0; i <= self.plotViewCalcs.numHorizSpacers; i++) {
        NSBezierPath* spacerLine = [NSBezierPath bezierPath];
        [spacerLine moveToPoint:NSMakePoint(self.plotViewCalcs.startx, self.plotViewCalcs.starty + (self.plotViewCalcs.height*i/self.plotViewCalcs.numHorizSpacers))];
        [spacerLine lineToPoint:NSMakePoint(self.plotViewCalcs.startx + self.plotViewCalcs.width + 10, self.plotViewCalcs.starty + (self.plotViewCalcs.height*i/self.plotViewCalcs.numHorizSpacers))];
        [color2 setStroke];
        [spacerLine setLineWidth:2];
        [spacerLine stroke];
        if (i != self.plotViewCalcs.numHorizSpacers) {
            for (int j = 0; j < 5; j++) {
                NSBezierPath* smallSpacer = [NSBezierPath bezierPath];
                [smallSpacer moveToPoint:NSMakePoint(self.plotViewCalcs.startx, self.plotViewCalcs.starty + (self.plotViewCalcs.height*i/self.plotViewCalcs.numHorizSpacers) + (j*(self.plotViewCalcs.spacerHeight/5)))];
                [smallSpacer lineToPoint:NSMakePoint(self.plotViewCalcs.startx + self.plotViewCalcs.width + 10, self.plotViewCalcs.starty + (self.plotViewCalcs.height*i/self.plotViewCalcs.numHorizSpacers) + (j*(self.plotViewCalcs.spacerHeight/5)))];
                [color2 setStroke];
                [smallSpacer setLineWidth:0.5];
                [smallSpacer stroke];
            }
        }
    }
    
    
    for (int i = 0; i <= self.plotViewCalcs.numSpacers; i++) {
        NSBezierPath* spacerLine = [NSBezierPath bezierPath];
        [spacerLine moveToPoint:NSMakePoint(self.plotViewCalcs.startx + (self.plotViewCalcs.width*i/self.plotViewCalcs.numSpacers), self.plotViewCalcs.starty-10)];
        [spacerLine lineToPoint:NSMakePoint(self.plotViewCalcs.startx + (self.plotViewCalcs.width*i/self.plotViewCalcs.numSpacers), self.plotViewCalcs.starty + self.plotViewCalcs.height)];
        [color2 setStroke];
        [spacerLine setLineWidth:2];
        [spacerLine stroke];
        if (i != self.plotViewCalcs.numSpacers) {
            for (int j = 0; j < 5; j++) {
                NSBezierPath* smallSpacer = [NSBezierPath bezierPath];
                [smallSpacer moveToPoint:NSMakePoint(self.plotViewCalcs.startx + (self.plotViewCalcs.width*i/self.plotViewCalcs.numSpacers) + (j * (self.plotViewCalcs.spacerWidth/5)), self.plotViewCalcs.starty-10)];
                [smallSpacer lineToPoint:NSMakePoint(self.plotViewCalcs.startx + (self.plotViewCalcs.width*i/self.plotViewCalcs.numSpacers) + (j * (self.plotViewCalcs.spacerWidth/5)), self.plotViewCalcs.starty + self.plotViewCalcs.height)];
                [color2 setStroke];
                [smallSpacer setLineWidth:0.5];
                [smallSpacer stroke];
            }
        }
        
        //// Abstracted Attributes
        NSString* textContent = [NSString stringFromTimeInterval:self.plotViewCalcs.spaceTime*i];
        
        
        //// Text Drawing
        NSRect textRect = NSMakeRect(self.plotViewCalcs.startx + (self.plotViewCalcs.width*i/self.plotViewCalcs.numSpacers), self.plotViewCalcs.starty -70, 0, 0);
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
    [timeline moveToPoint:NSMakePoint(self.plotViewCalcs.startx, self.plotViewCalcs.starty - 11)];
    [timeline lineToPoint:NSMakePoint(self.plotViewCalcs.startx + self.plotViewCalcs.width + 10, self.plotViewCalcs.starty - 11)];
    [[NSColor blackColor] setStroke];
    [timeline stroke];
    
    NSBezierPath* valueLine = [NSBezierPath bezierPath];
    [valueLine moveToPoint:NSMakePoint(self.plotViewCalcs.startx, self.plotViewCalcs.starty - 11)];
    [valueLine lineToPoint:NSMakePoint(self.plotViewCalcs.startx, self.plotViewCalcs.starty + self.plotViewCalcs.height + 10)];
    [[NSColor blackColor] setStroke];
    [valueLine stroke];
}

-(SIPlotViewCalcs*)plotViewCalcs {
    if (!plotViewCalcs) {
        plotViewCalcs = [[SIPlotViewCalcs alloc] init];
        [plotViewCalcs calcForMasterView:self];
    }
    return plotViewCalcs;
}

-(void)addChannel:(SIPlotViewChannel *)channel {
    channel.view = self;
    [channel addObserver:self forKeyPath:@"points" options:NSKeyValueObservingOptionNew context:NULL];
    [channels addObject:channel];
    SIPlotViewChannelView* channelView = [[SIPlotViewChannelView alloc] initWithFrame:self.bounds];
    channel.channelView = channelView;
    channelView.channel = channel;
    [NSAnimationContext beginGrouping];
    [[NSAnimationContext currentContext] setDuration:2.0];
    [[self animator] addSubview:channelView];
    [NSAnimationContext endGrouping];
    [channelView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
    [self setNeedsDisplay:YES];
    [(SIPlotViewChannelLegendView*) self.legendView updateChannelLegend];
}

-(void)markAllLayersRedraw {
    for (SIPlotViewChannel* channel in self.channels) {
        channel.needsRedraw = YES;
    }
}

-(void)updateAffectedLayers {
    for (SIPlotViewChannel* channel in self.channels) {
        if (channel.needsRedraw) [self updateChannel:channel];
    }
}

-(void)updateChannel:(SIPlotViewChannel*)channel {
    if (channel.active) {
        [channel.channelView setNeedsDisplay:YES];
    }
}

-(void)updateAllChannels {
    for (SIPlotViewChannel* channel in self.channels) {
        [self updateChannel:channel];
    }
    [self setNeedsDisplay:YES];
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"points"]) {
        SIPlotViewChannel* channel = object;
        channel.needsRedraw = YES;
        [self updateAffectedLayers];
    }    
    
    
    
    //else if (object == self && [keyPath isEqualToString:@"frame"]) {
      //  [self calculateSizes];
      //  [self backGroundLayer];
      //  [self updateAllChannels];
    //}
}

-(void)dealloc {
    [self removeObserver:self forKeyPath:@"bounds"];
    for (SIPlotViewChannel* channel in self.channels) {
        [channel removeObserver:self forKeyPath:@"points"];
    }
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

-(void)setNeedsDisplay:(BOOL)flag {
    for (NSView* subview in self.subviews) {
        [subview setNeedsDisplay:YES];
    }
    [super setNeedsDisplay:YES];
}

-(SIPlotViewChannelLegendView*)legendView {
    if (!_legendView) {
        _legendView = [[SIPlotViewChannelLegendView alloc] initWithFrame:self.frame];
    }
    _legendView.plotView = self;
    return _legendView;
}

@end

