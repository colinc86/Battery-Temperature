#import <SpringBoard/SpringBoard.h>
#import <Foundation/Foundation.h>

#import "BTActivatorListener.h"
#import "BTPreferencesInterface.h"
#import "BTStaticFunctions.h"
#import "BTAlertCenter.h"

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

static NSString *lastBatteryDetailString = @"";
static BTAlertCenter *alertCenter = nil;
static BOOL forcedUpdate = NO;

static void refreshStatusBarData(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    BTPreferencesInterface *interface = [BTPreferencesInterface sharedInterface];
    SBStatusBarStateAggregator *aggregator = [%c(SBStatusBarStateAggregator) sharedInstance];
    [aggregator _setItem:8 enabled:NO];
    if (interface.showPercent || interface.enabled) {
        [aggregator _setItem:8 enabled:YES];
    }
    
//    [alertCenter.itemManager updateWithTemperature:[BTStaticFunctions getBatteryTemperature] enabled:interface.enabled barAlertsEnabled:interface.statusBarAlerts alertVibrate:(interface.alertVibrate && !alertCenter.didVibrate)];
    
    // Post new data to the data bar
    forcedUpdate = YES;
    [UIStatusBarServer postStatusBarData:[UIStatusBarServer getStatusBarData] withActions:0];
}

static void resetAlerts(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    [alertCenter resetAlerts];
}




#pragma mark - Hook methods

%hook UIStatusBarServer

+ (void)postStatusBarData:(CDStruct_4ec3be00 *)arg1 withActions:(int)arg2 {
    BTPreferencesInterface *interface = [BTPreferencesInterface sharedInterface];
    [interface loadSettings];
    [interface loadSpringBoardSettings];
    
    char currentString[150];
    strcpy(currentString, arg1->batteryDetailString);
    NSString *batteryDetailString = [NSString stringWithUTF8String:currentString];
    
    if (!forcedUpdate) {
        if (lastBatteryDetailString != nil) {
            [lastBatteryDetailString release];
            lastBatteryDetailString = nil;
        }
        lastBatteryDetailString = [batteryDetailString retain];
    }
    
    [alertCenter checkAlertsWithTemperature:[BTStaticFunctions getBatteryTemperature] enabled:interface.enabled tempAlerts:interface.tempAlerts alertVibrate:interface.alertVibrate barAlertsEnabled:interface.statusBarAlerts];
    
    if (interface.enabled && [interface isTemperatureVisible:[alertCenter hasAlertShown]]) {
        NSString *temperatureString = [BTStaticFunctions getTemperatureString];
        
        if (interface.showPercent) {
            temperatureString = [temperatureString stringByAppendingFormat:@"  %@", lastBatteryDetailString];
        }
        
        strlcpy(arg1->batteryDetailString, [temperatureString UTF8String], sizeof(arg1->batteryDetailString));
    } else if (forcedUpdate) {
        if (interface.showPercent) {
            strlcpy(arg1->batteryDetailString, [lastBatteryDetailString UTF8String], sizeof(arg1->batteryDetailString));
        }
        else {
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
    BTPreferencesInterface *interface = [BTPreferencesInterface sharedInterface];
    if (arg1 == 8) {
        interface.showPercent = interface.enabled;
    }
    
    return %orig(arg1, ((arg1 == 8) && interface.enabled) ? YES : arg2);
}

%end

%ctor {
    if (%c(SpringBoard)) {
        CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, refreshStatusBarData, CFSTR(UPDATE_STAUS_BAR_NOTIFICATION_NAME), NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
        CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, resetAlerts, CFSTR(RESET_ALERTS_NOTIFICATION_NAME), NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
        
        [[BTPreferencesInterface sharedInterface] startListeningForNotifications];
        
        alertCenter = [[BTAlertCenter alloc] init];
        
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
