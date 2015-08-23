#import <SpringBoard/SpringBoard.h>
#import <Foundation/Foundation.h>
#import "BTActivatorListener.h"
#import "Globals.h"

#include <dlfcn.h>
#include <mach/port.h>
#include <mach/kern_return.h>



// Preferences variables
static BOOL enabled = true;
static BOOL showPercent = false;
static BOOL showAbbreviation = true;
static BOOL showDecimal = true;
static BOOL highTempAlerts = false;
static BOOL lowTempAlerts = false;
static int unit = 0;

// Local variables
static BOOL forcedUpdate = false;
static BOOL didShowH1A = false;
static BOOL didShowH2A = false;
static BOOL didShowL1A = false;
static BOOL didShowL2A = false;
static NSString *lastBatteryDetailString = nil;




// Status bar classes

@interface UIStatusBarServer : NSObject
+ (CDStruct_4ec3be00 *)getStatusBarData;
+ (void)postStatusBarData:(CDStruct_4ec3be00 *)arg1 withActions:(int)arg2;
@end

@interface SBStatusBarStateAggregator
- (BOOL)_setItem:(int)arg1 enabled:(BOOL)arg2;
@end




// Static functions

static void LoadSpringBoardSettings() {
    CFPreferencesAppSynchronize(CFSTR(SPRINGBOARD_FILE_NAME));
    
    CFPropertyListRef showPercentRef = CFPreferencesCopyAppValue(CFSTR(SPRINGBOARD_BATTERY_PERCENT_KEY), CFSTR(SPRINGBOARD_FILE_NAME));
    showPercent = showPercentRef ? [(id)CFBridgingRelease(showPercentRef) boolValue] : NO;
}


static void LoadSettings() {
    CFPreferencesAppSynchronize(CFSTR(PREFERENCES_FILE_NAME));
    
    CFPropertyListRef enabledRef = CFPreferencesCopyAppValue(CFSTR("enabled"), CFSTR(PREFERENCES_FILE_NAME));
    enabled = enabledRef ? [(id)CFBridgingRelease(enabledRef) boolValue] : YES;
    
    CFPropertyListRef unitRef = CFPreferencesCopyAppValue(CFSTR("unit"), CFSTR(PREFERENCES_FILE_NAME));
    unit = unitRef ? [(id)CFBridgingRelease(unitRef) intValue] : 0;
    
    CFPropertyListRef showAbbreviationRef = CFPreferencesCopyAppValue(CFSTR("showAbbreviation"), CFSTR(PREFERENCES_FILE_NAME));
    showAbbreviation = showAbbreviationRef ? [(id)CFBridgingRelease(showAbbreviationRef) boolValue] : YES;
    
    CFPropertyListRef showDecimalRef = CFPreferencesCopyAppValue(CFSTR("showDecimal"), CFSTR(PREFERENCES_FILE_NAME));
    showDecimal = showDecimalRef ? [(id)CFBridgingRelease(showDecimalRef) boolValue] : YES;
    
    CFPropertyListRef highTempAlertsRef = CFPreferencesCopyAppValue(CFSTR("highTempAlerts"), CFSTR(PREFERENCES_FILE_NAME));
    highTempAlerts = highTempAlertsRef ? [(id)CFBridgingRelease(highTempAlertsRef) boolValue] : NO;
    if (!highTempAlerts) {
        didShowH1A = false;
        didShowH2A = false;
    }
    
    CFPropertyListRef lowTempAlertsRef = CFPreferencesCopyAppValue(CFSTR("lowTempAlerts"), CFSTR(PREFERENCES_FILE_NAME));
    lowTempAlerts = lowTempAlertsRef ? [(id)CFBridgingRelease(lowTempAlertsRef) boolValue] : NO;
    if (!lowTempAlerts) {
        didShowL1A = false;
        didShowL2A = false;
    }
}

static void CheckDefaultSettings() {
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
    
    CFPreferencesAppSynchronize(CFSTR(PREFERENCES_FILE_NAME));
}

static void RefreshStatusBarData() {
    SBStatusBarStateAggregator *aggregator = [%c(SBStatusBarStateAggregator) sharedInstance];
    [aggregator _setItem:8 enabled:NO];
    if (showPercent || enabled) {
        [aggregator _setItem:8 enabled:YES];
    }
    
    forcedUpdate = true;
    [UIStatusBarServer postStatusBarData:[UIStatusBarServer getStatusBarData] withActions:0];
}

static void PreferencesChanged(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    LoadSettings();
    RefreshStatusBarData();
}

static void SpringBoardPreferencesChanged(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    LoadSpringBoardSettings();
    RefreshStatusBarData();
}

