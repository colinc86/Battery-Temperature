//
//  BTPreferencesInterface.m
//  Battery Temperature
//
//  Created by Colin Campbell on 8/24/15.
//
//

#import "BTPreferencesInterface.h"
#import "BTStatusItemManager.h"
#import "BTStaticFunctions.h"

@interface BTPreferencesInterface()
static void preferencesChanged(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo);
static void springBoardPreferencesChanged(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo);
- (void)startListeningForNotifications;
- (void)checkDefaultSettings;
@end

@implementation BTPreferencesInterface

#pragma mark - Class methods

+ (BTPreferencesInterface *)sharedInterface {
    static BTPreferencesInterface *sharedInterface = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInterface = [[self alloc] init];
    });
    return sharedInterface;
}




#pragma mark - Public instance methods

- (id)init {
    if (self = [super init]) {
        _forcedUpdate = YES;
        _enabled = YES;
        _showPercent = NO;
        _showAbbreviation = YES;
        _showDecimal = YES;
        _tempAlerts = NO;
        _statusBarAlerts = NO;
        _unit = 0;
    }
    return self;
}




#pragma mark - Public instance methods

- (void)loadSpringBoardSettings {
    CFPreferencesAppSynchronize(CFSTR(SPRINGBOARD_FILE_NAME));
    
    CFPropertyListRef showPercentRef = CFPreferencesCopyAppValue(CFSTR(SPRINGBOARD_BATTERY_PERCENT_KEY), CFSTR(SPRINGBOARD_FILE_NAME));
    self.showPercent = showPercentRef ? [(id)CFBridgingRelease(showPercentRef) boolValue] : NO;
}

- (void)loadSettings {
    CFPreferencesAppSynchronize(CFSTR(PREFERENCES_FILE_NAME));
    
    CFPropertyListRef enabledRef = CFPreferencesCopyAppValue(CFSTR("enabled"), CFSTR(PREFERENCES_FILE_NAME));
    self.enabled = enabledRef ? [(id)CFBridgingRelease(enabledRef) boolValue] : YES;
    
    CFPropertyListRef unitRef = CFPreferencesCopyAppValue(CFSTR("unit"), CFSTR(PREFERENCES_FILE_NAME));
    self.unit = unitRef ? [(id)CFBridgingRelease(unitRef) intValue] : 0;
    
    CFPropertyListRef showAbbreviationRef = CFPreferencesCopyAppValue(CFSTR("showAbbreviation"), CFSTR(PREFERENCES_FILE_NAME));
    self.showAbbreviation = showAbbreviationRef ? [(id)CFBridgingRelease(showAbbreviationRef) boolValue] : YES;
    
    CFPropertyListRef showDecimalRef = CFPreferencesCopyAppValue(CFSTR("showDecimal"), CFSTR(PREFERENCES_FILE_NAME));
    self.showDecimal = showDecimalRef ? [(id)CFBridgingRelease(showDecimalRef) boolValue] : YES;
    
    CFPropertyListRef tempAlertsRef = CFPreferencesCopyAppValue(CFSTR("tempAlerts"), CFSTR(PREFERENCES_FILE_NAME));
    self.tempAlerts = tempAlertsRef ? [(id)CFBridgingRelease(tempAlertsRef) boolValue] : NO;
    if (!self.tempAlerts) {
        [BTStaticFunctions resetAlerts];
    }
    
    CFPropertyListRef statusBarAlertsRef = CFPreferencesCopyAppValue(CFSTR("statusBarAlerts"), CFSTR(PREFERENCES_FILE_NAME));
    self.statusBarAlerts = statusBarAlertsRef ? [(id)CFBridgingRelease(statusBarAlertsRef) boolValue] : NO;
}

- (void)toggleEnabled {
    CFPreferencesAppSynchronize(CFSTR(PREFERENCES_FILE_NAME));
    CFPropertyListRef enabledRef = CFPreferencesCopyAppValue(CFSTR("enabled"), CFSTR(PREFERENCES_FILE_NAME));
    BOOL enabled = enabledRef ? [(id)CFBridgingRelease(enabledRef) boolValue] : YES;
    enabled = !enabled;
    CFPreferencesSetAppValue(CFSTR("enabled"), (CFNumberRef)[NSNumber numberWithBool:enabled], CFSTR(PREFERENCES_FILE_NAME));
}

- (void)changeUnit {
    CFPreferencesAppSynchronize(CFSTR(PREFERENCES_FILE_NAME));
    CFPropertyListRef unitRef = CFPreferencesCopyAppValue(CFSTR("unit"), CFSTR(PREFERENCES_FILE_NAME));
    int unit = unitRef ? [(id)CFBridgingRelease(unitRef) intValue] : 0;
    unit = (unit + 1) % 3;
    CFPreferencesSetAppValue(CFSTR("unit"), (CFNumberRef)[NSNumber numberWithInt:unit], CFSTR(PREFERENCES_FILE_NAME));
}

- (void)toggleAbbreviation {
    CFPreferencesAppSynchronize(CFSTR(PREFERENCES_FILE_NAME));
    CFPropertyListRef showAbbreviationRef = CFPreferencesCopyAppValue(CFSTR("showAbbreviation"), CFSTR(PREFERENCES_FILE_NAME));
    BOOL showAbbreviation = showAbbreviationRef ? [(id)CFBridgingRelease(showAbbreviationRef) boolValue] : YES;
    showAbbreviation = !showAbbreviation;
    CFPreferencesSetAppValue(CFSTR("showAbbreviation"), (CFNumberRef)[NSNumber numberWithBool:showAbbreviation], CFSTR(PREFERENCES_FILE_NAME));
}

