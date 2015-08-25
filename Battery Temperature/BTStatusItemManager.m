//
//  BTStatusItemManager.m
//  Battery Temperature
//
//  Created by Colin Campbell on 8/24/15.
//
//

#import <AudioToolbox/AudioServices.h>
#import "BTStatusItemManager.h"
#import "BTStaticFunctions.h"
#import "BTPreferencesInterface.h"
#import "LSStatusBarItem+VisibilityTimer.h"

@interface BTStatusItemManager()
@property (nonatomic, retain) LSStatusBarItem *hotStatusItem;
@property (nonatomic, retain) LSStatusBarItem *warmStatusItem;
@property (nonatomic, retain) LSStatusBarItem *coolStatusItem;
@property (nonatomic, retain) LSStatusBarItem *coldStatusItem;
@end

@implementation BTStatusItemManager

#pragma mark - Public instance methods

- (void)updateWithTemperature:(NSNumber *)rawTemperature enabled:(BOOL)enabled barAlertsEnabled:(BOOL)statusBarAlerts alertVibrate:(BOOL)alertVibrate {
    if (rawTemperature) {
        if (statusBarAlerts && enabled) {
            float celsius = ([rawTemperature floatValue] / 100.0f);
            
            if (celsius >= 45.0f) {
                if (!self.hotStatusItem.visible && alertVibrate) {
                    AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
                }
                
                [self.hotStatusItem show];
                [self.warmStatusItem hide:YES];
                [self.coolStatusItem hide:YES];
                [self.coldStatusItem hide:YES];
            }
            else if (celsius >= 35.0f) {
                if (!self.warmStatusItem.visible && alertVibrate) {
                    AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
                }
                
                [self.warmStatusItem show];
                [self.hotStatusItem hide:YES];
                [self.coolStatusItem hide:YES];
                [self.coldStatusItem hide:YES];
            }
            else if (celsius <= -20.0f) {
                if (!self.coldStatusItem.visible && alertVibrate) {
                    AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
                }
                
                [self.coldStatusItem show];
                [self.hotStatusItem hide:YES];
                [self.coolStatusItem hide:YES];
                [self.warmStatusItem hide:YES];
            }
            else if (celsius <= 0.0f) {
                if (!self.coolStatusItem.visible && alertVibrate) {
                    AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
                }
                
                [self.coolStatusItem show];
                [self.hotStatusItem hide:YES];
                [self.coldStatusItem hide:YES];
                [self.warmStatusItem hide:YES];
            }
            else {
                [self.coolStatusItem hide:NO];
                [self.hotStatusItem hide:NO];
                [self.coldStatusItem hide:NO];
                [self.warmStatusItem hide:NO];
            }
        }
        else {
            [self.coolStatusItem hide:YES];
            [self.hotStatusItem hide:YES];
            [self.coldStatusItem hide:YES];
            [self.warmStatusItem hide:YES];
        }
    }
    else {
        [self.coolStatusItem hide:YES];
        [self.hotStatusItem hide:YES];
        [self.coldStatusItem hide:YES];
        [self.warmStatusItem hide:YES];
    }
}




#pragma mark - Getter/setter methods

- (LSStatusBarItem *)hotStatusItem {
    if (!_hotStatusItem) {
        _hotStatusItem = [[NSClassFromString(@"LSStatusBarItem") alloc] initWithIdentifier:[[NSString stringWithUTF8String:PREFERENCES_FILE_NAME] stringByAppendingString:ICON_HOT] alignment:StatusBarAlignmentRight];
        _hotStatusItem.imageName = ICON_HOT;
        _hotStatusItem.visible = NO;
    }
    return _hotStatusItem;
}

- (LSStatusBarItem *)warmStatusItem {
    if (!_warmStatusItem) {
        _warmStatusItem = [[NSClassFromString(@"LSStatusBarItem") alloc] initWithIdentifier:[[NSString stringWithUTF8String:PREFERENCES_FILE_NAME] stringByAppendingString:ICON_WARM] alignment:StatusBarAlignmentRight];
        _warmStatusItem.imageName = ICON_WARM;
        _warmStatusItem.visible = NO;
    }
    return _warmStatusItem;
}

- (LSStatusBarItem *)coolStatusItem {
    if (!_coolStatusItem) {
        _coolStatusItem = [[NSClassFromString(@"LSStatusBarItem") alloc] initWithIdentifier:[[NSString stringWithUTF8String:PREFERENCES_FILE_NAME] stringByAppendingString:ICON_COOL] alignment:StatusBarAlignmentRight];
        _coolStatusItem.imageName = ICON_COOL;
        _coolStatusItem.visible = NO;
    }
    return _coolStatusItem;
}

- (LSStatusBarItem *)coldStatusItem {
    if (!_coldStatusItem) {
        _coldStatusItem = [[NSClassFromString(@"LSStatusBarItem") alloc] initWithIdentifier:[[NSString stringWithUTF8String:PREFERENCES_FILE_NAME] stringByAppendingString:ICON_COLD] alignment:StatusBarAlignmentRight];
        _coldStatusItem.imageName = ICON_COLD;
        _coldStatusItem.visible = NO;
    }
    return _coldStatusItem;
}

@end
