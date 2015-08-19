#import <SpringBoard/SpringBoard.h>
#import <Foundation/Foundation.h>
#import <libactivator/libactivator.h>

#include <dlfcn.h>
#include <mach/port.h>
#include <mach/kern_return.h>






typedef struct {
    char itemIsEnabled[25];
    char timeString[64];
    int gsmSignalStrengthRaw;
    int gsmSignalStrengthBars;
    char serviceString[100];
    char serviceCrossfadeString[100];
    char serviceImages[2][100];
    char operatorDirectory[1024];
    unsigned int serviceContentType;
    int wifiSignalStrengthRaw;
    int wifiSignalStrengthBars;
    unsigned int dataNetworkType;
    int batteryCapacity;
    unsigned int batteryState;
    char batteryDetailString[150];
    int bluetoothBatteryCapacity;
    int thermalColor;
    unsigned int thermalSunlightMode:1;
    unsigned int slowActivity:1;
    unsigned int syncActivity:1;
    char activityDisplayId[256];
    unsigned int bluetoothConnected:1;
    unsigned int displayRawGSMSignal:1;
    unsigned int displayRawWifiSignal:1;
    unsigned int locationIconType:1;
    unsigned int quietModeInactive:1;
    unsigned int tetheringConnectionCount;
} CDStruct_4ec3be00;

typedef struct {
    BOOL x1[24];
    unsigned int x2 : 1;
    unsigned int x3 : 1;
    unsigned int x4 : 1;
    unsigned int x5 : 1;
    unsigned int x6 : 2;
    unsigned int x7 : 1;
    unsigned int x8 : 1;
    unsigned int x9 : 1;
    unsigned int x10 : 1;
    unsigned int x11 : 1;
    unsigned int x12 : 1;
    unsigned int x13 : 1;
    unsigned int x14 : 1;
    unsigned int x15 : 1;
    unsigned int x16 : 1;
    unsigned int x17 : 1;
    unsigned int x18 : 1;
    unsigned int x19 : 1;
    unsigned int x20 : 1;
    unsigned int x21 : 1;
    unsigned int x22 : 1;
    CDStruct_4ec3be00 x23;
} RAWDATA;

@class UIStatusBarItem;

@interface UIStatusBarItemView : UIView
@end

@interface UIStatusBarBatteryPercentItemView : UIStatusBarItemView
- (id)initWithItem:(UIStatusBarItem *)item data:(void *)data actions:(NSInteger)actions style:(NSInteger)style;
@end

@interface UIStatusBarServer : NSObject
+ (CDStruct_4ec3be00 *)getStatusBarData;
+ (void)postStatusBarData:(CDStruct_4ec3be00 *)arg1 withActions:(int)arg2;
+ (RAWDATA *)getStatusBarOverrideData;
+ (void)postStatusBarOverrideData:(RAWDATA *)arg1;
@end






#define PREFERENCES_FILE_NAME "com.cnc.Battery-Temperature"
#define PREFERENCES_FILE_PATH @"/var/mobile/Library/Preferences/com.cnc.Battery-Temperature.plist"
#define PREFERENCES_NOTIFICATION_NAME "com.cnc.Battery-Temperature-preferencesChanged"

// Preferences variables
static BOOL enabled = false;
static BOOL autoHide = false;
static BOOL hidePercent = false;
static float autoHideCutoff = 0.0f;
static int unit = 0;

// Local variables
static BOOL forcedUpdate = false;
static NSString *lastBatteryDetailString = @"";

