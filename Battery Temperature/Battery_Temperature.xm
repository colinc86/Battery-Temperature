#import <SpringBoard/SpringBoard.h>
#import <Foundation/Foundation.h>

#import "BTActivatorListener.h"
#import "BTPreferencesInterface.h"
#import "BTClassFunctions.h"
#import "BTAlertCenter.h"
#import "Headers.h"

#include <dlfcn.h>




#pragma mark - Static variables/functions

static UIStatusBarBatteryItemView *itemView = nil;
static NSString *lastBatteryDetailString = @"";
static BTAlertCenter *alertCenter = nil;
static BOOL forcedUpdate = NO;
static BOOL isCharging = NO;

static void refreshStatusBarData(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    UIStatusBar *statusBar = (UIStatusBar *)[[UIApplication sharedApplication] statusBar];
    if (statusBar) {
        [statusBar setShowsOnlyCenterItems:YES];
        [statusBar setShowsOnlyCenterItems:NO];
    }
    
    if (itemView) {
        if (!itemView.allowsUpdates) {
            [itemView setAllowsUpdates:YES];
        }
        
        [itemView updateContentsAndWidth];
    }
    
    if (%c(SpringBoard)) {
        SBStatusBarStateAggregator *aggregator = [%c(SBStatusBarStateAggregator) sharedInstance];
        [aggregator _updateBatteryItems];
        [aggregator _setItem:7 enabled:NO];
        [aggregator updateStatusBarItem:7];
        [aggregator _setItem:8 enabled:NO];
        [aggregator updateStatusBarItem:8];
        
        BTPreferencesInterface *interface = [BTPreferencesInterface sharedInterface];
        if (interface.showPercent || interface.enabled) {
            [aggregator _setItem:8 enabled:YES];
        }
        
        forcedUpdate = YES;
        [UIStatusBarServer postStatusBarData:[UIStatusBarServer getStatusBarData] withActions:0];
    }
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
    
    unsigned int state = arg1->batteryState;
    if (state == 1) {
        isCharging = YES;
    }
    else {
        isCharging = NO;
    }
    
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
    
    [alertCenter checkAlertsWithTemperature:[BTClassFunctions getBatteryTemperature] enabled:interface.enabled tempAlerts:interface.tempAlerts alertVibrate:interface.alertVibrate barAlertsEnabled:interface.statusBarAlerts];
    
    if (interface.enabled && [interface isTemperatureVisible:[alertCenter hasAlertShown]]) {
        NSString *temperatureString = [BTClassFunctions getTemperatureString];
        
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

%hook UIStatusBarBatteryItemView

- (_UILegibilityImageSet *)contentsImage
{
    if (itemView != self) {
        [itemView release];
        itemView = [self retain];
    }
    
    _UILegibilityImageSet *original = %orig;
    if ([BTPreferencesInterface sharedInterface].colorizeIcon && !isCharging) {
        UIColor *color = [BTClassFunctions getBatteryColor];
        original.image = [original.image _flatImageWithColor:color];
    }
        
    return original;
}

%end

%hook UIStatusBarNewUIForegroundStyleAttributes

- (id)_batteryColorForCapacity:(double)arg1 lowCapacity:(double)arg2 charging:(bool)arg3
{
    UIColor *original = %orig(arg1, arg2, arg3);
    if ([BTPreferencesInterface sharedInterface].colorizeIcon && !isCharging) {
        original = [BTClassFunctions getBatteryColor];
    }
    
    return original;
}

%end

%hook UIStatusBarForegroundStyleAttributes

- (id)_batteryColorForCapacity:(float)arg1 lowCapacity:(float)arg2 charging:(bool)arg3
{
    UIColor *original = %orig(arg1, arg2, arg3);
    if ([BTPreferencesInterface sharedInterface].colorizeIcon && !isCharging) {
        original = [BTClassFunctions getBatteryColor];
    }
    
    return original;
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
