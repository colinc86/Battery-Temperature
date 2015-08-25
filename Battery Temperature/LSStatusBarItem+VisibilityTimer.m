//
//  BTStatusBarItem.m
//  Battery Temperature
//
//  Created by Colin Campbell on 8/24/15.
//
//

#import "LSStatusBarItem+VisibilityTimer.h"

@implementation LSStatusBarItem (VisibilityTimer)

static NSTimer *_hideTimer = nil;

- (NSTimer *)hideTimer {
    return _hideTimer;
}

- (void)setHideTimer:(NSTimer *)hideTimer {
    _hideTimer = hideTimer;
}

- (void)show {
    self.visible = YES;
    if (self.hideTimer) {
        [self.hideTimer invalidate];
        self.hideTimer = nil;
    }
}

- (void)hide:(BOOL)forced {
    if (forced) {
        self.visible = NO;
    }
    else if (!self.hideTimer) {
        self.hideTimer = [NSTimer scheduledTimerWithTimeInterval:5.0 target:self selector:@selector(hideTimerFired:) userInfo:nil repeats:NO];
        self.hideTimer.tolerance = HideTimerInterval;
    }
}

- (void)hideTimerFired:(NSTimer *)timer {
    self.visible = NO;
    [self.hideTimer invalidate];
    self.hideTimer = nil;
}

@end