static void loadSettings() {
    CFPreferencesAppSynchronize(CFSTR(PREFERENCES_FILE_NAME));
    
    CFPropertyListRef enabledRef = CFPreferencesCopyAppValue(CFSTR("enabled"), CFSTR(PREFERENCES_FILE_NAME));
    enabled = enabledRef ? [(id)CFBridgingRelease(enabledRef) boolValue] : YES;
    
    CFPropertyListRef unitRef = CFPreferencesCopyAppValue(CFSTR("unit"), CFSTR(PREFERENCES_FILE_NAME));
    unit = unitRef ? [(id)CFBridgingRelease(unitRef) intValue] : 0;
    
    CFPropertyListRef shouldAutoHideRef = CFPreferencesCopyAppValue(CFSTR("shouldAutoHide"), CFSTR(PREFERENCES_FILE_NAME));
    autoHide = shouldAutoHideRef ? [(id)CFBridgingRelease(shouldAutoHideRef) boolValue] : NO;
    
    CFPropertyListRef autoHideCutoffRef = CFPreferencesCopyAppValue(CFSTR("autoHideCutoff"), CFSTR(PREFERENCES_FILE_NAME));
    autoHideCutoff = autoHideCutoffRef ? [(id)CFBridgingRelease(autoHideCutoffRef) floatValue] : 0.0f;
    
    CFPropertyListRef hidePercentRef = CFPreferencesCopyAppValue(CFSTR("hidePercent"), CFSTR(PREFERENCES_FILE_NAME));
    hidePercent = hidePercentRef ? [(id)CFBridgingRelease(hidePercentRef) boolValue] : NO;
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

static void refreshStatusBarData() {
    [UIStatusBarServer postStatusBarData:[UIStatusBarServer getStatusBarData] withActions:0];
}

static void preferencesChanged(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    forcedUpdate = true;
    loadSettings();
    refreshStatusBarData();
}






%hook UIStatusBarServer

+ (void)postStatusBarData:(CDStruct_4ec3be00 *)arg1 withActions:(int)arg2 {
    // Get the battery detail string
    char currentString[150];
    strcpy(currentString, arg1->batteryDetailString);
    NSString *batteryDetailString = [NSString stringWithUTF8String:currentString];
    
    // If this is a system update, then cache the percent string
    if (!forcedUpdate) {
        if (lastBatteryDetailString != nil) {
            [lastBatteryDetailString release];
        }
        lastBatteryDetailString = [batteryDetailString retain];
    }
    
    if (enabled) {
        // Get the battery's current charge percent
        NSString *sansPercentSignString = [batteryDetailString stringByReplacingOccurrencesOfString:@"%" withString:@""];
        NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
        formatter.numberStyle = NSNumberFormatterDecimalStyle;
        NSNumber *number = [formatter numberFromString:sansPercentSignString];
        [formatter release];
        
        float currentChargePercent = number ? [number floatValue] : 0.0f;

        // Only show the temperature string if we aren't auto-hiding the temperature or if the current charge is above the auto cutoff value.
        // We can assume currentChargePercent should always have a value greater than 0.0 because this program would have no power to run otherwise.
        bool printTemp =(currentChargePercent <= 0.0) || !autoHide || (currentChargePercent > autoHideCutoff);
        
        if (printTemp) {
            NSString *temperatureString = GetTemperatureString();
            
            if (!hidePercent) {
                // Append the battery detail string if we're showing the percent
                temperatureString = [temperatureString stringByAppendingFormat:@"  %@", lastBatteryDetailString];
            }
            
            strlcpy(arg1->batteryDetailString, [temperatureString UTF8String], sizeof(arg1->batteryDetailString));
        }
    } else if (forcedUpdate) {
        // If we manually disabled the tweak then copy in the last updated detain string
        strlcpy(arg1->batteryDetailString, [lastBatteryDetailString UTF8String], sizeof(arg1->batteryDetailString));
    }
    
    // Reset the forced update flag
    forcedUpdate = false;
    
    %orig(arg1, arg2);
}

%end

%hook UIStatusBarBatteryPercentItemView

- (id)initWithItem:(UIStatusBarItem *)item data:(void *)data actions:(NSInteger)actions style:(NSInteger)style {
    if ((self = %orig)) {
        self.userInteractionEnabled = YES;
    }
    return self;
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    unit = (unit + 1) % 3;
    
    CFPreferencesSetAppValue(CFSTR("unit"), (CFNumberRef)[NSNumber numberWithInt:unit], CFSTR(PREFERENCES_FILE_NAME));
    CFPreferencesAppSynchronize(CFSTR(PREFERENCES_FILE_NAME));
    CFNotificationCenterPostNotification (CFNotificationCenterGetDarwinNotifyCenter(), CFSTR(PREFERENCES_NOTIFICATION_NAME), NULL, NULL, false);
    
    forcedUpdate = true;
    refreshStatusBarData();
    
    %orig;
}

%end

%ctor {
    loadSettings();

    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, preferencesChanged, CFSTR(PREFERENCES_NOTIFICATION_NAME), NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
    
    %init;
}
