#line 1 "/Users/colincampbell/Documents/Xcode/Jailbreak/JailbreakProjects/Battery-Temperature/Battery Temperature/Battery_Temperature.xm"
#import <SpringBoard/SpringBoard.h>
#import <Foundation/Foundation.h>
#include <dlfcn.h>

#import "BTActivatorListener.h"
#import "BTPreferencesInterface.h"
#import "BTStatusItemController.h"




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

@interface UIStatusBarServer : NSObject
+ (CDStruct_4ec3be00 *)getStatusBarData;
+ (void)postStatusBarData:(CDStruct_4ec3be00 *)arg1 withActions:(int)arg2;
@end

@interface UIStatusBarItemView : UIView
- (id)imageWithText:(id)arg1;
@end




NSNumber *GetBatteryTemperature();
NSString *GetTemperatureString();
void PerformUpdates();
void PreferencesChanged(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo);

static BTPreferencesInterface *preferencesInterface = nil;
static BTStatusItemController *itemController = nil;




#pragma mark - Functions

void PerformUpdates() {
    [preferencesInterface updateSettings];
    
    if (itemController != nil) {
        [itemController updateAlertItem:(preferencesInterface.enabled && preferencesInterface.statusBarAlerts) temperature:GetBatteryTemperature()];
        [itemController updateTemperatureItem:(preferencesInterface.enabled && [preferencesInterface isTemperatureVisible:[itemController isAlertActive]])];
    }
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
@class UIStatusBarBatteryTemperatureItemView; @class SpringBoard; @class UIStatusBarCustomItemView; @class UIStatusBarServer; 
static id (*_logos_orig$_ungrouped$UIStatusBarBatteryTemperatureItemView$contentsImage)(UIStatusBarBatteryTemperatureItemView*, SEL); static id _logos_method$_ungrouped$UIStatusBarBatteryTemperatureItemView$contentsImage(UIStatusBarBatteryTemperatureItemView*, SEL); static void (*_logos_meta_orig$_ungrouped$UIStatusBarServer$postStatusBarData$withActions$)(Class, SEL, CDStruct_4ec3be00 *, int); static void _logos_meta_method$_ungrouped$UIStatusBarServer$postStatusBarData$withActions$(Class, SEL, CDStruct_4ec3be00 *, int); 
static __inline__ __attribute__((always_inline)) Class _logos_static_class_lookup$SpringBoard(void) { static Class _klass; if(!_klass) { _klass = objc_getClass("SpringBoard"); } return _klass; }
#line 160 "/Users/colincampbell/Documents/Xcode/Jailbreak/JailbreakProjects/Battery-Temperature/Battery Temperature/Battery_Temperature.xm"


static id _logos_method$_ungrouped$UIStatusBarBatteryTemperatureItemView$contentsImage(UIStatusBarBatteryTemperatureItemView* self, SEL _cmd) {
    [preferencesInterface updateSettings];
    
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



static __attribute__((constructor)) void _logosLocalCtor_6b26e8e0() {
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, PreferencesChanged, CFSTR(PREFERENCES_NOTIFICATION_NAME), NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
    
    preferencesInterface = [[BTPreferencesInterface alloc] init];
    
    if (_logos_static_class_lookup$SpringBoard()) {
    	void *Libstatusbar = dlopen("/Library/MobileSubstrate/DynamicLibraries/libstatusbar.dylib", RTLD_LAZY);
    	Class ls = objc_getClass("LSStatusBarItem");
    	if (ls) {
            [preferencesInterface setHasLibstatusbar:YES];
    		itemController = [[BTStatusItemController alloc] initWithLibrary:Libstatusbar];
    	}
        else {
            dlclose(Libstatusbar);
            [preferencesInterface setHasLibstatusbar:NO];
        }
        
        PerformUpdates();
        
        void *Libactivator = dlopen("/usr/lib/libactivator.dylib", RTLD_LAZY);
        Class la = objc_getClass("LAActivator");
        if (la) {
            [preferencesInterface setHasLibactivator:YES];
            
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
        else {
            [preferencesInterface setHasLibactivator:NO];
        }
        
        dlclose(Libactivator);
    }
    
    {Class _logos_class$_ungrouped$UIStatusBarCustomItemView = objc_getClass("UIStatusBarCustomItemView"); { Class _logos_class$_ungrouped$UIStatusBarBatteryTemperatureItemView = objc_allocateClassPair(_logos_class$_ungrouped$UIStatusBarCustomItemView, "UIStatusBarBatteryTemperatureItemView", 0); MSHookMessageEx(_logos_class$_ungrouped$UIStatusBarBatteryTemperatureItemView, @selector(contentsImage), (IMP)&_logos_method$_ungrouped$UIStatusBarBatteryTemperatureItemView$contentsImage, (IMP*)&_logos_orig$_ungrouped$UIStatusBarBatteryTemperatureItemView$contentsImage); objc_registerClassPair(_logos_class$_ungrouped$UIStatusBarBatteryTemperatureItemView); }Class _logos_class$_ungrouped$UIStatusBarServer = objc_getClass("UIStatusBarServer"); Class _logos_metaclass$_ungrouped$UIStatusBarServer = object_getClass(_logos_class$_ungrouped$UIStatusBarServer); MSHookMessageEx(_logos_metaclass$_ungrouped$UIStatusBarServer, @selector(postStatusBarData:withActions:), (IMP)&_logos_meta_method$_ungrouped$UIStatusBarServer$postStatusBarData$withActions$, (IMP*)&_logos_meta_orig$_ungrouped$UIStatusBarServer$postStatusBarData$withActions$);}
}