static NSNumber *GetBatteryTemperature() {
    NSNumber *temp = nil;
    void *IOKit = dlopen("/System/Library/Frameworks/IOKit.framework/IOKit", RTLD_NOW);
    
    if (IOKit) {
        mach_port_t *kIOMasterPortDefault = (mach_port_t *)dlsym(IOKit, "kIOMasterPortDefault");
        CFMutableDictionaryRef (*IOServiceMatching)(const char *name) = (CFMutableDictionaryRef (*)(const char *))dlsym(IOKit, "IOServiceMatching");
        mach_port_t (*IOServiceGetMatchingService)(mach_port_t masterPort, CFDictionaryRef matching) = (mach_port_t (*)(mach_port_t, CFDictionaryRef))dlsym(IOKit, "IOServiceGetMatchingService");
        CFTypeRef (*IORegistryEntryCreateCFProperty)(mach_port_t entry, CFStringRef key, CFAllocatorRef allocator, uint32_t options) = (CFTypeRef (*)(mach_port_t, CFStringRef, CFAllocatorRef, uint32_t))dlsym(IOKit, "IORegistryEntryCreateCFProperty");
        kern_return_t (*IOObjectRelease)(mach_port_t object) = (kern_return_t (*)(mach_port_t))dlsym(IOKit, "IOObjectRelease");
        
        if (kIOMasterPortDefault && IOServiceGetMatchingService && IORegistryEntryCreateCFProperty && IOObjectRelease) {
            mach_port_t powerSource = IOServiceGetMatchingService(*kIOMasterPortDefault, IOServiceMatching("IOPMPowerSource"));
            
            if (powerSource) {
                CFTypeRef temperatureRef = IORegistryEntryCreateCFProperty(powerSource, CFSTR("Temperature"), kCFAllocatorDefault, 0);
                temp = [[NSNumber alloc] initWithInt:[(__bridge NSNumber *)temperatureRef intValue]];
                CFRelease(temperatureRef);
            }
        }
    }
    
    dlclose(IOKit);
    
    return [temp autorelease];
}

static NSString *GetTemperatureString() {
    NSString *formattedString = @"N/A";
    NSNumber *rawTemperature = GetBatteryTemperature();
    
    if (rawTemperature) {
        NSString *abbreviationString = @"";
        float celsius = [rawTemperature intValue] / 100.0f;
        
        if (unit == 1) {
            if (showAbbreviation) abbreviationString = @"℉";
            
            float fahrenheit = (celsius * (9.0f / 5.0f)) + 32.0f;
            
            if (showDecimal) {
                formattedString = [NSString stringWithFormat:@"%0.1f%@", fahrenheit, abbreviationString];
            }
            else {
                formattedString = [NSString stringWithFormat:@"%0.f%@", fahrenheit, abbreviationString];
            }
        }
        else if (unit == 2) {
            if (showAbbreviation) abbreviationString = @" K";
            
            float kelvin = celsius + 273.15;
            
            if (showDecimal) {
                formattedString = [NSString stringWithFormat:@"%0.1f%@", kelvin, abbreviationString];
            }
            else {
                formattedString = [NSString stringWithFormat:@"%0.f%@", kelvin, abbreviationString];
            }
        }
        else {
            // Default to Celsius
            if (showAbbreviation) abbreviationString = @"℃";
            
            if (showDecimal) {
                formattedString = [NSString stringWithFormat:@"%0.1f%@", celsius, abbreviationString];
            }
            else {
                formattedString = [NSString stringWithFormat:@"%0.f%@", celsius, abbreviationString];
            }
        }
    }
    
    return formattedString;
}

static void CheckAndPostAlerts() {
    NSNumber *rawTemperature = GetBatteryTemperature();
    if (rawTemperature) {
        bool showAlert = false;
        float celsius = [rawTemperature intValue] / 100.0f;
        NSString *message = @"";
        
        // Check for message to display
        if (celsius >= 45.0f) {
            if (!didShowH2A && highTempAlerts) {
                didShowH2A = true;
                showAlert = true;
                message = @"Battery temperature has reached 45℃ (113℉)!";
            }
        }
        else if (celsius >= 35.0f) {
            if (!didShowH1A && highTempAlerts) {
                didShowH1A = true;
                showAlert = true;
                message = @"Battery temperature has reached 35℃ (95℉).";
            }
        }
        else if (celsius <= -20.0f) {
            if (!didShowL2A && lowTempAlerts) {
                didShowL2A = true;
                showAlert = true;
                message = @"Battery temperature has dropped to 0℃ (32℉)!";
            }
        }
        else if (celsius <= 0.0f) {
            if (!didShowL1A && lowTempAlerts) {
                didShowL2A = false;
                didShowL1A = true;
                showAlert = true;
                message = @"Battery temperature has dropped to -20℃ (-4℉)!";
            }
        }
        else if ((celsius > 0.0f) && (celsius < 35.0f)) {
            didShowL2A = false;
            didShowL1A = false;
            didShowH2A = false;
            didShowH1A = false;
        }
        
        if (showAlert) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Battery Temperature" message:message delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
            [alert show];
            [alert release];
        }
    }
}




