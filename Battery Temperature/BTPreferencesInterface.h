//
//  BTPreferencesInterface.h
//  Battery Temperature
//
//  Created by Colin Campbell on 8/24/15.
//
//

#import <Foundation/Foundation.h>

#define PREFERENCES_FILE_NAME "com.cnc.Battery-Temperature"
#define PREFERENCES_NOTIFICATION_NAME "com.cnc.Battery-Temperature-preferencesChanged"
#define RESET_ALERTS_NOTIFICATION_NAME "com.cnc.Battery-Temperature.resetAlerts"

typedef enum {
    RuleShow,
    RuleHide,
    RuleAlertShow,
    RuleAlertHide
} VisibilityRule;

@interface BTPreferencesInterface : NSObject
@property (nonatomic, assign) BOOL enabled;
@property (nonatomic, assign) BOOL showPercent;
@property (nonatomic, assign) BOOL showAbbreviation;
@property (nonatomic, assign) BOOL showDecimal;
@property (nonatomic, assign) BOOL tempAlerts;
@property (nonatomic, assign) BOOL statusBarAlerts;
@property (nonatomic, assign) BOOL alertVibrate;
@property (nonatomic, assign) int unit;
@property (nonatomic, assign) VisibilityRule rule;

- (void)checkDefaultSettings;
- (void)loadSettings;
- (BOOL)isTemperatureVisible:(BOOL)shouldShowAlert;

- (void)toggleEnabled;
- (void)changeUnit;
- (void)toggleAbbreviation;
- (void)toggleDecimal;

@end
