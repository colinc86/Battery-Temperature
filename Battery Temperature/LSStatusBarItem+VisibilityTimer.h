//
//  BTStatusBarItem.h
//  Battery Temperature
//
//  Created by Colin Campbell on 8/24/15.
//
//

#import <Foundation/Foundation.h>
#import "LSStatusBarItem.h"

static const NSTimeInterval HideTimerInterval = 1.0;

@interface LSStatusBarItem (VisibilityTimer)

@property (nonatomic, retain) NSTimer *hideTimer;

- (void)show;
- (void)hide:(BOOL)forced;

@end
