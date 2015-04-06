//
//  SIPlotView.m
//  SIPlotViewExample
//
//  Created by Andreas Zöllner on 27.03.15.
//  Copyright (c) 2015 Studio Istanbul Medya Hiz. Tic. Ltd. Sti. All rights reserved.
//

#import "SIPlotView.h"
#import "NSString+timeInterval.h"
#import <CoreGraphics/CoreGraphics.h>
#import <QuartzCore/QuartzCore.h>
#import "NSBezierPath+XUIKit.h"

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

@property (strong) CAShapeLayer* channelLayer;
@property (assign) BOOL needsRedraw;

-(CAShapeLayer*)channelLayerWithRect:(NSRect)channelRect minVal:(double)unitMin maxVal:(double)unitMax minTime:(NSTimeInterval)minTime maxTime:(NSTimeInterval)maxTime;
@end

@implementation SIPlotViewChannel
@synthesize unit, active, points=_points, channelLayer, needsRedraw;

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
    [self willChangeValueForKey:@"points"];
    [points addObject:point];
    [self didChangeValueForKey:@"points"];
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

-(CAShapeLayer*)channelLayerWithRect:(NSRect)channelRect minVal:(double)minVal maxVal:(double)maxVal minTime:(NSTimeInterval)minTime maxTime:(NSTimeInterval)maxTime {
    double startx = channelRect.origin.x;
    double starty = channelRect.origin.y;
    double width = channelRect.size.width;
    double height = channelRect.size.height;
    
    //// Shadow Declarations
    NSShadow* shadow = [[NSShadow alloc] init];
    [shadow setShadowColor: [[NSColor blackColor] colorWithAlphaComponent: 0.55]];
    [shadow setShadowOffset: NSMakeSize(2.1, -2.1)];
    [shadow setShadowBlurRadius: 5];
    
    if (!channelLayer) channelLayer = [CAShapeLayer layer];
    channelLayer.frame = self.view.bounds;
    
    NSBezierPath* channelPath = [NSBezierPath bezierPath];
    CGMutablePathRef xchannelPath = CGPathCreateMutable();
    int i = 0;
    channelLayer.sublayers = nil;
    if (self.lineColor) channelLayer.strokeColor = [self NSColorToCGColor:self.lineColor];
    else channelLayer.strokeColor = [self NSColorToCGColor:[NSColor blackColor]];
    for (SIPlotViewPoint* point in self.points) {
        double y = starty + ((point.value - minVal) / (maxVal - minVal)) * height;
        double x = startx + ((point.time - minTime) / (maxTime - minTime)) * width;
        NSBezierPath* pointRect = [NSBezierPath bezierPathWithRect:NSMakeRect(x - 3, y -3, 6, 6)];
        CAShapeLayer* rectLayer = [CAShapeLayer layer];
        CGPathRef rectPath = CGPathCreateWithRect(CGRectMake(x-3, y-3, 6, 6), NULL);
        rectLayer.path = rectPath;
        rectLayer.fillColor = channelLayer.strokeColor;
        rectLayer.delegate = self.view;
        rectLayer.name = @"rect";
        [channelLayer addSublayer:rectLayer];
        //if (i == 0) [channelPath moveToPoint:NSMakePoint(x, y)]; else [channelPath lineToPoint:NSMakePoint(x, y)];
        if (i == 0) CGPathMoveToPoint(xchannelPath, NULL, x, y); else CGPathAddLineToPoint(xchannelPath, NULL, x, y);
        i++;
    }
    
    channelLayer.lineWidth = 2;
    channelLayer.fillColor = [self NSColorToCGColor:[NSColor clearColor]];
    channelLayer.shadowColor = [self NSColorToCGColor:shadow.shadowColor];
    channelLayer.shadowOffset = shadow.shadowOffset;
    channelLayer.shadowRadius = shadow.shadowBlurRadius;
    channelLayer.shadowOpacity = 1;
    [channelLayer willChangeValueForKey:@"path"];
    channelLayer.path = xchannelPath;
    [channelLayer didChangeValueForKey:@"path"];
    needsRedraw = NO;
    return channelLayer;
}

- (CGColorRef)NSColorToCGColor:(NSColor *)color
{
    NSInteger numberOfComponents = [color numberOfComponents];
    CGFloat components[numberOfComponents];
    CGColorSpaceRef colorSpace = [[color colorSpace] CGColorSpace];
    [color getComponents:(CGFloat *)&components];
    CGColorRef cgColor = CGColorCreate(colorSpace, components);
    
    return cgColor;
}

@end

@interface SIPlotView () {
    NSRect channelContent;
    NSTimeInterval minTime, maxTime;
    NSMutableDictionary* minsForUnits, *maxsForUnits, *channelCol;
    CAGradientLayer* backgroundLayer;
    CALayer* chartLayer;
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
    }
    
    return self;
}

-(void)awakeFromNib {
    [self addObserver:self forKeyPath:@"frame" options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew context:NULL];
    [self calculateSizes];
    [self setLayer:[self backGroundLayer]];
    self.wantsLayer = YES;
}

