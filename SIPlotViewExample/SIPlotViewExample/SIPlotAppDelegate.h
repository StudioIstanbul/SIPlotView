//
//  SIPlotAppDelegate.h
//  SIPlotViewExample
//
//  Created by Andreas Zöllner on 27.03.15.
//  Copyright (c) 2015 Studio Istanbul Medya Hiz. Tic. Ltd. Sti. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SIPlotView.h"

@interface SIPlotAppDelegate : NSObject <NSApplicationDelegate>

@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet SIPlotView* plotView;

@end