// Hook methods

%hook UIStatusBarServer

+ (void)postStatusBarData:(CDStruct_4ec3be00 *)arg1 withActions:(int)arg2 {
    // Force the settings to load
    LoadSpringBoardSettings();
    LoadSettings();
    
    // Check for any alerts and post them if necessary
    CheckAndPostAlerts();
    
    // Get the battery detail string
    char currentString[150];
    strcpy(currentString, arg1->batteryDetailString);
    NSString *batteryDetailString = [NSString stringWithUTF8String:currentString];
    
    // If this is a system update, then cache the percent string
    if (!forcedUpdate) {
        if (lastBatteryDetailString != nil) {
            [lastBatteryDetailString release];
            lastBatteryDetailString = nil;
        }
        lastBatteryDetailString = [batteryDetailString retain];
    }
    
    if (enabled) {
        // Get the temperature string
        NSString *temperatureString = GetTemperatureString();
        
        if (showPercent) {
            // Append the battery detail string if we're showing the percent
            temperatureString = [temperatureString stringByAppendingFormat:@"  %@", lastBatteryDetailString];
        }
        
        strlcpy(arg1->batteryDetailString, [temperatureString UTF8String], sizeof(arg1->batteryDetailString));
    } else if (forcedUpdate) {
        if (showPercent) { // If we manually disabled the tweak, and showing the battery detail string is enabled, then copy in the last updated detail string.
            strlcpy(arg1->batteryDetailString, [lastBatteryDetailString UTF8String], sizeof(arg1->batteryDetailString));
        }
        else { // Othewise copy in a blank string
            NSString *blankString = @"";
            strlcpy(arg1->batteryDetailString, [blankString UTF8String], sizeof(arg1->batteryDetailString));
        }
    }
    
    forcedUpdate = false;
    
    %orig(arg1, arg2);
}

%end

%hook SBStatusBarStateAggregator

- (BOOL)_setItem:(int)arg1 enabled:(BOOL)arg2 {
    BOOL itemEnabled = arg2;
    
    if (arg1 == 8) {
        showPercent = enabled;
        
        if (enabled) {
            itemEnabled = YES;
        }
    }
    
    return %orig(arg1, itemEnabled);
}

%end

%ctor {
    if (%c(SpringBoard)) {
        CheckDefaultSettings();
        LoadSettings();
        
        CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, PreferencesChanged, CFSTR(PREFERENCES_NOTIFICATION_NAME), NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
        CFNotificationCenterAddObserver(CFNotificationCenterGetLocalCenter(), NULL, SpringBoardPreferencesChanged, CFSTR(SPRINGBOARD_NOTIFICATION_NAME), NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
        
        void *LibActivator = dlopen("/usr/lib/libactivator.dylib", RTLD_LAZY);
        Class la = objc_getClass("LAActivator");
        if (la) {
            BTActivatorListener *enabledListener = [[BTActivatorListener alloc] initWithListenerName:ACTIVATOR_LISTENER_ENABLED];
            [[la sharedInstance] registerListener:enabledListener forName:ACTIVATOR_LISTENER_ENABLED];
            [enabledListener release];
            
            BTActivatorListener *unitListener = [[BTActivatorListener alloc] initWithListenerName:ACTIVATOR_LISTENER_UNIT];
            [[la sharedInstance] registerListener:unitListener forName:ACTIVATOR_LISTENER_UNIT];
            [unitListener release];
            
            BTActivatorListener *abbreviationListener = [[BTActivatorListener alloc] initWithListenerName:ACTIVATOR_LISTENER_ABBREVIATION];
            [[la sharedInstance] registerListener:abbreviationListener forName:ACTIVATOR_LISTENER_ABBREVIATION];
            [abbreviationListener release];
            
            BTActivatorListener *decimalListener = [[BTActivatorListener alloc] initWithListenerName:ACTIVATOR_LISTENER_DECIMAL];
            [[la sharedInstance] registerListener:decimalListener forName:ACTIVATOR_LISTENER_DECIMAL];
            [decimalListener release];
        }
        dlclose(LibActivator);
    }
    
    %init;
}