-(CALayer*)backGroundLayer {
    if (!backgroundLayer) {
        backgroundLayer = [CAGradientLayer layer];
        backgroundLayer.delegate = self;
        backgroundLayer.name = @"backGroundLayer";
        chartLayer = [CALayer layer];
        [backgroundLayer addSublayer:chartLayer];
    }
    chartLayer.sublayers = nil;
    //// Color Declarations
    NSColor* color = [NSColor colorWithCalibratedRed: 0.667 green: 0.667 blue: 0.667 alpha: 1];
    NSColor* color2 = [NSColor colorWithCalibratedRed: 0.833 green: 0.833 blue: 0.833 alpha: 1];
    backgroundLayer.colors = [NSArray arrayWithObjects:(id)[self NSColorToCGColor:color2], (id)[self NSColorToCGColor:color], nil];
    //// Rectangle 3 Drawing
    CAShapeLayer* maskLayer = [CAShapeLayer layer];
    CGPathRef rectPath = [self newPathForRoundedRect:self.bounds radius:10];
    maskLayer.path = rectPath;
    backgroundLayer.mask = maskLayer;
    int numSpacers = channelContent.size.height / 50;
    double spacerWidth = channelContent.size.width/numSpacers;
    double spaceTime = (maxTime - minTime) / numSpacers;
    
    int numHorizSpacers = channelContent.size.height / 50;
    double spacerHeight = (channelContent.size.height/numHorizSpacers);
    
    for (int i = 0; i <= numHorizSpacers; i++) {
        CAShapeLayer* lineLayer = [CAShapeLayer layer];
        CGMutablePathRef spacerLine = CGPathCreateMutable();
        CGPathMoveToPoint(spacerLine, NULL, channelContent.origin.x, channelContent.origin.y+(channelContent.size.height*i/numHorizSpacers));
        CGPathAddLineToPoint(spacerLine, NULL, channelContent.origin.x + channelContent.size.width + 10, channelContent.origin.y+(channelContent.size.height*i/numHorizSpacers));
        lineLayer.path = spacerLine;
        lineLayer.strokeColor = [self NSColorToCGColor:color2];
        lineLayer.lineWidth = 2;
        if (i != numHorizSpacers) {
            for (int j = 0; j < 5; j++) {
                CAShapeLayer* smallSpacerLayer = [CAShapeLayer layer];
                CGMutablePathRef smallSpacer = CGPathCreateMutable();
                CGPathMoveToPoint(smallSpacer, NULL, channelContent.origin.x, channelContent.origin.y+(channelContent.size.height*i/numHorizSpacers) + (j*spacerHeight/5));
                CGPathAddLineToPoint(smallSpacer, NULL, channelContent.origin.x + channelContent.size.width + 10, channelContent.origin.y+(channelContent.size.height*i/numHorizSpacers) + (j*spacerHeight/5));
                smallSpacerLayer.path = smallSpacer;
                smallSpacerLayer.strokeColor = [self NSColorToCGColor:color2];
                smallSpacerLayer.lineWidth = 0.2;
                smallSpacerLayer.delegate = self;
                [lineLayer addSublayer:smallSpacerLayer];
            }
        }
        lineLayer.delegate = self;
        [chartLayer addSublayer:lineLayer];
    }
    
    
    /*
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
    [valueLine stroke];*/
    return backgroundLayer;
}

- (CGPathRef) newPathForRoundedRect:(CGRect)rect radius:(CGFloat)radius
{
	CGMutablePathRef retPath = CGPathCreateMutable();
    
	CGRect innerRect = CGRectInset(rect, radius, radius);
    
	CGFloat inside_right = innerRect.origin.x + innerRect.size.width;
	CGFloat outside_right = rect.origin.x + rect.size.width;
	CGFloat inside_bottom = innerRect.origin.y + innerRect.size.height;
	CGFloat outside_bottom = rect.origin.y + rect.size.height;
    
	CGFloat inside_top = innerRect.origin.y;
	CGFloat outside_top = rect.origin.y;
	CGFloat outside_left = rect.origin.x;
    
	CGPathMoveToPoint(retPath, NULL, innerRect.origin.x, outside_top);
    
	CGPathAddLineToPoint(retPath, NULL, inside_right, outside_top);
	CGPathAddArcToPoint(retPath, NULL, outside_right, outside_top, outside_right, inside_top, radius);
	CGPathAddLineToPoint(retPath, NULL, outside_right, inside_bottom);
	CGPathAddArcToPoint(retPath, NULL,  outside_right, outside_bottom, inside_right, outside_bottom, radius);
    
	CGPathAddLineToPoint(retPath, NULL, innerRect.origin.x, outside_bottom);
	CGPathAddArcToPoint(retPath, NULL,  outside_left, outside_bottom, outside_left, inside_bottom, radius);
	CGPathAddLineToPoint(retPath, NULL, outside_left, inside_top);
	CGPathAddArcToPoint(retPath, NULL,  outside_left, outside_top, innerRect.origin.x, outside_top, radius);
    
	CGPathCloseSubpath(retPath);
    
	return retPath;
}

