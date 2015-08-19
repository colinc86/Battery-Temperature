#import <SpringBoard/SpringBoard.h>
#import <Foundation/Foundation.h>
#import <libactivator/libactivator.h>

#include <dlfcn.h>
#include <mach/port.h>
#include <mach/kern_return.h>

struct ComposedBatteryData {
    BOOL itemIsEnabled[25];
    BOOL timeString[64];
    int gsmSignalStrengthRaw;
    int gsmSignalStrengthBars;
    BOOL serviceString[100];
    BOOL serviceCrossfadeString[100];
    BOOL serviceImages[2][100];
    BOOL operatorDirectory[1024];
    unsigned int serviceContentType;
    int wifiSignalStrengthRaw;
    int wifiSignalStrengthBars;
    unsigned int dataNetworkType;
    int batteryCapacity;
    unsigned int batteryState;
    char batteryDetailString[150];
    int bluetoothBatteryCapacity;
    int thermalColor;
    unsigned int thermalSunlightMode : 1;
    unsigned int slowActivity : 1;
    unsigned int syncActivity : 1;
    BOOL activityDisplayId[256];
    unsigned int bluetoothConnected : 1;
    unsigned int displayRawGSMSignal : 1;
    unsigned int displayRawWifiSignal : 1;
    unsigned int locationIconType : 1;
    unsigned int quietModeInactive : 1;
    unsigned int tetheringConnectionCount;
    NSString *_doubleHeightStatus;
    BOOL _itemEnabled[30];
} ComposedBatteryData;

@interface UIStatusBarComposedData : NSObject <NSCopying> {
    struct ComposedBatteryData *_rawData;
}
@property(readonly) struct ComposedBatteryData *rawData;
- (struct ComposedBatteryData *)rawData;
@end

@interface UIStatusBarItemView : UIView
@end

@interface UIStatusBarBatteryPercentItemView : UIStatusBarItemView
- (BOOL)updateForNewData:(id)arg1 actions:(int)arg2;
@end

@interface UIStatusBar ()
- (void)setShowsOnlyCenterItems:(BOOL)arg1;
@end

@interface UIApplication ()
- (id)statusBar;
@end

@class UIStatusBarItem;

#define PREFERENCES_FILE_NAME "com.cnc.Battery-Temperature"
#define PREFERENCES_FILE_PATH @"/var/mobile/Library/Preferences/com.cnc.Battery-Temperature.plist"
#define PREFERENCES_NOTIFICATION_NAME "com.cnc.Battery-Temperature-preferencesChanged"

static BOOL enabled = false;
static BOOL autoHide = false;
static float autoHideCutoff = 0.0f;
static int unit = 0;

static void loadSettings() {
    CFPreferencesAppSynchronize(CFSTR(PREFERENCES_FILE_NAME));
    CFPreferencesSynchronize(CFSTR(PREFERENCES_FILE_NAME), kCFPreferencesAnyUser, kCFPreferencesAnyHost);
    NSDictionary *preferences = [[NSDictionary alloc] initWithContentsOfFile:PREFERENCES_FILE_PATH];
    
    Boolean exists = false;
    Boolean enabledRef = CFPreferencesGetAppBooleanValue(CFSTR("enabled"), CFSTR(PREFERENCES_FILE_NAME), &exists);
    if (exists) {
        enabled = enabledRef;
    } else {
        enabled = [preferences objectForKey:@"enabled"] ? [[preferences objectForKey:@"enabled"] boolValue] : YES;
    }
    
    exists = false;
    NSInteger unitRef = CFPreferencesGetAppIntegerValue(CFSTR("unit"), CFSTR(PREFERENCES_FILE_NAME), &exists);
    if (exists) {
        unit = (int)unitRef;
    } else {
        unit = [preferences objectForKey:@"unit"] ? [[preferences objectForKey:@"unit"] intValue] : 0;
    }
    
    exists = false;
    Boolean shouldAutoHideRef = CFPreferencesGetAppBooleanValue(CFSTR("shouldAutoHide"), CFSTR(PREFERENCES_FILE_NAME), &exists);
    if (exists) {
        autoHide = shouldAutoHideRef;
    } else {
        autoHide = [preferences objectForKey:@"shouldAutoHide"] ? [[preferences objectForKey:@"shouldAutoHide"] boolValue] : NO;
    }
    
    CFPropertyListRef autoHideCutoffRef = CFPreferencesCopyAppValue(CFSTR("autoHideCutoff"), CFSTR(PREFERENCES_FILE_NAME));
    if (autoHideCutoffRef) {
        autoHideCutoff = [(id)CFBridgingRelease(autoHideCutoffRef) floatValue];
    } else {
        autoHideCutoff = [preferences objectForKey:@"autoHideCutoff"] ? [[preferences objectForKey:@"autoHideCutoff"] floatValue] : 0.0f;
    }
    
    [preferences release];
}

