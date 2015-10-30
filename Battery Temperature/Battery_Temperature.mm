#line 1 "/Users/colincampbell/Documents/Xcode/Jailbreak/JailbreakProjects/Battery-Temperature/Battery Temperature/Battery_Temperature.xm"
#import <SpringBoard/SpringBoard.h>
#import <Foundation/Foundation.h>

#import "BTActivatorListener.h"
#import "BTPreferencesInterface.h"
#import "BTAlertCenter.h"
#import "Headers.h"

#include <dlfcn.h>




NSNumber *GetBatteryTemperature();
NSString *GetTemperatureString();
void PerformUpdates();
void ResetAlerts(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo);
void PreferencesChanged(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo);

static BTPreferencesInterface *preferencesInterface = nil;
static BTAlertCenter *alertCenter = nil;




#pragma mark - Functions

void PerformUpdates() {
    [preferencesInterface loadSettings];
    [alertCenter checkAlertsWithTemperature:GetBatteryTemperature() enabled:preferencesInterface.enabled statusBarAlerts:preferencesInterface.statusBarAlerts alertVibrate:preferencesInterface.alertVibrate tempAlerts:preferencesInterface.tempAlerts];
    [alertCenter updateTemperatureItem:(preferencesInterface.enabled && [preferencesInterface isTemperatureVisible:[alertCenter hasAlertShown]])];
}

void ResetAlerts(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    [alertCenter resetAlerts];
}

void PreferencesChanged(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    PerformUpdates();
}

NSNumber *GetBatteryTemperature() {
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

NSString *GetTemperatureString() {
    NSString *formattedString = @"N/A";
    NSNumber *rawTemperature = GetBatteryTemperature();
    
    if (rawTemperature) {
        NSString *abbreviationString = @"";
        float celsius = [rawTemperature intValue] / 100.0f;

        [preferencesInterface loadSettings];

        if (preferencesInterface.unit == 1) {
            if (preferencesInterface.showAbbreviation) abbreviationString = @"℉";
                
                float fahrenheit = (celsius * (9.0f / 5.0f)) + 32.0f;
                
                if (preferencesInterface.showDecimal) {
                    formattedString = [NSString stringWithFormat:@"%0.1f%@", fahrenheit, abbreviationString];
                }
                else {
                    formattedString = [NSString stringWithFormat:@"%0.f%@", fahrenheit, abbreviationString];
                }
        }
        else if (preferencesInterface.unit == 2) {
            if (preferencesInterface.showAbbreviation) abbreviationString = @" K";
                
                float kelvin = celsius + 273.15;
                
                if (preferencesInterface.showDecimal) {
                    formattedString = [NSString stringWithFormat:@"%0.1f%@", kelvin, abbreviationString];
                }
                else {
                    formattedString = [NSString stringWithFormat:@"%0.f%@", kelvin, abbreviationString];
                }
        }
        else {
            
            if (preferencesInterface.showAbbreviation) abbreviationString = @"℃";
                
                if (preferencesInterface.showDecimal) {
                    formattedString = [NSString stringWithFormat:@"%0.1f%@", celsius, abbreviationString];
                }
                else {
                    formattedString = [NSString stringWithFormat:@"%0.f%@", celsius, abbreviationString];
                }
        }
    }
    
    return formattedString;
}




#pragma mark - Hook methods

#include <logos/logos.h>
#include <substrate.h>
@class UIStatusBarCustomItemView; @class SpringBoard; @class UIStatusBarServer; @class UIStatusBarBatteryTemperatureItemView; 
static id (*_logos_orig$_ungrouped$UIStatusBarBatteryTemperatureItemView$contentsImage)(UIStatusBarBatteryTemperatureItemView*, SEL); static id _logos_method$_ungrouped$UIStatusBarBatteryTemperatureItemView$contentsImage(UIStatusBarBatteryTemperatureItemView*, SEL); static void (*_logos_meta_orig$_ungrouped$UIStatusBarServer$postStatusBarData$withActions$)(Class, SEL, CDStruct_4ec3be00 *, int); static void _logos_meta_method$_ungrouped$UIStatusBarServer$postStatusBarData$withActions$(Class, SEL, CDStruct_4ec3be00 *, int); 
static __inline__ __attribute__((always_inline)) Class _logos_static_class_lookup$SpringBoard(void) { static Class _klass; if(!_klass) { _klass = objc_getClass("SpringBoard"); } return _klass; }
#line 124 "/Users/colincampbell/Documents/Xcode/Jailbreak/JailbreakProjects/Battery-Temperature/Battery Temperature/Battery_Temperature.xm"


static id _logos_method$_ungrouped$UIStatusBarBatteryTemperatureItemView$contentsImage(UIStatusBarBatteryTemperatureItemView* self, SEL _cmd) {
    [preferencesInterface loadSettings];
    
    NSString *temperatureString = GetTemperatureString();
    UIImage *temperatureImage = [((UIStatusBarItemView *) self) imageWithText:temperatureString];
    
    if (!temperatureImage) {
        temperatureImage = _logos_orig$_ungrouped$UIStatusBarBatteryTemperatureItemView$contentsImage(self, _cmd);
    }
    
    return temperatureImage;
}





static void _logos_meta_method$_ungrouped$UIStatusBarServer$postStatusBarData$withActions$(Class self, SEL _cmd, CDStruct_4ec3be00 * arg1, int arg2) {
    PerformUpdates();
    _logos_meta_orig$_ungrouped$UIStatusBarServer$postStatusBarData$withActions$(self, _cmd, arg1, arg2);
}



static __attribute__((constructor)) void _logosLocalCtor_9f9f90ed() {
    if (_logos_static_class_lookup$SpringBoard()) {
        CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, ResetAlerts, CFSTR(RESET_ALERTS_NOTIFICATION_NAME), NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
        CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, PreferencesChanged, CFSTR(PREFERENCES_NOTIFICATION_NAME), NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
        
        preferencesInterface = [[BTPreferencesInterface alloc] init];
        [preferencesInterface checkDefaultSettings];
        
        alertCenter = [[BTAlertCenter alloc] init];
        
        PerformUpdates();
        
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
    
    {Class _logos_class$_ungrouped$UIStatusBarCustomItemView = objc_getClass("UIStatusBarCustomItemView"); { Class _logos_class$_ungrouped$UIStatusBarBatteryTemperatureItemView = objc_allocateClassPair(_logos_class$_ungrouped$UIStatusBarCustomItemView, "UIStatusBarBatteryTemperatureItemView", 0); MSHookMessageEx(_logos_class$_ungrouped$UIStatusBarBatteryTemperatureItemView, @selector(contentsImage), (IMP)&_logos_method$_ungrouped$UIStatusBarBatteryTemperatureItemView$contentsImage, (IMP*)&_logos_orig$_ungrouped$UIStatusBarBatteryTemperatureItemView$contentsImage); objc_registerClassPair(_logos_class$_ungrouped$UIStatusBarBatteryTemperatureItemView); }Class _logos_class$_ungrouped$UIStatusBarServer = objc_getClass("UIStatusBarServer"); Class _logos_metaclass$_ungrouped$UIStatusBarServer = object_getClass(_logos_class$_ungrouped$UIStatusBarServer); MSHookMessageEx(_logos_metaclass$_ungrouped$UIStatusBarServer, @selector(postStatusBarData:withActions:), (IMP)&_logos_meta_method$_ungrouped$UIStatusBarServer$postStatusBarData$withActions$, (IMP*)&_logos_meta_orig$_ungrouped$UIStatusBarServer$postStatusBarData$withActions$);}
}
