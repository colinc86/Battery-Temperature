//
//  BTStatusBarItem.m
//  Battery Temperature
//
//  Created by Colin Campbell on 8/24/15.
//
//

#import "LSStatusBarItem+VisibilityTimer.h"

@implementation LSStatusBarItem (VisibilityTimer)

static BOOL cancelledHide = NO;

- (void)show {
    self.visible = YES;
    cancelledHide = YES;
}

- (void)hide:(BOOL)forced {
    static BOOL running = NO;

    if (forced) {
        self.visible = NO;
        cancelledHide = YES;
    }
    else {
        if (!running) {
            running = YES;
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, HideTimerInterval * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                if (!cancelledHide) {
                    self.visible = NO;
                }
                
                cancelledHide = NO;
                running = NO;
            });
        }
    }
}

@end