static inline NSNumber *GetBatteryTemperature() {
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

static inline NSString *GetTemperatureString() {
    NSString *formattedString = @"N/A";
    NSNumber *rawTemperature = GetBatteryTemperature();
    
    if (rawTemperature) {
        float celsius = [rawTemperature intValue] / 100.0f;
        
        if (unit == 1) {
            float fahrenheit = (celsius * (9.0f / 5.0f)) + 32.0f;
            formattedString = [NSString stringWithFormat:@"%0.1f℉", fahrenheit];
        }
        else if (unit == 2) {
            float kelvin = celsius + 273.15;
            formattedString = [NSString stringWithFormat:@"%0.1f K", kelvin];
        }
        else {
            // Default to Celsius
            formattedString = [NSString stringWithFormat:@"%0.1f℃", celsius];
        }
    }
    
    return formattedString;
}

static void preferencesChanged(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    loadSettings();
    
    // Refresh the status bar
    UIStatusBar *statusBar = (UIStatusBar *)[[UIApplication sharedApplication] statusBar];
    [statusBar setShowsOnlyCenterItems:YES];
    [statusBar setShowsOnlyCenterItems:NO];
}

%hook UIStatusBarBatteryPercentItemView

- (id)initWithItem:(UIStatusBarItem *)item data:(void *)data actions:(NSInteger)actions style:(NSInteger)style {
    if ((self = %orig)) {
        self.userInteractionEnabled = YES;
    }
    return self;
}

- (BOOL)updateForNewData:(UIStatusBarComposedData *)arg1 actions:(int)arg2 {
    if (enabled) {
        // Get the battery's current charge percent
        char currentString[150];
        strcpy(currentString, arg1.rawData->batteryDetailString);
        
        NSString *batteryDetailString = [NSString stringWithUTF8String:currentString];
        NSString *sansPercentSignString = [batteryDetailString stringByReplacingOccurrencesOfString:@"%" withString:@""];
        
        NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
        formatter.numberStyle = NSNumberFormatterDecimalStyle;
        
        NSNumber *number = [formatter numberFromString:sansPercentSignString];
        [formatter release];
        
        float currentChargePercent = number ? [number floatValue] : 0.0f;
        
        // Only determine if the percent should be hidden if the charge percent has a value greater than 0.0
        // We can assume the value should always be greater than 0.0 because this program would have no power to run otherwise.
        if (currentChargePercent > 0.0) {
            // Copy the temperature string if we shouldn't hide it
            if (!autoHide || (currentChargePercent > autoHideCutoff)) {
                NSString *temperatureString = GetTemperatureString();
                strlcpy(arg1.rawData->batteryDetailString, [temperatureString UTF8String], sizeof(arg1.rawData->batteryDetailString));
            }
        }
        else {
            NSString *temperatureString = GetTemperatureString();
            strlcpy(arg1.rawData->batteryDetailString, [temperatureString UTF8String], sizeof(arg1.rawData->batteryDetailString));
        }
    }
    
    return %orig(arg1, arg2);
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    unit = (unit + 1) % 3;
    
    CFPreferencesSetAppValue(CFSTR("unit"), (CFNumberRef)[NSNumber numberWithInt:unit], CFSTR(PREFERENCES_FILE_NAME));
    CFPreferencesAppSynchronize(CFSTR(PREFERENCES_FILE_NAME));
    CFPreferencesSynchronize (CFSTR(PREFERENCES_FILE_NAME), kCFPreferencesAnyUser, kCFPreferencesAnyHost);
    
    NSMutableDictionary *preferences = [NSMutableDictionary dictionaryWithContentsOfFile:PREFERENCES_FILE_PATH];
    [preferences setObject:[NSNumber numberWithInt:unit] forKey:@"unit"];
    [preferences writeToFile:PREFERENCES_FILE_PATH atomically:YES];
    
    CFNotificationCenterPostNotification (CFNotificationCenterGetDarwinNotifyCenter(), CFSTR(PREFERENCES_NOTIFICATION_NAME), NULL, NULL, false);
    
    // Refresh the status bar
    UIStatusBar *statusBar = (UIStatusBar *)[[UIApplication sharedApplication] statusBar];
    [statusBar setShowsOnlyCenterItems:YES];
    [statusBar setShowsOnlyCenterItems:NO];
    
    %orig;
}

%end

%hook UIApplicationDelegate

- (void)applicationDidBecomeActive:(UIApplication *)application {
    UIStatusBar *statusBar = [application statusBar];
    [statusBar setShowsOnlyCenterItems:YES];
    [statusBar setShowsOnlyCenterItems:NO];
}

%end

%ctor {
    loadSettings();

    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, preferencesChanged, CFSTR(PREFERENCES_NOTIFICATION_NAME), NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
    
    %init;
}
