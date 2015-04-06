//
//  NSView+Fade.h
//  websmslib
//
//  Created by malcom on 9/5/08.
//  Copyright 2008 http://www.malcom-mac.com. All rights reserved.
//
//  modified and adopted to ARC by Andreas Zöllner on 06/04/2015
//

#import <Cocoa/Cocoa.h>


@interface NSView(Fade)
- (IBAction)setHidden:(BOOL)hidden withFade:(BOOL)fade blocking:(BOOL)blocking;
- (IBAction)setHidden:(BOOL)hidden withFade:(BOOL)fade;
- (IBAction)setHidden:(BOOL)hidden withFade:(BOOL)fade duration:(NSTimeInterval)duration;
- (IBAction)setHidden:(BOOL)hidden withFade:(BOOL)fade blocking:(BOOL)blocking duration:(NSTimeInterval)duration;
- (void) exchangeView:(NSView *) _toHide withView:(NSView*) _toShow;
@end
