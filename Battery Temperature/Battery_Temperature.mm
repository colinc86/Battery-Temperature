#line 1 "/Users/colincampbell/Documents/Xcode/JailbreakProjects/Battery Temperature/Battery Temperature/Battery_Temperature.xm"
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

@interface SBStatusBarStateAggregator
+ (id)sharedInstance;
- (_Bool)_setItem:(int)arg1 enabled:(_Bool)arg2;
@end

@interface UIStatusBarItemView : UIView
@property (getter=isVisible, nonatomic) BOOL visible;
@end

@interface UIStatusBarBatteryPercentItemView : UIStatusBarItemView
- (BOOL)updateForNewData:(id)arg1 actions:(int)arg2;
@end

#define PREFERENCES_FILE_NAME "com.cnc.Battery-Temperature"
#define PREFERENCES_NOTIFICATION_NAME "com.cnc.Battery-Temperature-preferencesChanged"

static UIStatusBarItemView *itemView;
static BOOL enabled = false;
static int unit = 0;

static void loadSettings() {
    CFPreferencesAppSynchronize(CFSTR(PREFERENCES_FILE_NAME));
    enabled =  !CFPreferencesCopyAppValue(CFSTR("enabled"), CFSTR(PREFERENCES_FILE_NAME)) ? YES : [(id)CFBridgingRelease(CFPreferencesCopyAppValue(CFSTR("enabled"), CFSTR(PREFERENCES_FILE_NAME))) boolValue];
    unit = !CFPreferencesCopyAppValue(CFSTR("unit"), CFSTR(PREFERENCES_FILE_NAME)) ? 0 : [(id)CFBridgingRelease(CFPreferencesCopyAppValue(CFSTR("unit"), CFSTR(PREFERENCES_FILE_NAME))) intValue];
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
    NSString *formattedString = @"";
    NSNumber *rawTemperature = GetBatteryTemperature();
    
    if (!rawTemperature) {
        formattedString = @"N/A";
    }
    else {
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
            
            formattedString = [NSString stringWithFormat:@"%0.1f℃", celsius];
        }
    }
    
    return formattedString;
}

#include <logos/logos.h>
#include <substrate.h>
@class UIStatusBarBatteryPercentItemView; @class SBStatusBarStateAggregator; 
static BOOL (*_logos_orig$_ungrouped$UIStatusBarBatteryPercentItemView$updateForNewData$actions$)(UIStatusBarBatteryPercentItemView*, SEL, UIStatusBarComposedData *, int); static BOOL _logos_method$_ungrouped$UIStatusBarBatteryPercentItemView$updateForNewData$actions$(UIStatusBarBatteryPercentItemView*, SEL, UIStatusBarComposedData *, int); 
static __inline__ __attribute__((always_inline)) Class _logos_static_class_lookup$SBStatusBarStateAggregator(void) { static Class _klass; if(!_klass) { _klass = objc_getClass("SBStatusBarStateAggregator"); } return _klass; }
#line 129 "/Users/colincampbell/Documents/Xcode/JailbreakProjects/Battery Temperature/Battery Temperature/Battery_Temperature.xm"
static void preferencesChanged(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    loadSettings();
    
    if (itemView.visible) {
        SBStatusBarStateAggregator *aggregator = [_logos_static_class_lookup$SBStatusBarStateAggregator() sharedInstance];
        [aggregator _setItem:8 enabled:NO];
        [aggregator _setItem:8 enabled:YES];
    }
}



static BOOL _logos_method$_ungrouped$UIStatusBarBatteryPercentItemView$updateForNewData$actions$(UIStatusBarBatteryPercentItemView* self, SEL _cmd, UIStatusBarComposedData * arg1, int arg2) {
    if (itemView != self) {
        [itemView release];
        itemView = [self retain];
    }
    
    if (enabled) {
        char currentString[150];
        strcpy(currentString, arg1.rawData->batteryDetailString);
        NSString *tempString = GetTemperatureString();
        strlcpy(arg1.rawData->batteryDetailString, [tempString UTF8String], sizeof(arg1.rawData->batteryDetailString));
    }
    
    return _logos_orig$_ungrouped$UIStatusBarBatteryPercentItemView$updateForNewData$actions$(self, _cmd, arg1, arg2);
}



static __attribute__((constructor)) void _logosLocalCtor_1aadaca9() {
    {Class _logos_class$_ungrouped$UIStatusBarBatteryPercentItemView = objc_getClass("UIStatusBarBatteryPercentItemView"); MSHookMessageEx(_logos_class$_ungrouped$UIStatusBarBatteryPercentItemView, @selector(updateForNewData:actions:), (IMP)&_logos_method$_ungrouped$UIStatusBarBatteryPercentItemView$updateForNewData$actions$, (IMP*)&_logos_orig$_ungrouped$UIStatusBarBatteryPercentItemView$updateForNewData$actions$);}
    
    loadSettings();
    
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, preferencesChanged, CFSTR(PREFERENCES_NOTIFICATION_NAME), NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
}
