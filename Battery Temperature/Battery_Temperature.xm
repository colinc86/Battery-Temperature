#import <UIKit/UIKit.h>
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

@interface UIStatusBarItemView : UIView
@end

@interface UIStatusBarBatteryPercentItemView : UIStatusBarItemView {
    NSString *_percentString;
}
- (int)textStyle;
- (int)textAlignment;
- (BOOL)animatesDataChange;
- (float)extraRightPadding;
- (id)contentsImage;
- (BOOL)updateForNewData:(id)arg1 actions:(int)arg2;
- (void)dealloc;
@end

#define SETTINGS_PATH @"/var/mobile/Library/Preferences/com.cnc.Battery-Temperature.plist"

static UIStatusBarBatteryPercentItemView *itemView;
static NSString *percentString;

static inline int GetBatteryTemperature() {
    int temp = INT_MAX;
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
                CFTypeRef temperature = IORegistryEntryCreateCFProperty(powerSource, CFSTR("Temperature"), kCFAllocatorDefault, 0);
                temp = [(__bridge NSNumber *)temperature intValue];
            }
        }
    }
    
    dlclose(IOKit);
    
    return temp;
}

static inline NSString *GetTemperatureString() {
    NSString *formattedString = @"";
    int rawTemperature = GetBatteryTemperature();
    
    if (rawTemperature == INT_MAX) {
        formattedString = @"N/A";
    }
    else {
        float celcius = (float)rawTemperature / 100.0f;
        
        NSDictionary *settings = [NSDictionary dictionaryWithContentsOfFile:SETTINGS_PATH];
        int unit = settings[@"unit"] ? [settings[@"unit"] intValue] : 0;
        if (unit == 1) {
            float farenheit = (celcius * (9.0f / 5.0f)) + 32.0f;
            formattedString = [NSString stringWithFormat:@"%0.1f℉", farenheit];
        }
        else if (unit == 2) {
            float kelvin = celcius + 273.15;
            formattedString = [NSString stringWithFormat:@"%0.1f K", kelvin];
        }
        else {
            formattedString = [NSString stringWithFormat:@"%0.1f℃", celcius];
        }
    }
    
    return formattedString;
}

static void preferencesChanged(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    NSDictionary *settings = [NSDictionary dictionaryWithContentsOfFile:SETTINGS_PATH];
    BOOL enabled = settings[@"enabled"] ? [settings[@"enabled"] boolValue] : NO;
    
    if (itemView && percentString && enabled) {
        percentString = GetTemperatureString();
        [itemView setNeedsDisplay];
    }
}

%hook UIStatusBarBatteryPercentItemView

- (BOOL)updateForNewData:(UIStatusBarComposedData *)arg1 actions:(int)arg2 {
    if (itemView != self) {
        [itemView release];
        itemView = [self retain];
        percentString = MSHookIvar<NSString *>(self, "_percentString");
        percentVisible = MSHookIvar<BOOL>(self, "_visible");
    }
    
    NSDictionary *settings = [NSDictionary dictionaryWithContentsOfFile:SETTINGS_PATH];
    BOOL enabled = settings[@"enabled"] ? [settings[@"enabled"] boolValue] : NO;
    
    if (enabled) {
        char currentString[150];
        strcpy(currentString, arg1.rawData->batteryDetailString);
        NSString *tempString = GetTemperatureString();
        strlcpy(arg1.rawData->batteryDetailString, [tempString UTF8String], sizeof(arg1.rawData->batteryDetailString));
    }
    
    return %orig(arg1, arg2);
}

%end

%ctor {
    %init;
    
    CFNotificationCenterRef center = CFNotificationCenterGetDarwinNotifyCenter();
    CFNotificationCenterAddObserver(center, NULL, &preferencesChanged, CFSTR("com.cnc.Battery-Temperature-preferencesChanged"), NULL, 0);
}