/*- (void)drawRect:(NSRect)dirtyRect
{
    // Drawing code here.
    
    
    
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
    

    
    
            for (int i=0; i<=numHorizSpacers; i++) {
                double val = i * (([[maxsForUnits valueForKey:unit] doubleValue] - [[minsForUnits valueForKey:unit] doubleValue]) / numHorizSpacers);
                //// Abstracted Attributes
                NSString* textContent = [NSString stringWithFormat:@"%@ %@",[formatter stringFromNumber:[NSNumber numberWithDouble:val]], unit];
                
                NSRect textRect = NSMakeRect(startx, starty + (height*i/numHorizSpacers) - (textSize.height/2), textSize.width, textSize.height);
                
                //// Text Drawing
                [textContent drawInRect: NSOffsetRect(textRect, 0, 1) withAttributes: textFontAttributes];
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
    
    
    

    
}*/

-(void)markAllLayersRedraw {
    for (SIPlotViewChannel* channel in self.channels) {
        channel.needsRedraw = YES;
    }
}

-(void)updateAffectedLayers {
    [self calculateSizes];
    for (SIPlotViewChannel* channel in self.channels) {
        if (channel.needsRedraw) [self updateChannel:channel];
    }
}

-(void)calculateSizes {
    double height = self.bounds.size.height - 100;
    double startx = 10;
    double starty = 50;
    
    double oldMaxTime = maxTime;
    double oldMinTime = minTime;
    
    maxTime = self.maxTime;
    minTime = self.minTime;
    
    if (oldMaxTime != maxTime || oldMinTime != minTime) {
        [self markAllLayersRedraw];
    }
    
    NSSet *uniqueUnits = [NSSet setWithArray:[channels valueForKey:@"unit"]];
    
    minsForUnits = [NSMutableDictionary dictionaryWithCapacity:uniqueUnits.count];
    maxsForUnits = [NSMutableDictionary dictionaryWithCapacity:uniqueUnits.count];
    channelCol = [NSMutableDictionary dictionaryWithCapacity:uniqueUnits.count];
    
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
            startx += textSize.width + 5;
            
        }
        
    }
    
    double width = self.bounds.size.width - startx - 20;
    
    channelContent = NSMakeRect(startx, starty, width, height);
}

-(void)updateChannel:(SIPlotViewChannel*)channel {
    if (channel.active) {
        [self calculateSizes];
        [CATransaction begin];
        [channel channelLayerWithRect:channelContent minVal:[[minsForUnits valueForKey:channel.unit] doubleValue] maxVal:[[maxsForUnits valueForKey:channel.unit] doubleValue] minTime:minTime maxTime:maxTime];
        channel.channelLayer.delegate = self;
        [CATransaction commit];
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
    } else if (object == self && [keyPath isEqualToString:@"frame"]) {
        [self calculateSizes];
        [self backGroundLayer];
        [self updateAllChannels];
    }
}

-(void)addChannel:(SIPlotViewChannel *)channel {
    if (self.layer == backgroundLayer) {
        channel.view = self;
        [channels addObject:channel];
        [channel addObserver:self forKeyPath:@"points" options:NSKeyValueObservingOptionNew context:NULL];
        [self calculateSizes];
        CALayer* channelLayer = [channel channelLayerWithRect:channelContent minVal:[[minsForUnits valueForKey:channel.unit] doubleValue] maxVal:[[maxsForUnits valueForKey:channel.unit] doubleValue] minTime:minTime maxTime:maxTime];
        channelLayer.delegate = self;
        channelLayer.name = channel.title;
        [self.layer addSublayer:channelLayer];
        [self.layer setNeedsDisplay];
        NSLog(@"adding channel with size: %f/%f", channelLayer.frame.size.width, channelLayer.frame.size.height);
    } else {
        NSLog(@"no layer!");
        [self performSelector:@selector(addChannel:) withObject:channel afterDelay:1];
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

-(void)dealloc {
    [self removeObserver:self forKeyPath:@"bounds"];
    for (SIPlotViewChannel* channel in self.channels) {
        [channel removeObserver:self forKeyPath:@"points"];
    }
}

-(id <CAAction>)actionForLayer:(CALayer *)layer forKey:(NSString *)event {
    NSLog(@"action for layer: %@", layer.name);
    if([layer.name isEqualToString:@"backGroundLayer"]) { // Check for right layer
        
        CABasicAnimation *ani = [CABasicAnimation animationWithKeyPath:event]; // Default Animation for 'event'
        ani.duration = .0; // Your custom animation duration
        return ani;
        
    } else {
        CABasicAnimation *ani = [CABasicAnimation animationWithKeyPath:event]; // Default Animation for 'event'
        ani.duration = 0.0; // Your custom animation duration
        return ani;
    }
}

- (CGColorRef)NSColorToCGColor:(NSColor *)color
{
    NSInteger numberOfComponents = [color numberOfComponents];
    CGFloat components[numberOfComponents];
    CGColorSpaceRef colorSpace = [[color colorSpace] CGColorSpace];
    [color getComponents:(CGFloat *)&components];
    CGColorRef cgColor = CGColorCreate(colorSpace, components);
    
    return cgColor;
}

@end
