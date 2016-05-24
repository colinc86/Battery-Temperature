//
//  BTPreferencesInterface.m
//  Battery Temperature
//
//  Created by Colin Campbell on 8/24/15.
//
//

#import "BTPreferencesInterface.h"

@interface BTPreferencesInterface()
- (void)checkDefaultSettings;
@end

@implementation BTPreferencesInterface

#pragma mark - Public instance methods

- (id)init {
    if (self = [super init]) {
        _enabled = YES;
        _showPercent = NO;
        _showAbbreviation = YES;
        _showDecimal = YES;
        _statusBarAlerts = NO;
        _unit = 0;
        _rule = RuleShow;
        
        [self checkDefaultSettings];
    }
    return self;
}




#pragma mark - Public instance methods

- (void)updateSettings {
    // Retrieve preferences
    NSDictionary *defaults = nil;
    BOOL releaseDefaults = true;
    
    if ([NSHomeDirectory() isEqualToString:@"/var/mobile"]) {
        CFArrayRef keyList = CFPreferencesCopyKeyList(CFSTR(PREFERENCES_FILE_NAME), kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
        if(keyList) {
            defaults = (NSDictionary *)CFPreferencesCopyMultiple(keyList, CFSTR(PREFERENCES_FILE_NAME), kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
            if(!defaults) defaults = [NSDictionary new];
            CFRelease(keyList);
        }
    } else {
        defaults = [NSDictionary dictionaryWithContentsOfFile:[NSString stringWithFormat:@"/User/Library/Preferences/%@.plist", @PREFERENCES_FILE_NAME]];
        releaseDefaults = false;
    }
    
    if (defaults != nil) {
        self.enabled = [(NSNumber *)[defaults objectForKey:@"enabled"] boolValue];
        self.unit = [(NSNumber *)[defaults objectForKey:@"unit"] intValue];
        self.showAbbreviation = [(NSNumber *)[defaults objectForKey:@"showAbbreviation"] boolValue];
        self.showDecimal = [(NSNumber *)[defaults objectForKey:@"showDecimal"] boolValue];
        self.rule = [(NSNumber *)[defaults objectForKey:@"visibilityRule"] intValue];
        self.statusBarAlerts = [(NSNumber *)[defaults objectForKey:@"statusBarAlerts"] boolValue];
        
        if (releaseDefaults) [defaults release];
    }
}

- (BOOL)isTemperatureVisible:(BOOL)shouldShowAlert {
    BOOL visible = false;
    if (self.rule == RuleShow) {
        visible = true;
    }
    else if ((self.rule == RuleAlertShow) && shouldShowAlert) {
        visible = true;
    }
    else if ((self.rule == RuleAlertHide) && !shouldShowAlert) {
        visible = true;
    }
    return visible;
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

- (void)setHasLibstatusbar:(BOOL)flag {
    NSString *description = flag ? @"Installed" : @"Not Installed";
    CFPreferencesSetAppValue(CFSTR("hasLibstatusbarDescription"), (CFStringRef)description, CFSTR(PREFERENCES_FILE_NAME));
}

- (void)setHasLibactivator:(BOOL)flag {
    NSString *description = flag ? @"Installed" : @"Not Installed";
    CFPreferencesSetAppValue(CFSTR("hasLibactivatorDescription"), (CFStringRef)description, CFSTR(PREFERENCES_FILE_NAME));
}




#pragma mark - Private instance methods

- (void)checkDefaultSettings {
    //
    // Legacy support (v1.2 -> v1.3)
    //
    CFPropertyListRef highTempAlertsRef = CFPreferencesCopyAppValue(CFSTR("highTempAlerts"), CFSTR(PREFERENCES_FILE_NAME));
    BOOL highTempAlert = highTempAlertsRef ? [(id)CFBridgingRelease(highTempAlertsRef) boolValue] : NO;
    
    CFPropertyListRef lowTempAlertsRef = CFPreferencesCopyAppValue(CFSTR("lowTempAlerts"), CFSTR(PREFERENCES_FILE_NAME));
    BOOL lowTempAlert = lowTempAlertsRef ? [(id)CFBridgingRelease(lowTempAlertsRef) boolValue] : NO;
    
    if (highTempAlert || lowTempAlert) {
        CFPreferencesSetAppValue(CFSTR("statusBarAlerts"), (CFNumberRef)[NSNumber numberWithBool:YES], CFSTR(PREFERENCES_FILE_NAME));
        CFPreferencesSetAppValue(CFSTR("highTempAlerts"), NULL, CFSTR(PREFERENCES_FILE_NAME));
        CFPreferencesSetAppValue(CFSTR("lowTempAlerts"), NULL, CFSTR(PREFERENCES_FILE_NAME));
    }
    //
    // End legacy support
    //
    
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
    
    CFPropertyListRef statusBarAlertsRef = CFPreferencesCopyAppValue(CFSTR("statusBarAlerts"), CFSTR(PREFERENCES_FILE_NAME));
    if (!statusBarAlertsRef) {
        CFPreferencesSetAppValue(CFSTR("statusBarAlerts"), (CFNumberRef)[NSNumber numberWithBool:NO], CFSTR(PREFERENCES_FILE_NAME));
    }
    else {
        CFRelease(statusBarAlertsRef);
    }
    
    CFPropertyListRef visibilityRuleRef = CFPreferencesCopyAppValue(CFSTR("visibilityRule"), CFSTR(PREFERENCES_FILE_NAME));
    if (!visibilityRuleRef) {
        CFPreferencesSetAppValue(CFSTR("visibilityRule"), (CFNumberRef)[NSNumber numberWithInt:0], CFSTR(PREFERENCES_FILE_NAME));
    }
    else {
        CFRelease(visibilityRuleRef);
    }
    
    CFPropertyListRef libstatusbarStatusRef = CFPreferencesCopyAppValue(CFSTR("hasLibstatusbarDescription"), CFSTR(PREFERENCES_FILE_NAME));
    if (!libstatusbarStatusRef) {
        CFPreferencesSetAppValue(CFSTR("hasLibstatusbarDescription"), (CFStringRef)@"Not Installed", CFSTR(PREFERENCES_FILE_NAME));
    }
    else {
        CFRelease(libstatusbarStatusRef);
    }
    
    CFPropertyListRef libactivatorStatusRef = CFPreferencesCopyAppValue(CFSTR("hasLibactivatorDescription"), CFSTR(PREFERENCES_FILE_NAME));
    if (!libactivatorStatusRef) {
        CFPreferencesSetAppValue(CFSTR("hasLibactivatorDescription"), (CFStringRef)@"Not Installed", CFSTR(PREFERENCES_FILE_NAME));
    }
    else {
        CFRelease(libactivatorStatusRef);
    }
    
    CFPreferencesAppSynchronize(CFSTR(PREFERENCES_FILE_NAME));
}

@end
