//
//  BTAlertCenter.m
//  Battery Temperature
//
//  Created by Colin Campbell on 8/25/15.
//
//

#import <AudioToolbox/AudioServices.h>
#import "BTAlertCenter.h"
#import "BTPreferencesInterface.h"

@implementation BTAlertCenter

- (id)init {
    if (self = [super init]) {
        _didShowColdAlert = NO;
        _didShowCoolAlert = NO;
        _didShowHotAlert = NO;
        _didShowWarmAlert = NO;
        _didVibrate = NO;
    }
    return self;
}

- (BTStatusItemManager *)itemManager {
    if (!_itemManager) {
        _itemManager = [[BTStatusItemManager alloc] init];
    }
    return _itemManager;
}

- (void)checkAlertsWithTemperature:(NSNumber *)rawTemperature enabled:(BOOL)enabled tempAlerts:(BOOL)tempAlerts alertVibrate:(BOOL)alertVibrate {
    if (rawTemperature) {
        BOOL showAlert = NO;
        float celsius = [rawTemperature intValue] / 100.0f;
        NSString *message = @"";
        
        if (celsius >= 45.0f) {
            if (!self.didShowHotAlert) {
                self.didShowHotAlert = true;
                showAlert = YES;
                message = @"Battery temperature has reached 45℃ (113℉)!";
            }
        }
        else if (celsius >= 35.0f) {
            if (!self.didShowWarmAlert) {
                self.didShowWarmAlert = true;
                self.didShowHotAlert = false;
                showAlert = YES;
                message = @"Battery temperature has reached 35℃ (95℉).";
            }
        }
        else if (celsius <= -20.0f) {
            if (!self.didShowColdAlert) {
                self.didShowColdAlert = true;
                showAlert = YES;
                message = @"Battery temperature has dropped to 0℃ (32℉)!";
            }
        }
        else if (celsius <= 0.0f) {
            if (!self.didShowCoolAlert) {
                self.didShowColdAlert = false;
                self.didShowCoolAlert = true;
                showAlert = YES;
                message = @"Battery temperature has dropped to -20℃ (-4℉)!";
            }
        }
        else if ((celsius > 0.0f) && (celsius < 35.0f)) {
            [self resetAlerts];
        }
        
        if (showAlert && enabled && tempAlerts) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Battery Temperature" message:message delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
            [alert show];
            [alert release];
            
            if (alertVibrate) {
                AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
                self.didVibrate = YES;
            }
        }
    }
}

- (void)resetAlerts {
    self.didShowColdAlert = false;
    self.didShowCoolAlert = false;
    self.didShowHotAlert = false;
    self.didShowWarmAlert = false;
    self.didVibrate = NO;
}

- (BOOL)hasAlertShown {
    return self.didShowWarmAlert || self.didShowHotAlert || self.didShowCoolAlert || self.didShowColdAlert;
}

@end
