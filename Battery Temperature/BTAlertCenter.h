//
//  BTAlertCenter.h
//  Battery Temperature
//
//  Created by Colin Campbell on 8/25/15.
//
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "BTStatusItemManager.h"

@interface BTAlertCenter : NSObject {
    BTStatusItemManager *_itemManager;
    BOOL _didShowWarmAlert;
    BOOL _didShowHotAlert;
    BOOL _didShowCoolAlert;
    BOOL _didShowColdAlert;
}

@property (nonatomic, retain) BTStatusItemManager *itemManager;
@property (nonatomic, assign) BOOL didShowWarmAlert;
@property (nonatomic, assign) BOOL didShowHotAlert;
@property (nonatomic, assign) BOOL didShowCoolAlert;
@property (nonatomic, assign) BOOL didShowColdAlert;

- (void)checkAlertsWithTemperature:(NSNumber *)rawTemperature enabled:(BOOL)enabled tempAlerts:(BOOL)tempAlerts alertVibrate:(BOOL)alertVibrate barAlertsEnabled:(BOOL)statusBarAlerts;
- (void)resetAlerts;
- (BOOL)hasAlertShown;

@end