- (void)toggleDecimal {
    CFPreferencesAppSynchronize(CFSTR(PREFERENCES_FILE_NAME));
    CFPropertyListRef showDecimalRef = CFPreferencesCopyAppValue(CFSTR("showDecimal"), CFSTR(PREFERENCES_FILE_NAME));
    BOOL showDecimal = showDecimalRef ? [(id)CFBridgingRelease(showDecimalRef) boolValue] : YES;
    showDecimal = !showDecimal;
    CFPreferencesSetAppValue(CFSTR("showDecimal"), (CFNumberRef)[NSNumber numberWithBool:showDecimal], CFSTR(PREFERENCES_FILE_NAME));
}




#pragma mark - Private static methods

static void preferencesChanged(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    BTPreferencesInterface *interface = [BTPreferencesInterface sharedInterface];
    [interface loadSettings];
    CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR(UPDATE_STAUS_BAR_NOTIFICATION_NAME), NULL, NULL, true);
}

static void springBoardPreferencesChanged(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    BTPreferencesInterface *interface = [BTPreferencesInterface sharedInterface];
    [interface loadSpringBoardSettings];
    CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR(UPDATE_STAUS_BAR_NOTIFICATION_NAME), NULL, NULL, true);
}




#pragma mark - Private instance methods

- (void)startListeningForNotifications {
    [self checkDefaultSettings];
    [self loadSettings];
    
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, preferencesChanged, CFSTR(PREFERENCES_NOTIFICATION_NAME), NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
    CFNotificationCenterAddObserver(CFNotificationCenterGetLocalCenter(), NULL, springBoardPreferencesChanged, CFSTR(SPRINGBOARD_NOTIFICATION_NAME), NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
}

- (void)checkDefaultSettings {
    CFPropertyListRef enabledRef = CFPreferencesCopyAppValue(CFSTR("enabled"), CFSTR(PREFERENCES_FILE_NAME));
    if (!enabledRef) {
        CFPreferencesSetAppValue(CFSTR("enabled"), (CFNumberRef)[NSNumber numberWithBool:YES], CFSTR(PREFERENCES_FILE_NAME));
    }
    else {
        CFRelease(enabledRef);
    }
    
    CFPropertyListRef unitRef = CFPreferencesCopyAppValue(CFSTR("unit"), CFSTR(PREFERENCES_FILE_NAME));
    if (!unitRef) {
        CFPreferencesSetAppValue(CFSTR("unit"), (CFNumberRef)[NSNumber numberWithInt:0], CFSTR(PREFERENCES_FILE_NAME));
    }
    else {
        CFRelease(unitRef);
    }
    
    CFPropertyListRef showAbbreviationRef = CFPreferencesCopyAppValue(CFSTR("showAbbreviation"), CFSTR(PREFERENCES_FILE_NAME));
    if (!showAbbreviationRef) {
        CFPreferencesSetAppValue(CFSTR("showAbbreviation"), (CFNumberRef)[NSNumber numberWithBool:YES], CFSTR(PREFERENCES_FILE_NAME));
    }
    else {
        CFRelease(showAbbreviationRef);
    }
    
    CFPropertyListRef showDecimalRef = CFPreferencesCopyAppValue(CFSTR("showDecimal"), CFSTR(PREFERENCES_FILE_NAME));
    if (!showDecimalRef) {
        CFPreferencesSetAppValue(CFSTR("showDecimal"), (CFNumberRef)[NSNumber numberWithBool:YES], CFSTR(PREFERENCES_FILE_NAME));
    }
    else {
        CFRelease(showDecimalRef);
    }
    
    CFPropertyListRef highTempAlertsRef = CFPreferencesCopyAppValue(CFSTR("highTempAlerts"), CFSTR(PREFERENCES_FILE_NAME));
    if (!highTempAlertsRef) {
        CFPreferencesSetAppValue(CFSTR("highTempAlerts"), (CFNumberRef)[NSNumber numberWithBool:NO], CFSTR(PREFERENCES_FILE_NAME));
    }
    else {
        CFRelease(highTempAlertsRef);
    }
    
    CFPropertyListRef lowTempAlertsRef = CFPreferencesCopyAppValue(CFSTR("lowTempAlerts"), CFSTR(PREFERENCES_FILE_NAME));
    if (!lowTempAlertsRef) {
        CFPreferencesSetAppValue(CFSTR("lowTempAlerts"), (CFNumberRef)[NSNumber numberWithBool:NO], CFSTR(PREFERENCES_FILE_NAME));
    }
    else {
        CFRelease(lowTempAlertsRef);
    }
    
    CFPropertyListRef highTempIconRef = CFPreferencesCopyAppValue(CFSTR("highTempIcon"), CFSTR(PREFERENCES_FILE_NAME));
    if (!highTempIconRef) {
        CFPreferencesSetAppValue(CFSTR("highTempIcon"), (CFNumberRef)[NSNumber numberWithBool:NO], CFSTR(PREFERENCES_FILE_NAME));
    }
    else {
        CFRelease(highTempIconRef);
    }
    
    CFPropertyListRef lowTempIconRef = CFPreferencesCopyAppValue(CFSTR("lowTempIcon"), CFSTR(PREFERENCES_FILE_NAME));
    if (!lowTempIconRef) {
        CFPreferencesSetAppValue(CFSTR("lowTempIcon"), (CFNumberRef)[NSNumber numberWithBool:NO], CFSTR(PREFERENCES_FILE_NAME));
    }
    else {
        CFRelease(lowTempIconRef);
    }
    
    CFPreferencesAppSynchronize(CFSTR(PREFERENCES_FILE_NAME));
}

@end
