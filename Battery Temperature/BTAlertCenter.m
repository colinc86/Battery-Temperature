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
    }
    return self;
}

- (BTStatusItemManager *)itemManager {
    if (!_itemManager) {
        _itemManager = [[BTStatusItemManager alloc] init];
    }
    return _itemManager;
}

- (void)checkAlertsWithTemperature:(NSNumber *)rawTemperature enabled:(BOOL)enabled tempAlerts:(BOOL)tempAlerts alertVibrate:(BOOL)alertVibrate barAlertsEnabled:(BOOL)statusBarAlerts {
    if (rawTemperature) {
        //
        // Check UIAlertView type alerts
        //
        BOOL showAlert = NO;
        float celsius = [rawTemperature intValue] / 100.0f;
        NSString *message = @"";
        
        if (celsius >= HOT_CUTOFF) {
            if (!self.didShowHotAlert) {
                self.didShowHotAlert = true;
                showAlert = YES;
                message = @"Battery temperature has reached 45℃ (113℉)!";
            }
        }
        else if (celsius >= WARM_CUTOFF) {
            if (!self.didShowWarmAlert) {
                self.didShowWarmAlert = true;
                self.didShowHotAlert = false;
                showAlert = YES;
                message = @"Battery temperature has reached 35℃ (95℉).";
            }
        }
        else if (celsius <= COLD_CUTOFF) {
            if (!self.didShowColdAlert) {
                self.didShowColdAlert = true;
                showAlert = YES;
                message = @"Battery temperature has dropped to 0℃ (32℉)!";
            }
        }
        else if (celsius <= COOL_CUTOFF) {
            if (!self.didShowCoolAlert) {
                self.didShowColdAlert = false;
                self.didShowCoolAlert = true;
                showAlert = YES;
                message = @"Battery temperature has dropped to -20℃ (-4℉)!";
            }
        }
        else if ((celsius > COOL_CUTOFF) && (celsius < WARM_CUTOFF)) {
            [self resetAlerts];
        }
        
        BOOL didVibrate = NO;
        if (showAlert && enabled && tempAlerts) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Battery Temperature" message:message delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
            [alert show];
            [alert release];
            
            if (alertVibrate) {
                AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
                didVibrate = YES;
            }
        }
        
        //
        // Check UIStatusBar type alerts
        //
        [self.itemManager updateWithTemperature:rawTemperature enabled:enabled barAlertsEnabled:statusBarAlerts alertVibrate:(alertVibrate && !didVibrate)];
    }
}

- (void)resetAlerts {
    self.didShowColdAlert = false;
    self.didShowCoolAlert = false;
    self.didShowHotAlert = false;
    self.didShowWarmAlert = false;
}

- (BOOL)hasAlertShown {
    return self.didShowWarmAlert || self.didShowHotAlert || self.didShowCoolAlert || self.didShowColdAlert;
}

@end
