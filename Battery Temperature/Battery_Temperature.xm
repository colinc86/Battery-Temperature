#import <SpringBoard/SpringBoard.h>
#import <Foundation/Foundation.h>

#import "BTActivatorListener.h"
#import "BTPreferencesInterface.h"
#import "BTAlertCenter.h"
#import "Headers.h"

#include <dlfcn.h>




#pragma mark - Static variables/functions

static BTAlertCenter *alertCenter = nil;

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
        
        BTPreferencesInterface *interface = [BTPreferencesInterface sharedInterface];
        
        if (interface.unit == 1) {
            if (interface.showAbbreviation) abbreviationString = @"℉";
                
                float fahrenheit = (celsius * (9.0f / 5.0f)) + 32.0f;
                
                if (interface.showDecimal) {
                    formattedString = [NSString stringWithFormat:@"%0.1f%@", fahrenheit, abbreviationString];
                }
                else {
                    formattedString = [NSString stringWithFormat:@"%0.f%@", fahrenheit, abbreviationString];
                }
        }
        else if (interface.unit == 2) {
            if (interface.showAbbreviation) abbreviationString = @" K";
                
                float kelvin = celsius + 273.15;
                
                if (interface.showDecimal) {
                    formattedString = [NSString stringWithFormat:@"%0.1f%@", kelvin, abbreviationString];
                }
                else {
                    formattedString = [NSString stringWithFormat:@"%0.f%@", kelvin, abbreviationString];
                }
        }
        else {
            // Default to Celsius
            if (interface.showAbbreviation) abbreviationString = @"℃";
                
                if (interface.showDecimal) {
                    formattedString = [NSString stringWithFormat:@"%0.1f%@", celsius, abbreviationString];
                }
                else {
                    formattedString = [NSString stringWithFormat:@"%0.f%@", celsius, abbreviationString];
                }
        }
    }
    
    return formattedString;
}

static void PerformUpdates() {
    BTPreferencesInterface *interface = [BTPreferencesInterface sharedInterface];
    [interface loadSettings];
    
    [alertCenter checkAlertsWithTemperature:GetBatteryTemperature() enabled:interface.enabled statusBarAlerts:interface.statusBarAlerts alertVibrate:interface.alertVibrate tempAlerts:interface.tempAlerts];
    [alertCenter updateTemperatureItem:(interface.enabled && [interface isTemperatureVisible:[alertCenter hasAlertShown]])];
}

static void RefreshStatusBarData(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    PerformUpdates();
    [UIStatusBarServer postStatusBarData:[UIStatusBarServer getStatusBarData] withActions:0];
}

static void ResetAlerts(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    [alertCenter resetAlerts];
}




#pragma mark - Hook methods

%subclass UIStatusBarBatteryTemperatureItemView : UIStatusBarCustomItemView

- (id)contentsImage {
    [[BTPreferencesInterface sharedInterface] loadSettings];
    
    NSString *temperatureString = GetTemperatureString();
    UIImage *temperatureImage = [((UIStatusBarItemView *) self) imageWithText:temperatureString];
    
    if (!temperatureImage) {
        temperatureImage = %orig;
    }
    
    return temperatureImage;
}

%end

%hook UIStatusBarServer

+ (void)postStatusBarData:(CDStruct_4ec3be00 *)arg1 withActions:(int)arg2 {
    PerformUpdates();
    %orig(arg1, arg2);
}

%end

%ctor {
    if (%c(SpringBoard)) {
        CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, RefreshStatusBarData, CFSTR(UPDATE_STAUS_BAR_NOTIFICATION_NAME), NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
        CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, ResetAlerts, CFSTR(RESET_ALERTS_NOTIFICATION_NAME), NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
        
        [[BTPreferencesInterface sharedInterface] startListeningForNotifications];
        
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
    
    %init;
}
