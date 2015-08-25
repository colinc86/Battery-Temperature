#line 1 "/Users/colincampbell/Documents/Xcode/JailbreakProjects/Battery-Temperature/Battery Temperature/Battery_Temperature.xm"
#import <SpringBoard/SpringBoard.h>
#import <Foundation/Foundation.h>

#import "BTActivatorListener.h"
#import "BTStatusItemManager.h"
#import "BTPreferencesInterface.h"
#import "BTStaticFunctions.h"

#include <dlfcn.h>




#pragma mark - Status bar classes/types

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

@interface SBStatusBarStateAggregator
+ (id)sharedInstance;
- (BOOL)_setItem:(int)arg1 enabled:(BOOL)arg2;
@end




#pragma mark - Static variables/functions

static NSString *lastBatteryDetailString = nil;

#include <logos/logos.h>
#include <substrate.h>
@class UIStatusBarServer; @class SBStatusBarStateAggregator; @class SpringBoard; 
static void (*_logos_meta_orig$_ungrouped$UIStatusBarServer$postStatusBarData$withActions$)(Class, SEL, CDStruct_4ec3be00 *, int); static void _logos_meta_method$_ungrouped$UIStatusBarServer$postStatusBarData$withActions$(Class, SEL, CDStruct_4ec3be00 *, int); static BOOL (*_logos_orig$_ungrouped$SBStatusBarStateAggregator$_setItem$enabled$)(SBStatusBarStateAggregator*, SEL, int, BOOL); static BOOL _logos_method$_ungrouped$SBStatusBarStateAggregator$_setItem$enabled$(SBStatusBarStateAggregator*, SEL, int, BOOL); 
static __inline__ __attribute__((always_inline)) Class _logos_static_class_lookup$SBStatusBarStateAggregator(void) { static Class _klass; if(!_klass) { _klass = objc_getClass("SBStatusBarStateAggregator"); } return _klass; }static __inline__ __attribute__((always_inline)) Class _logos_static_class_lookup$SpringBoard(void) { static Class _klass; if(!_klass) { _klass = objc_getClass("SpringBoard"); } return _klass; }
#line 63 "/Users/colincampbell/Documents/Xcode/JailbreakProjects/Battery-Temperature/Battery Temperature/Battery_Temperature.xm"
static void refreshStatusBarData(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    BTPreferencesInterface *interface = [BTPreferencesInterface sharedInterface];
    SBStatusBarStateAggregator *aggregator = [_logos_static_class_lookup$SBStatusBarStateAggregator() sharedInstance];
    [aggregator _setItem:8 enabled:NO];
    if (interface.showPercent || interface.enabled) {
        [aggregator _setItem:8 enabled:YES];
    }
    
    [[BTStatusItemManager sharedManager] update];
    
    
    interface.forcedUpdate = YES;
    [UIStatusBarServer postStatusBarData:[UIStatusBarServer getStatusBarData] withActions:0];
}




#pragma mark - Hook methods



static void _logos_meta_method$_ungrouped$UIStatusBarServer$postStatusBarData$withActions$(Class self, SEL _cmd, CDStruct_4ec3be00 * arg1, int arg2) {
    BTPreferencesInterface *interface = [BTPreferencesInterface sharedInterface];
    [interface loadSettings];
    [interface loadSpringBoardSettings];
    
    char currentString[150];
    strcpy(currentString, arg1->batteryDetailString);
    NSString *batteryDetailString = [NSString stringWithUTF8String:currentString];
    
    if (!interface.forcedUpdate) {
        if (lastBatteryDetailString != nil) {
            [lastBatteryDetailString release];
            lastBatteryDetailString = nil;
        }
        lastBatteryDetailString = [batteryDetailString retain];
    }
    
    [BTStaticFunctions checkAlerts];
    
    [[BTStatusItemManager sharedManager] update];
    
    if (interface.enabled) {
        NSString *temperatureString = [BTStaticFunctions getTemperatureString];
        
        if (interface.showPercent) {
            temperatureString = [temperatureString stringByAppendingFormat:@"  %@", lastBatteryDetailString];
        }
        
        strlcpy(arg1->batteryDetailString, [temperatureString UTF8String], sizeof(arg1->batteryDetailString));
    } else if (interface.forcedUpdate) {
        if (interface.showPercent) {
            strlcpy(arg1->batteryDetailString, [lastBatteryDetailString UTF8String], sizeof(arg1->batteryDetailString));
        }
        else {
            NSString *blankString = @"";
            strlcpy(arg1->batteryDetailString, [blankString UTF8String], sizeof(arg1->batteryDetailString));
        }
    }
    
    interface.forcedUpdate = false;
    
    _logos_meta_orig$_ungrouped$UIStatusBarServer$postStatusBarData$withActions$(self, _cmd, arg1, arg2);
}





static BOOL _logos_method$_ungrouped$SBStatusBarStateAggregator$_setItem$enabled$(SBStatusBarStateAggregator* self, SEL _cmd, int arg1, BOOL arg2) {
    BTPreferencesInterface *interface = [BTPreferencesInterface sharedInterface];
    if (arg1 == 8) {
        interface.showPercent = interface.enabled;
    }
    
    return _logos_orig$_ungrouped$SBStatusBarStateAggregator$_setItem$enabled$(self, _cmd, arg1, ((arg1 == 8) && interface.enabled) ? YES : arg2);
}



static __attribute__((constructor)) void _logosLocalCtor_94b0abe3() {
    if (_logos_static_class_lookup$SpringBoard()) {
        CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, refreshStatusBarData, CFSTR(UPDATE_STAUS_BAR_NOTIFICATION_NAME), NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
        
        [[BTPreferencesInterface sharedInterface] startListeningForNotifications];
        
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
    
    {Class _logos_class$_ungrouped$UIStatusBarServer = objc_getClass("UIStatusBarServer"); Class _logos_metaclass$_ungrouped$UIStatusBarServer = object_getClass(_logos_class$_ungrouped$UIStatusBarServer); MSHookMessageEx(_logos_metaclass$_ungrouped$UIStatusBarServer, @selector(postStatusBarData:withActions:), (IMP)&_logos_meta_method$_ungrouped$UIStatusBarServer$postStatusBarData$withActions$, (IMP*)&_logos_meta_orig$_ungrouped$UIStatusBarServer$postStatusBarData$withActions$);Class _logos_class$_ungrouped$SBStatusBarStateAggregator = objc_getClass("SBStatusBarStateAggregator"); MSHookMessageEx(_logos_class$_ungrouped$SBStatusBarStateAggregator, @selector(_setItem:enabled:), (IMP)&_logos_method$_ungrouped$SBStatusBarStateAggregator$_setItem$enabled$, (IMP*)&_logos_orig$_ungrouped$SBStatusBarStateAggregator$_setItem$enabled$);}
}
