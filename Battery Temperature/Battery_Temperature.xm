#import <SpringBoard/SpringBoard.h>
#import <Foundation/Foundation.h>

#include <dlfcn.h>
#include <mach/port.h>
#include <mach/kern_return.h>
#include <limits.h>

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

@interface UIStatusBarBatteryPercentItemView
- (BOOL)updateForNewData:(id)arg1 actions:(int)arg2;
@end

@interface UIStatusBar ()
- (void)setShowsOnlyCenterItems:(BOOL)arg1;
@end

@interface UIApplication ()
- (id)statusBar;
@end

#define PREFERENCES_FILE_NAME "com.cnc.Battery-Temperature"
#define PREFERENCES_FILE_PATH @"/var/mobile/Library/Preferences/com.cnc.Battery-Temperature.plist"
#define PREFERENCES_NOTIFICATION_NAME "com.cnc.Battery-Temperature-preferencesChanged"

static BOOL enabled = false;
static BOOL autoHide = false;
static BOOL highAlert = false;
static BOOL lowAlert = false;
static BOOL didShowHighAlert = false;
static BOOL didShowLowAlert = false;

static float autoHideCutoff = 0.0f;
static float highAlertLimit = 35.0f;
static float lowAlertLimit = 0.0f;

static int unit = 0;

static void loadSettings() {
    CFPreferencesAppSynchronize(CFSTR(PREFERENCES_FILE_NAME));
    CFPropertyListRef enabledRef = CFPreferencesCopyAppValue(CFSTR("enabled"), CFSTR(PREFERENCES_FILE_NAME));
    CFPropertyListRef unitRef = CFPreferencesCopyAppValue(CFSTR("unit"), CFSTR(PREFERENCES_FILE_NAME));
    CFPropertyListRef shouldAutoHideRef = CFPreferencesCopyAppValue(CFSTR("shouldAutoHide"), CFSTR(PREFERENCES_FILE_NAME));
    CFPropertyListRef autoHideCutoffRef = CFPreferencesCopyAppValue(CFSTR("autoHideCutoff"), CFSTR(PREFERENCES_FILE_NAME));
    CFPropertyListRef showHighAlertRef = CFPreferencesCopyAppValue(CFSTR("showHighAlert"), CFSTR(PREFERENCES_FILE_NAME));
    CFPropertyListRef highTempLimitRef = CFPreferencesCopyAppValue(CFSTR("highTempLimit"), CFSTR(PREFERENCES_FILE_NAME));
    CFPropertyListRef showLowAlertRef = CFPreferencesCopyAppValue(CFSTR("showLowAlert"), CFSTR(PREFERENCES_FILE_NAME));
    CFPropertyListRef lowTempLimitRef = CFPreferencesCopyAppValue(CFSTR("lowTempLimit"), CFSTR(PREFERENCES_FILE_NAME));
    
    if (enabledRef && unitRef && shouldAutoHideRef && showHighAlertRef && highTempLimitRef && showLowAlertRef && lowTempLimitRef) {
        enabled =  [(id)CFBridgingRelease(enabledRef) boolValue];
        unit = [(id)CFBridgingRelease(unitRef) intValue];
        autoHide = [(id)CFBridgingRelease(shouldAutoHideRef) boolValue];
        autoHideCutoff = [(id)CFBridgingRelease(autoHideCutoffRef) floatValue];
        highAlert = [(id)CFBridgingRelease(showHighAlertRef) boolValue];
        highAlertLimit = [(id)CFBridgingRelease(highTempLimitRef) floatValue];
        lowAlert = [(id)CFBridgingRelease(showLowAlertRef) boolValue];
        lowAlertLimit = [(id)CFBridgingRelease(lowTempLimitRef) floatValue];
    }
    else {
        NSDictionary *preferences = [[NSDictionary alloc] initWithContentsOfFile:PREFERENCES_FILE_PATH];
        enabled = [preferences objectForKey:@"enabled"] ? [[preferences objectForKey:@"enabled"] boolValue] : NO;
        unit = [preferences objectForKey:@"unit"] ? [[preferences objectForKey:@"unit"] intValue] : 0;
        autoHide = [preferences objectForKey:@"shouldAutoHide"] ? [[preferences objectForKey:@"shouldAutoHide"] boolValue] : NO;
        autoHideCutoff = [preferences objectForKey:@"autoHideCutoff"] ? [[preferences objectForKey:@"autoHideCutoff"] floatValue] : 0.0f;
        highAlert = [preferences objectForKey:@"showHighAlert"] ? [[preferences objectForKey:@"showHighAlert"] boolValue] : NO;
        highAlertLimit = [preferences objectForKey:@"highTempLimit"] ? [[preferences objectForKey:@"highTempLimit"] floatValue] : 0.0f;
        lowAlert = [preferences objectForKey:@"showLowAlert"] ? [[preferences objectForKey:@"showLowAlert"] boolValue] : NO;
        lowAlertLimit = [preferences objectForKey:@"lowTempLimit"] ? [[preferences objectForKey:@"lowTempLimit"] floatValue] : 0.0f;
        
        [preferences release];
    }
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

- (BOOL)updateForNewData:(UIStatusBarComposedData *)arg1 actions:(int)arg2 {
    if (enabled) {
        char currentString[150];
        strcpy(currentString, arg1.rawData->batteryDetailString);
        
        NSString *batteryDetailString = [NSString stringWithUTF8String:currentString];
        NSString *sansPercentSignString = [batteryDetailString stringByReplacingOccurrencesOfString:@"%" withString:@""];
        
        NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
        formatter.numberStyle = NSNumberFormatterDecimalStyle;
        
        NSNumber *number = [formatter numberFromString:sansPercentSignString];
        [formatter release];
        
        // Get the battery's current charge percent
        float currentChargePercent = number ? [number floatValue] : 0.0f;
        
        // Show temperature alerts if necessary
        NSNumber *temperature = GetBatteryTemperature();
        if (temperature) {
            if ([temperature floatValue] >= highAlertLimit * 100.0f) {
                didShowLowAlert = false;
                
                if (highAlert && !didShowHighAlert) {
                    UIAlertView *highTempAlert = [[UIAlertView alloc] initWithTitle:@"High Battery Temperature" message:[NSString stringWithFormat:@"The battery temperature has reached %@.", GetTemperatureString()] delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
                    [highTempAlert show];
                    [highTempAlert release];
                    
                    didShowHighAlert = true;
                }
            }
            else if ([temperature floatValue] <= lowAlertLimit * 100.0f) {
                didShowHighAlert = false;
                
                if (lowAlert && !didShowLowAlert) {
                    UIAlertView *lowTempAlert = [[UIAlertView alloc] initWithTitle:@"Low Battery Temperature" message:[NSString stringWithFormat:@"The battery temperature has reached %@.", GetTemperatureString()] delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
                    [lowTempAlert show];
                    [lowTempAlert release];
                    
                    didShowLowAlert = true;
                }
            }
            else {
                didShowHighAlert = false;
                didShowLowAlert = false;
            }
        }
        
        // Decide if we should hide the temperature
        BOOL shouldHide = autoHide && (currentChargePercent <= autoHideCutoff);
        
        // Copy the temperature string if it's not hidden
        if (!shouldHide) {
            strlcpy(arg1.rawData->batteryDetailString, [GetTemperatureString() UTF8String], sizeof(arg1.rawData->batteryDetailString));
        }
    }
    
    return %orig(arg1, arg2);
}

%end

%ctor {
    %init;

    loadSettings();

    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, preferencesChanged, CFSTR(PREFERENCES_NOTIFICATION_NAME), NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
}
