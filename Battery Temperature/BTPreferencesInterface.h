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
@property (nonatomic, assign) BOOL statusBarAlerts;
@property (nonatomic, assign) int unit;
@property (nonatomic, assign) VisibilityRule rule;

- (void)updateSettings;
- (BOOL)isTemperatureVisible:(BOOL)shouldShowAlert;

- (void)toggleEnabled;
- (void)changeUnit;
- (void)toggleAbbreviation;
- (void)toggleDecimal;

- (void)setHasLibstatusbar:(BOOL)flag;
- (void)setHasLibactivator:(BOOL)flag;

@end
