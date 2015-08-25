//
//  BTPreferencesInterface.h
//  Battery Temperature
//
//  Created by Colin Campbell on 8/24/15.
//
//

#import <Foundation/Foundation.h>

#define SPRINGBOARD_FILE_NAME "com.apple.springboard"
#define SPRINGBOARD_BATTERY_PERCENT_KEY "SBShowBatteryPercentage"
#define SPRINGBOARD_NOTIFICATION_NAME "SBPreferencesChangedNotification"

#define PREFERENCES_FILE_NAME "com.cnc.Battery-Temperature"
#define PREFERENCES_NOTIFICATION_NAME "com.cnc.Battery-Temperature-preferencesChanged"

#define UPDATE_STAUS_BAR_NOTIFICATION_NAME "com.cnc.Battery-Temperature.refreshStatusBar"
#define RESET_ALERTS_NOTIFICATION_NAME "com.cnc.Battery-Temperature.resetAlerts"

typedef enum {
    RuleShow,
    RuleHide,
    RuleAlertShow,
    RuleAlertHide
} VisibilityRule;

@interface BTPreferencesInterface : NSObject
@property (nonatomic, assign) BOOL forcedUpdate;
@property (nonatomic, assign) BOOL enabled;
@property (nonatomic, assign) BOOL showPercent;
@property (nonatomic, assign) BOOL showAbbreviation;
@property (nonatomic, assign) BOOL showDecimal;
@property (nonatomic, assign) BOOL tempAlerts;
@property (nonatomic, assign) BOOL statusBarAlerts;
@property (nonatomic, assign) BOOL alertVibrate;
@property (nonatomic, assign) int unit;
@property (nonatomic, assign) VisibilityRule rule;

+ (BTPreferencesInterface *)sharedInterface;

- (void)startListeningForNotifications;
- (void)loadSpringBoardSettings;
- (void)loadSettings;
- (BOOL)isTemperatureVisible:(BOOL)shouldShowAlert;

- (void)toggleEnabled;
- (void)changeUnit;
- (void)toggleAbbreviation;
- (void)toggleDecimal;

@end
