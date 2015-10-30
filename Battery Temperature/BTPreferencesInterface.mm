#line 1 "/Users/colincampbell/Documents/Xcode/JailbreakProjects/Battery-Temperature/Battery Temperature/BTPreferencesInterface.xm"








#import "BTPreferencesInterface.h"
#import "BTStatusItemManager.h"
#import "BTStaticFunctions.h"
#import "Globals.h"



@interface UIStatusBarServer : NSObject
+ (CDStruct_4ec3be00 *)getStatusBarData;
+ (void)postStatusBarData:(CDStruct_4ec3be00 *)arg1 withActions:(int)arg2;
@end

@interface SBStatusBarStateAggregator
+ (id)sharedInstance;
- (BOOL)_setItem:(int)arg1 enabled:(BOOL)arg2;
@end

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
        _highTempAlerts = NO;
        _highTempIcon = NO;
        _lowTempAlerts = NO;
        _lowTempIcon = NO;
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
    
    CFPropertyListRef highTempAlertsRef = CFPreferencesCopyAppValue(CFSTR("highTempAlerts"), CFSTR(PREFERENCES_FILE_NAME));
    self.highTempAlerts = highTempAlertsRef ? [(id)CFBridgingRelease(highTempAlertsRef) boolValue] : NO;
    if (!self.highTempAlerts) {
        
        
    }
    
    CFPropertyListRef lowTempAlertsRef = CFPreferencesCopyAppValue(CFSTR("lowTempAlerts"), CFSTR(PREFERENCES_FILE_NAME));
    self.lowTempAlerts = lowTempAlertsRef ? [(id)CFBridgingRelease(lowTempAlertsRef) boolValue] : NO;
    if (!self.lowTempAlerts) {
        
        
    }
    
    CFPropertyListRef highTempIconRef = CFPreferencesCopyAppValue(CFSTR("highTempIcon"), CFSTR(PREFERENCES_FILE_NAME));
    self.highTempIcon = highTempIconRef ? [(id)CFBridgingRelease(highTempIconRef) boolValue] : NO;
    
    CFPropertyListRef lowTempIconRef = CFPreferencesCopyAppValue(CFSTR("lowTempIcon"), CFSTR(PREFERENCES_FILE_NAME));
    self.lowTempIcon = lowTempIconRef ? [(id)CFBridgingRelease(lowTempIconRef) boolValue] : NO;
}




#pragma mark - Private static methods

static void preferencesChanged(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    BTPreferencesInterface *interface = [BTPreferencesInterface sharedInterface];
    [interface loadSettings];
    [interface refreshStatusBarData];
    
    NSLog(@"************************************************ PREFERENCES CHANGED");
}

static void springBoardPreferencesChanged(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    BTPreferencesInterface *interface = [BTPreferencesInterface sharedInterface];
    [interface loadSpringBoardSettings];
    [interface refreshStatusBarData];
    
    NSLog(@"************************************************ SPRINGBOARD SETTINGS CHANGED");
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
